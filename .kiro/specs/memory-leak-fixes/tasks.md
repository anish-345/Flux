# Implementation Plan: Memory Leak Fixes

## Overview

Three surgical, single-method fixes to eliminate OOM risks in `WebShareService`,
`ThumbnailService`, and `EncryptionService`. Each fix touches one method body only;
no public APIs, data models, or architectural layers change.

---

## Tasks

- [x] 1. Fix `_serveZipDownload` in `web_share_service.dart`
  - Remove the stale `AppLogger.info` line that references the deleted `zipData`
    variable (causes a compile-time error on every "Download All" request).
  - Move `await response.close()` out of the `finally` block and into the success
    path only (after `response.flush()`). The `catch` block already calls
    `response.close()` for the error path, so the `finally` close is always a
    double-close.
  - Remove the now-redundant `await response.close()` from `finally`; keep only
    `_activeClients.remove(clientKey)` there.
  - _Requirements: 1.4, 1.7_

  - [x] 1.1 Remove `zipData` reference and fix double `response.close()`
    - In `lib/services/web_share_service.dart`, locate `_serveZipDownload`.
    - Delete the `AppLogger.info('... (${zipData.length} bytes, ...)')` line.
    - Move `await response.close()` from the `finally` block to immediately after
      `response.flush()` in the success path.
    - Leave `_activeClients.remove(clientKey)` as the sole statement in `finally`.
    - _Requirements: 1.4, 1.7_

  - [ ]* 1.2 Write property test — response closed exactly once (Property 2)
    - Create `test/services/web_share_zip_test.dart`.
    - Implement a mock `HttpResponse` that counts `close()` invocations.
    - Use `fast_check` to generate random lists of file paths (mix of existing
      temp files and non-existent paths).
    - For each generated list, call `_serveZipDownload` with the mock response.
    - Assert `close()` call count == 1 for every generated input.
    - **Property 2: Response closed exactly once**
    - **Validates: Requirements 1.4, 1.5**

  - [ ]* 1.3 Write property test — download counts incremented for included files (Property 3)
    - Extend `test/services/web_share_zip_test.dart`.
    - Use `fast_check` to generate lists of existing temp files (at least one file).
    - Capture `_downloadCounts` before and after `_serveZipDownload`.
    - Assert each included file's count increased by exactly 1.
    - **Property 3: Download counts incremented for included files**
    - **Validates: Requirement 1.6**

  - [ ]* 1.4 Write property test — streaming ZIP round-trip (Property 1)
    - Extend `test/services/web_share_zip_test.dart`.
    - Use `fast_check` to generate random lists of `(name, bytes)` pairs.
    - Encode via `ZipEncoder` + `_ResponseOutputStream` backed by a `BytesBuilder`.
    - Decode the resulting bytes with `ZipDecoder`.
    - Assert each file's decoded bytes match the original bytes under the original name.
    - **Property 1: Streaming ZIP round-trip**
    - **Validates: Requirements 1.3, 1.8**

- [ ] 2. Checkpoint — Fix 1 complete
  - Ensure all tests pass, ask the user if questions arise.

- [x] 3. Document memory lifecycle in `_decodeAndResize` in `thumbnail_service.dart`
  - The existing code is functionally correct: the 50 MB guard is in place, the
    `compute()` call is in place, and `bytes` goes out of scope before the resize.
  - The only change needed is an inline comment that makes the memory lifecycle
    explicit for future maintainers, confirming `bytes` is not captured in a
    closure or stored after `decodeImage` returns.
  - _Requirements: 2.3, 2.4, 4.4_

  - [x] 3.1 Add memory-lifecycle comment to `_decodeAndResize`
    - In `lib/services/thumbnail_service.dart`, locate `_decodeAndResize`.
    - After `final image = img.decodeImage(bytes);`, add a comment explaining
      that `bytes` is now eligible for GC and is not referenced again, so the
      isolate heap holds at most `bytes` + `image` briefly before the resize.
    - Confirm `bytes` is not used after the `decodeImage` call (no closure capture,
      no assignment to a field).
    - _Requirements: 2.3, 2.4, 4.4_

  - [ ]* 3.2 Write property test — large-file guard returns null (Property 4)
    - Create `test/services/thumbnail_service_test.dart`.
    - Use `fast_check` to generate random integers in
      `[ThumbnailService._maxDecodeSizeBytes + 1, 2 * 1024 * 1024 * 1024]`.
    - Mock `File.length()` to return the generated value.
    - Assert `getThumbnail` returns `null` without invoking the image decoder.
    - **Property 4: Large-file guard returns null**
    - **Validates: Requirement 2.1**

  - [ ]* 3.3 Write property test — thumbnail dimensions bounded (Property 5)
    - Extend `test/services/thumbnail_service_test.dart`.
    - Use `fast_check` to generate random valid images (`img.Image` with random
      width/height in `[1, 4096]`), encode as PNG, write to a temp file.
    - Call `_decodeAndResize` with the temp file path.
    - Decode the returned PNG bytes and assert width ≤ 128 and height ≤ 128.
    - **Property 5: Thumbnail dimensions bounded**
    - **Validates: Requirements 2.3, 2.4**

  - [ ]* 3.4 Write property test — corrupt image returns null (Property 6)
    - Extend `test/services/thumbnail_service_test.dart`.
    - Use `fast_check` to generate random byte arrays that are not valid images.
    - Write each to a temp file and call `getThumbnail`.
    - Assert the result is `null` and no exception propagates to the caller.
    - **Property 6: Corrupt image input returns null**
    - **Validates: Requirement 2.5**

  - [ ]* 3.5 Write property test — cache size invariant (Property 7)
    - Extend `test/services/thumbnail_service_test.dart`.
    - Use `fast_check` to generate sequences of `n > 100` distinct file paths.
    - Call `_cacheThumbnail` for each path with a dummy `Uint8List`.
    - After each insertion, assert `_thumbnailCache.length ≤ 100`.
    - **Property 7: Cache size invariant**
    - **Validates: Requirement 2.6**

  - [ ]* 3.6 Write property test — cache hit idempotence (Property 8)
    - Extend `test/services/thumbnail_service_test.dart`.
    - Use `fast_check` to generate a valid image file path.
    - Call `getThumbnail` twice on the same path.
    - Assert both results are non-null and byte-equal.
    - Assert the decode function was called only once (via a call counter or mock).
    - **Property 8: Cache hit idempotence**
    - **Validates: Requirement 2.7**

- [ ] 4. Checkpoint — Fix 2 complete
  - Ensure all tests pass, ask the user if questions arise.

- [x] 5. Replace `file.readAsBytes()` fallback in `calculateFileHash` in `encryption_service.dart`
  - In the `catch` block of `calculateFileHash`, replace the single
    `file.readAsBytes()` + `sha256.convert(bytes)` call with a `RandomAccessFile`
    loop that feeds 1 MB chunks into `sha256.startChunkedConversion`.
  - Add `static const int _hashChunkSize = 1024 * 1024;` near the other chunk-size
    constants at the top of the class.
  - Change `AppLogger.error(...)` to `AppLogger.warning(...)` and include both
    `filePath` and the Rust error `e` in the message.
  - _Requirements: 3.2, 3.3, 3.4, 3.5_

  - [x] 5.1 Add `_hashChunkSize` constant
    - In `lib/services/encryption_service.dart`, add
      `static const int _hashChunkSize = 1024 * 1024;` alongside
      `_streamThresholdBytes` and `_encryptChunkSize`.
    - _Requirements: 3.3_

  - [x] 5.2 Replace `readAsBytes()` with `RandomAccessFile` chunked read
    - In the `catch` block of `calculateFileHash`, replace:
      ```dart
      final file = File(filePath);
      final bytes = await file.readAsBytes();
      final digest = sha256.convert(bytes);
      return digest.toString();
      ```
      with a `RandomAccessFile` loop:
      - Open the file with `await File(filePath).open()`.
      - Create a `sha256.startChunkedConversion(AccumulatorSink<Digest>())` sink.
      - Allocate a `Uint8List(_hashChunkSize)` buffer.
      - Loop: `await raf.readInto(buffer)`, break on `n == 0`, feed
        `buffer.sublist(0, n)` to the sink.
      - Close both `raf` and `sink` in a `finally` block.
      - Return the accumulated digest as a hex string.
    - _Requirements: 3.2, 3.3, 3.5_

  - [x] 5.3 Update log call to `AppLogger.warning` with path and error
    - Change `AppLogger.error('Failed to calculate file hash via Rust', e)` to
      `AppLogger.warning('Rust hashFileOptimized failed for $filePath: $e — using Dart fallback')`.
    - _Requirements: 3.4_

  - [ ]* 5.4 Write property test — chunked fallback hash correctness (Property 9)
    - Create `test/services/encryption_service_hash_test.dart`.
    - Use `fast_check` to generate random byte arrays of varying sizes
      (including sizes > `_hashChunkSize` to exercise multi-chunk paths).
    - Write each byte array to a temp file.
    - Mock `rust_crypto.hashFileOptimized` to throw an exception.
    - Call `calculateFileHash` and assert the result equals
      `sha256.convert(bytes).toString()` (reference implementation).
    - **Property 9: Chunked fallback hash correctness**
    - **Validates: Requirement 3.2**

- [ ] 6. Final checkpoint — All fixes complete
  - Ensure all tests pass, ask the user if questions arise.

---

## Notes

- Tasks marked with `*` are optional and can be skipped for a faster MVP.
- Each fix is confined to a single method body; no public APIs change.
- Property tests use the `fast_check` package with a minimum of 100 iterations.
- Checkpoints validate that no regression was introduced across all three services.
- The `_decodeAndResize` fix (task 3) is documentation-only; the runtime behaviour
  is already correct thanks to the existing 50 MB guard and `compute()` call.
