# Design Document — Memory Leak Fixes

## Overview

Three surgical fixes eliminate out-of-memory (OOM) risks in the Flux P2P
file-sharing app. Each fix is confined to a single method or code block; no
public APIs, data models, or architectural layers change.

| Fix | File | Root cause | Change |
|-----|------|-----------|--------|
| 1 | `web_share_service.dart` | Stale `zipData` reference + double `response.close()` | Remove reference, remove duplicate close |
| 2 | `thumbnail_service.dart` | Isolate reads full file into `Uint8List` before decode | Add early-exit for large files; rely on existing `compute()` path |
| 3 | `encryption_service.dart` | Fallback hash path calls `file.readAsBytes()` | Replace with `RandomAccessFile` chunked read |

---

## Architecture

All three services are Dart singletons that run on the Flutter UI isolate
(or, in the thumbnail case, spawn a background isolate via `compute()`).
No new classes, packages, or isolates are introduced.

```
┌─────────────────────────────────────────────────────────┐
│  Flutter UI Isolate                                      │
│                                                          │
│  WebShareService ──► HttpServer ──► Browser client       │
│       │                                                  │
│       └─ _serveZipDownload                               │
│            ZipEncoder ──► _ResponseOutputStream          │
│                               │                          │
│                               └─► HttpResponse (stream)  │
│                                                          │
│  ThumbnailService                                        │
│       └─ _generateImageThumbnail                         │
│            └─ compute(_decodeAndResize, path)            │
│                 └─► Background Isolate (own heap)        │
│                                                          │
│  EncryptionService                                       │
│       └─ calculateFileHash                               │
│            ├─ Rust hashFileOptimized (primary)           │
│            └─ RandomAccessFile chunked read (fallback)   │
└─────────────────────────────────────────────────────────┘
```

---

## Components and Interfaces

### Fix 1 — `_serveZipDownload` in `WebShareService`

**Current broken state (two bugs):**

```dart
// Bug A — stale variable reference (zipData was removed when streaming was adopted)
AppLogger.info('... (${zipData.length} bytes, ...)');

// Bug B — double close: the finally block always runs after the try block
// which already called response.close() via encoder.endEncode() path
finally {
  _activeClients.remove(clientKey);
  await response.close();   // ← second close crashes the response
}
```

**Correct streaming pattern:**

```
ZipEncoder.startEncode(_ResponseOutputStream(response))
  │
  ├─ for each file:
  │    ArchiveFile.stream(name, size, File(path).openRead())
  │    encoder.addFile(archiveFile)
  │
  └─ encoder.endEncode()
       │
       └─ _ResponseOutputStream.writeBytes / writeInputStream
            │
            └─ response.add(bytes)   ← bytes flow directly, no buffer

response.flush()
// download counts incremented here
// ONE response.close() here — not in finally
```

**Changes (minimal):**

1. Remove the `AppLogger.info` line that references `zipData`.
2. Move `await response.close()` out of the `finally` block and into the
   success path only (after `response.flush()`). The `catch` block already
   calls `response.close()` for the error path.
3. Remove the redundant `await response.close()` from `finally`.

The `_ResponseOutputStream` class and `ArchiveFile.stream()` usage are
already correct and require no changes.

---

### Fix 2 — `_decodeAndResize` in `ThumbnailService`

**Current state:**

The 50 MB file-size guard in `_generateImageThumbnail` is correct. The
`compute()` call is correct. The problem is inside the isolate function:

```dart
static Uint8List? _decodeAndResize(String filePath) {
  final bytes = File(filePath).readAsBytesSync();  // ← loads full file
  final image = img.decodeImage(bytes);            // ← decodes to raw RGBA
  // A 50 MB JPEG → ~200 MB RGBA bitmap in memory simultaneously
  ...
}
```

**Correct pattern:**

The `image` package's `decodeImage` requires the full byte array — there is
no streaming decode API. The memory spike comes from holding `bytes` AND
`image` simultaneously. The fix is to drop `bytes` before the resize:

```dart
static Uint8List? _decodeAndResize(String filePath) {
  // 1. Read bytes
  final bytes = File(filePath).readAsBytesSync();
  // 2. Decode — bytes and image both live here briefly
  final image = img.decodeImage(bytes);
  // 3. Drop the raw bytes immediately — they are no longer needed
  //    (Dart GC will collect them; the isolate heap is separate from UI)
  if (image == null) return null;
  // 4. Resize to thumbnail — full-res bitmap and thumbnail coexist briefly
  final thumbnail = img.copyResize(image, width: thumbnailSize, height: thumbnailSize);
  // 5. Encode to PNG — only thumbnail bytes remain after this line
  return Uint8List.fromList(img.encodePng(thumbnail));
  // image and bytes go out of scope here → GC eligible
}
```

Because this runs in a background isolate (separate heap), even the brief
coexistence of `bytes` + `image` is isolated from the UI thread. The 50 MB
guard ensures the worst-case peak inside the isolate is bounded:
- Raw bytes: ≤ 50 MB
- Decoded RGBA: ≤ 50 MB × 4 bytes/pixel / compression_ratio ≈ ≤ 200 MB
- Thumbnail (128×128 RGBA): ~64 KB

The fix makes the intent explicit and ensures `bytes` is not referenced after
`decodeImage` returns, allowing the GC to collect it before the resize step.

**Changes (minimal):**

The existing code already has the correct structure. The only change needed
is to add a comment making the memory lifecycle explicit, and to confirm
`bytes` is not captured in a closure or stored after `decodeImage`. No
functional code change is required beyond what is already in place — the
current implementation is correct. The design documents the pattern for
future maintainers.

> **Note:** If the `image` package adds a streaming/tiled decode API in a
> future version, `_decodeAndResize` should be updated to use it. For now,
> the isolate boundary + 50 MB guard is the correct mitigation.

---

### Fix 3 — `calculateFileHash` fallback in `EncryptionService`

**Current broken state:**

```dart
} catch (e) {
  AppLogger.error('Failed to calculate file hash via Rust', e);
  // Fallback to Dart implementation
  final file = File(filePath);
  final bytes = await file.readAsBytes();   // ← loads entire file into memory
  final digest = sha256.convert(bytes);
  return digest.toString();
}
```

**Correct chunked pattern:**

```dart
} catch (e) {
  AppLogger.warning(
    'Rust hashFileOptimized failed for $filePath: $e — using Dart fallback',
  );
  // Chunked SHA-256: never holds more than _hashChunkSize bytes at once
  final raf = await File(filePath).open();
  final sink = sha256.startChunkedConversion(AccumulatorSink<Digest>());
  final buffer = Uint8List(_hashChunkSize);   // 1 MB
  try {
    while (true) {
      final n = await raf.readInto(buffer);
      if (n == 0) break;
      sink.add(buffer.sublist(0, n));
    }
  } finally {
    await raf.close();
    sink.close();
  }
  return (sink as AccumulatorSink<Digest>).events.single.toString();
}
```

**Changes (minimal):**

1. Replace `file.readAsBytes()` + `sha256.convert(bytes)` with a
   `RandomAccessFile` loop that feeds 1 MB chunks into
   `sha256.startChunkedConversion`.
2. Update the `AppLogger.error` call to `AppLogger.warning` and include
   `filePath` and the Rust error `e` in the message.
3. Add `static const int _hashChunkSize = 1024 * 1024;` constant.

---

## Data Models

No data model changes. All fixes are confined to method bodies.

---

## Correctness Properties

*A property is a characteristic or behavior that should hold true across all
valid executions of a system — essentially, a formal statement about what the
system should do. Properties serve as the bridge between human-readable
specifications and machine-verifiable correctness guarantees.*

### Property 1: Streaming ZIP round-trip

*For any* list of named byte sequences (representing file contents), encoding
them into a ZIP archive via the `_ResponseOutputStream` + `ArchiveFile.stream`
path and then decoding the resulting ZIP bytes should yield the original byte
sequences under their original names.

**Validates: Requirements 1.3, 1.8**

---

### Property 2: Response closed exactly once

*For any* set of shared files — including the empty set, a set where all
files exist, and a set where some files are missing on disk — after
`_serveZipDownload` completes (successfully or with an error), the mock
`HttpResponse.close()` method should have been called exactly once.

**Validates: Requirements 1.4, 1.5**

---

### Property 3: Download counts incremented for included files

*For any* set of shared files where at least one file exists on disk, after a
successful `_serveZipDownload`, the `_downloadCounts` entry for every file
that was included in the archive should be exactly one greater than its value
before the call.

**Validates: Requirement 1.6**

---

### Property 4: Large-file guard returns null

*For any* file whose size in bytes is strictly greater than
`ThumbnailService._maxDecodeSizeBytes` (50 MB), `getThumbnail` should return
`null` without invoking the image decoder.

**Validates: Requirement 2.1**

---

### Property 5: Thumbnail dimensions are bounded

*For any* valid image (any width, height, format supported by the `image`
package), the PNG bytes returned by `_decodeAndResize` should decode to an
image whose width and height are both ≤ `ThumbnailService.thumbnailSize`
(128 pixels).

**Validates: Requirements 2.3, 2.4**

---

### Property 6: Corrupt image input returns null

*For any* byte sequence that is not a valid image (random bytes, truncated
files, wrong magic bytes), `getThumbnail` should return `null` and not throw
an exception to the caller.

**Validates: Requirement 2.5**

---

### Property 7: Cache size invariant

*For any* sequence of `getThumbnail` calls with distinct file paths of length
greater than `ThumbnailService.maxCacheSize` (100), the number of entries in
`_thumbnailCache` should never exceed 100 at any point during or after the
sequence.

**Validates: Requirement 2.6**

---

### Property 8: Cache hit idempotence

*For any* file path that has already been cached, calling `getThumbnail` a
second time should return bytes that are equal to the bytes returned by the
first call, without re-reading or re-decoding the file.

**Validates: Requirement 2.7**

---

### Property 9: Chunked fallback hash correctness

*For any* byte sequence written to a temporary file, when the Rust
`hashFileOptimized` call is mocked to throw, the value returned by
`calculateFileHash` should equal the lowercase hex-encoded SHA-256 digest of
the full byte sequence as computed by a reference implementation.

**Validates: Requirement 3.2**

---

## Error Handling

### Fix 1 — ZIP download

| Scenario | Behaviour |
|----------|-----------|
| File missing at download time | Skip file, continue encoding remaining files |
| `ZipEncoder` throws | `catch` block sets 500 status, writes error body, calls `response.close()` once |
| `response.add` throws (client disconnected) | Exception propagates to `catch`, `finally` removes client from `_activeClients` |

The `finally` block must **not** call `response.close()` because the `catch`
block already does. Calling `close()` on an already-closed response throws a
`StateError` in Dart's HTTP server.

### Fix 2 — Thumbnail

| Scenario | Behaviour |
|----------|-----------|
| File > 50 MB | Return `null` immediately (no decode attempt) |
| `decodeImage` returns `null` | Return `null` |
| Any exception inside isolate | `catch (_)` returns `null`; exception does not propagate |
| File unreadable | `readAsBytesSync` throws inside isolate → caught → `null` |

### Fix 3 — Hash fallback

| Scenario | Behaviour |
|----------|-----------|
| Rust succeeds | Return hex hash; no file I/O in Dart |
| Rust throws | Log warning with path + error; open `RandomAccessFile`; read in 1 MB chunks; close file in `finally` |
| File unreadable in fallback | `RandomAccessFile.open` throws; propagates to caller (same behaviour as before) |
| File deleted mid-read | `readInto` returns 0 or throws; `finally` closes the handle |

---

## Testing Strategy

### Unit tests (example-based)

Each fix gets a focused unit test file:

**`test/services/web_share_zip_test.dart`**
- Verify `_serveZipDownload` with zero files → 404, `close()` once
- Verify with one existing file → valid ZIP, `close()` once, count +1
- Verify with one missing file → empty ZIP (or 404), `close()` once
- Verify `zipData` identifier does not appear in source (static check via
  `dart analyze`)

**`test/services/thumbnail_service_test.dart`**
- Verify file > 50 MB returns `null` (mock `File.length`)
- Verify valid 1×1 PNG returns non-null bytes ≤ 128×128
- Verify corrupt bytes return `null`
- Verify cache eviction at 101 entries

**`test/services/encryption_service_hash_test.dart`**
- Verify fallback hash of a known byte sequence matches reference SHA-256
- Verify `AppLogger.warning` is called with path and error when Rust throws
- Verify `file.readAsBytes` is not called in fallback (mock `File`)

### Property-based tests

Use the [`fast_check`](https://pub.dev/packages/fast_check) package (Dart
port of fast-check) with a minimum of **100 iterations** per property.

Each test is tagged with the property it validates:

```dart
// Feature: memory-leak-fixes, Property 1: streaming zip round-trip
// Feature: memory-leak-fixes, Property 2: response closed exactly once
// Feature: memory-leak-fixes, Property 3: download counts incremented
// Feature: memory-leak-fixes, Property 4: large-file guard returns null
// Feature: memory-leak-fixes, Property 5: thumbnail dimensions bounded
// Feature: memory-leak-fixes, Property 6: corrupt image returns null
// Feature: memory-leak-fixes, Property 7: cache size invariant
// Feature: memory-leak-fixes, Property 8: cache hit idempotence
// Feature: memory-leak-fixes, Property 9: chunked fallback hash correctness
```

**Property 1** — Generate random lists of `(name, bytes)` pairs. Encode via
`ZipEncoder` + `_ResponseOutputStream` backed by a `BytesBuilder`. Decode
with `ZipDecoder`. Assert each file's bytes match.

**Property 2** — Generate random lists of file paths (mix of existing temp
files and non-existent paths). Run `_serveZipDownload` with a mock
`HttpResponse`. Assert `close()` call count == 1.

**Property 3** — Generate random lists of existing temp files. Run
`_serveZipDownload`. Assert each `_downloadCounts[id]` increased by 1.

**Property 4** — Generate random integers in range
`[_maxDecodeSizeBytes + 1, 2 GB]`. Mock `File.length()` to return that value.
Assert `getThumbnail` returns `null`.

**Property 5** — Generate random valid images (using `img.Image` with random
width/height in `[1, 4096]`). Encode as PNG. Pass path to `_decodeAndResize`.
Decode output PNG. Assert width ≤ 128 and height ≤ 128.

**Property 6** — Generate random byte arrays that are not valid images.
Assert `getThumbnail` returns `null` and does not throw.

**Property 7** — Generate sequences of `n > 100` distinct file paths. Call
`_cacheThumbnail` for each. Assert `_thumbnailCache.length ≤ 100` after each
insertion.

**Property 8** — Generate a valid image file path. Call `getThumbnail` twice.
Assert both results are non-null and byte-equal. Assert the decode function
was called only once (via a call counter).

**Property 9** — Generate random byte arrays. Write to a temp file. Mock
`rust_crypto.hashFileOptimized` to throw. Call `calculateFileHash`. Assert
result equals `sha256.convert(bytes).toString()`.

### Integration tests

- Start `WebShareService` with a real HTTP server on a loopback port; request
  `/download/all` with 3 files totalling 150 MB; verify the downloaded ZIP
  unpacks correctly and the process RSS stays below 200 MB (measured via
  `ProcessInfo.currentRss`).
- Call `calculateFileHash` on a 200 MB file with Rust available; verify hash
  matches reference. Then disable Rust (mock) and verify fallback produces the
  same hash.
