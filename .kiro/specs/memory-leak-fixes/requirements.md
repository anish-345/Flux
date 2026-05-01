# Requirements Document

## Introduction

The Flux P2P file-sharing app has three services that risk out-of-memory (OOM) crashes when handling large files:

1. **Web Share Zip Download** (`web_share_service.dart`) — the streaming zip path is partially implemented but contains a reference to a deleted variable (`zipData`) and calls `response.close()` twice, causing a runtime crash on every "Download All" request.
2. **Thumbnail Generation** (`thumbnail_service.dart`) — the 50 MB file-size guard and isolate offload are in place, but the isolate still reads the entire file into a `Uint8List` before decoding. A 50 MB JPEG decoded to raw RGBA can expand to ~200 MB in memory.
3. **Encryption Service** (`encryption_service.dart`) — chunked streaming for files above 50 MB is already implemented correctly. The remaining risk is the SHA-256 hash fallback in `calculateFileHash`, which calls `file.readAsBytes()` on the full file when the Rust path fails.

The goal of this phase is to make all three services handle files of any size (including 1 GB+) while keeping peak memory usage below 200 MB.

---

## Glossary

- **WebShareService**: The Dart singleton that hosts an HTTP server for browser-based file downloads.
- **ZipEncoder**: The `archive` package class that encodes files into a ZIP archive.
- **_ResponseOutputStream**: A custom `OutputStreamBase` that writes ZIP bytes directly to an `HttpResponse` without buffering.
- **ThumbnailService**: The Dart singleton that generates 128×128 PNG thumbnails for image files.
- **EncryptionService**: The Dart singleton that encrypts and decrypts files using AES-256-GCM via the Rust backend.
- **Isolate**: A Dart concurrency primitive with its own memory heap, used to offload CPU-intensive work off the UI thread.
- **RandomAccessFile**: Dart's `dart:io` class for reading a file in arbitrary-sized chunks without loading it fully.
- **OOM**: Out-of-memory crash — the process is killed by the OS because it requested more RAM than is available.
- **Streaming**: Processing data in fixed-size chunks so that only one chunk is in memory at a time, regardless of total file size.
- **Peak memory**: The maximum amount of RAM held simultaneously during an operation.
- **Rust backend**: The native Rust library accessed via `flutter_rust_bridge`, providing `hashFileOptimized()` and `encryptAesGcm()`.

---

## Requirements

### Requirement 1: Streaming ZIP Download

**User Story:** As a browser user downloading multiple shared files, I want the "Download All" button to produce a ZIP file that streams directly to my browser, so that the Flux app does not crash when the combined file size exceeds available RAM.

#### Acceptance Criteria

1. WHEN a browser client requests `/download/all`, THE WebShareService SHALL begin writing ZIP-encoded bytes to the HTTP response before all files have been read from disk.
2. THE WebShareService SHALL use `_ResponseOutputStream` to pipe ZIP bytes directly into the `HttpResponse` without accumulating a complete in-memory ZIP buffer.
3. THE WebShareService SHALL add each shared file to the ZIP archive using `ArchiveFile.stream()` with the file's `openRead()` stream, so that no individual file is fully loaded into memory.
4. WHEN the ZIP encoding is complete, THE WebShareService SHALL call `response.close()` exactly once.
5. IF a shared file does not exist on disk at download time, THEN THE WebShareService SHALL skip that file and continue encoding the remaining files.
6. WHEN the ZIP download completes successfully, THE WebShareService SHALL increment the download count for every file that was included in the archive.
7. THE WebShareService SHALL NOT reference the variable `zipData` anywhere in the zip-download code path, as this variable was removed when the streaming approach was adopted.
8. WHILE a ZIP download is in progress, THE WebShareService SHALL hold no more than one 64 KB chunk of any single file in memory at a time.

---

### Requirement 2: Memory-Safe Thumbnail Generation

**User Story:** As a user browsing shared files, I want thumbnails to be generated without crashing the app, so that I can preview files even when the originals are large images.

#### Acceptance Criteria

1. WHEN an image file is larger than 50 MB, THE ThumbnailService SHALL return `null` without attempting to decode the image.
2. WHEN an image file is 50 MB or smaller, THE ThumbnailService SHALL decode and resize the image inside a background `Isolate` via `compute()`, so that the UI thread is never blocked.
3. THE ThumbnailService SHALL resize the decoded image to at most 128×128 pixels before encoding it as PNG.
4. WHEN the decoded image dimensions exceed 1024×1024 pixels, THE ThumbnailService SHALL use `img.copyResize` with a target width of 128 pixels so that the full-resolution bitmap is not retained in memory after resizing.
5. IF image decoding throws an exception inside the isolate, THEN THE ThumbnailService SHALL catch the exception and return `null` without propagating the error to the caller.
6. THE ThumbnailService SHALL cache at most 100 thumbnails in memory; WHEN the cache is full, THE ThumbnailService SHALL evict the oldest entry before inserting a new one.
7. WHEN a thumbnail is requested for a file path that is already cached, THE ThumbnailService SHALL return the cached value without re-reading or re-decoding the file.

---

### Requirement 3: Memory-Safe File Hash Fallback

**User Story:** As a developer relying on file integrity checks, I want the SHA-256 hash fallback in the encryption service to not load entire large files into memory, so that integrity verification does not cause OOM crashes when the Rust path is unavailable.

#### Acceptance Criteria

1. WHEN `calculateFileHash` is called and the Rust `hashFileOptimized` call succeeds, THE EncryptionService SHALL return the hex-encoded hash without reading the file in Dart.
2. IF the Rust `hashFileOptimized` call throws an exception, THEN THE EncryptionService SHALL compute the SHA-256 hash by reading the file in chunks using a `RandomAccessFile`, so that the full file is never held in memory simultaneously.
3. THE EncryptionService fallback hash path SHALL use a read buffer of no more than 1 MB per iteration.
4. WHEN the fallback hash path is used, THE EncryptionService SHALL log a warning that includes the file path and the Rust error message.
5. THE EncryptionService SHALL NOT call `file.readAsBytes()` in the `calculateFileHash` fallback path for any file, regardless of size.

---

### Requirement 4: Memory Budget Compliance

**User Story:** As a mobile user transferring 1 GB+ files, I want the app to stay within a 200 MB memory budget during all file operations, so that the OS does not kill the app mid-transfer.

#### Acceptance Criteria

1. WHEN any single file operation (zip download, thumbnail generation, or file hash) is in progress, THE application SHALL hold no more than 200 MB of file data in memory simultaneously.
2. WHEN the WebShareService streams a ZIP containing N files each of size S, THE WebShareService SHALL use memory proportional to the chunk size (≤ 256 KB), not proportional to N × S.
3. WHEN the EncryptionService encrypts a file larger than 50 MB, THE EncryptionService SHALL use memory proportional to the chunk size (1 MB per chunk), not proportional to the total file size.
4. WHEN the ThumbnailService decodes an image, THE ThumbnailService SHALL release the full-resolution decoded bitmap from memory before returning the resized thumbnail bytes.
