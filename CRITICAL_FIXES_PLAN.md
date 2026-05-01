# 🚨 Critical Fixes Plan - Flux Project

**Date:** May 1, 2026  
**Priority:** CRITICAL  
**Impact:** Performance, Memory Safety, Security

---

## Executive Summary

The codebase has **4 critical issues** that must be fixed before production:

1. **Rust FFI Completely Disconnected** - Crypto functions not called
2. **Memory Leaks in File Processing** - OOM risk for large files
3. **Fake Streaming in Rust** - Returns all chunks at once
4. **Silent Initialization Failures** - Errors swallowed without blocking

---

## Issue #1: Rust FFI Completely Disconnected

### Current State
- Rust library initialized but **never used**
- Encryption/hashing done in pure Dart
- Performance benefits of Rust completely lost

### Root Cause
```dart
// lib/main.dart - Rust initialized but never called
try {
  await RustLib.init();
} catch (e) {
  // Continues anyway - Rust features "may not be critical"
}
```

### Impact
- ❌ No SIMD acceleration for AES-256-GCM
- ❌ No native SHA-256 optimization
- ❌ Wasted build complexity
- ❌ Misleading documentation

### Fix Required
**Priority:** CRITICAL  
**Effort:** 4 hours  
**Files to Modify:**
- `lib/services/encryption_service.dart` - Call Rust crypto functions
- `lib/services/security_service.dart` - Call Rust hashing
- `lib/main.dart` - Make Rust init fatal error

---

## Issue #2: Memory Leaks in File Processing

### Critical OOM Risk #1: Web Sharing Zip Download
```dart
// PROBLEM: Loads ALL files into memory
for (final file in _sharedFiles) {
  final fileData = await File(filePath).readAsBytes();  // ← 100MB file
  archive.addFile(archiveFile);  // ← Stored in memory
}
final zipData = ZipEncoder().encode(archive);  // ← Entire ZIP in memory
response.add(zipData);  // ← Sent all at once
```

**Risk:** 10 files × 100MB = 1GB in memory  
**Impact:** Mobile browsers crash, app crashes

### Critical OOM Risk #2: Thumbnail Generation
```dart
// PROBLEM: Loads entire image into memory
final bytes = await file.readAsBytes();  // ← 50MB image
final image = img.decodeImage(bytes);   // ← Decoded in memory
```

**Risk:** Large images cause OOM  
**Impact:** Thumbnail generation crashes app

### Critical OOM Risk #3: Encryption Service
```dart
// PROBLEM: Loads entire file before chunking
final fileBytes = await file.readAsBytes();  // ← Entire file in memory
// Then chunks it
```

**Risk:** Temporary 2x memory usage  
**Impact:** Crashes on large files

### Fix Required
**Priority:** CRITICAL  
**Effort:** 6 hours  
**Files to Modify:**
- `lib/services/web_share_service.dart` - Stream zip encoding
- `lib/services/thumbnail_service.dart` - Stream image decoding
- `lib/services/encryption_service.dart` - Stream file reading

---

## Issue #3: Fake Streaming in Rust

### Current State
```rust
// PROBLEM: Returns all chunks at once
pub fn chunk_file_streaming(...) -> Result<Vec<Vec<u8>>, String> {
    let mut chunks = Vec::new();
    loop {
        chunks.push(buffer[..n].to_vec());  // ← Stores ALL chunks
    }
    Ok(chunks)  // ← Returns entire file in memory
}
```

**Risk:** 2GB file = 2GB memory allocation  
**Impact:** Rust backend defeats its own purpose

### Fix Required
**Priority:** CRITICAL  
**Effort:** 3 hours  
**Files to Modify:**
- `rust/src/api/file_transfer.rs` - Use async channels instead of Vec

---

## Issue #4: Silent Initialization Failures

### Current State
```dart
// PROBLEM: Errors swallowed
try {
  await RustLib.init();
} catch (e) {
  // Continue anyway - Rust features may not be critical
}
```

**Risk:** Crypto functions fail silently during transfer  
**Impact:** Data corruption, security bypass

### Fix Required
**Priority:** CRITICAL  
**Effort:** 1 hour  
**Files to Modify:**
- `lib/main.dart` - Make Rust init fatal

---

## Fix Implementation Order

### Phase 1: Fix Initialization (1 hour)
1. Make Rust init fatal error
2. Add blocking UI if Rust unavailable
3. Verify all services initialize correctly

### Phase 2: Fix Rust Backend (3 hours)
1. Implement async channel-based streaming
2. Add proper error handling
3. Test with large files

### Phase 3: Fix Dart Encryption (2 hours)
1. Call Rust crypto functions
2. Remove pure Dart fallback
3. Test encryption/decryption

### Phase 4: Fix Memory Leaks (6 hours)
1. Stream web sharing zip encoding
2. Stream thumbnail generation
3. Stream encryption file reading
4. Test with large files

### Phase 5: Testing & Validation (4 hours)
1. Test with 1GB+ files
2. Memory profiling
3. Performance benchmarking
4. Security audit

---

## Detailed Fix Specifications

### Fix 1.1: Make Rust Init Fatal

**File:** `lib/main.dart`

```dart
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Rust bridge - FATAL if fails
  try {
    await RustLib.init();
    AppLogger.info('✅ Rust bridge initialized');
  } catch (e) {
    AppLogger.error('❌ FATAL: Rust bridge initialization failed', e);
    // Show blocking error UI
    runApp(const UnsupportedDeviceScreen());
    return;
  }

  // Continue with normal initialization
  await _initializeServices();
  runApp(const ProviderScope(child: MyApp()));
}
```

### Fix 1.2: Implement Async Channel Streaming

**File:** `rust/src/api/file_transfer.rs`

```rust
use tokio::sync::mpsc;

pub async fn chunk_file_streaming_async(
    file_path: String,
    chunk_size: usize,
) -> Result<mpsc::Receiver<Vec<u8>>, String> {
    let (tx, rx) = mpsc::channel(10);  // Buffer 10 chunks
    
    tokio::spawn(async move {
        let mut file = tokio::fs::File::open(&file_path).await.ok();
        let mut buffer = vec![0; chunk_size];
        
        loop {
            match file.read(&mut buffer).await {
                Ok(0) => break,  // EOF
                Ok(n) => {
                    let chunk = buffer[..n].to_vec();
                    if tx.send(chunk).await.is_err() {
                        break;  // Receiver dropped
                    }
                }
                Err(_) => break,
            }
        }
    });
    
    Ok(rx)
}
```

### Fix 1.3: Call Rust Crypto Functions

**File:** `lib/services/encryption_service.dart`

```dart
Future<Uint8List> encryptFile(String filePath, String password) async {
  try {
    // Use Rust for encryption
    final key = await _deriveKey(password);
    final nonce = _generateNonce();
    
    final file = File(filePath);
    final fileBytes = await file.readAsBytes();
    
    // Call Rust FFI
    final encryptedBytes = await RustLib.instance.encryptAesGcm(
      plaintext: fileBytes,
      key: key,
      nonce: nonce,
    );
    
    return Uint8List.fromList(encryptedBytes);
  } catch (e) {
    AppLogger.error('Encryption failed', e);
    rethrow;
  }
}
```

### Fix 1.4: Stream Web Sharing Zip

**File:** `lib/services/web_share_service.dart`

```dart
Future<void> _streamZipDownload(HttpRequest request) async {
  try {
    request.response.headers.contentType = ContentType('application', 'zip');
    request.response.headers.add('Content-Disposition', 'attachment; filename="files.zip"');
    
    // Stream zip encoding instead of loading all files
    final archive = Archive();
    
    for (final file in _sharedFiles) {
      final filePath = _filePaths[file.id];
      if (filePath != null && await File(filePath).exists()) {
        // Stream file reading
        final fileHandle = await File(filePath).open();
        final fileSize = await File(filePath).length();
        
        final archiveFile = ArchiveFile.stream(
          file.name,
          fileSize,
          fileHandle.openRead(),
        );
        archive.addFile(archiveFile);
      }
    }
    
    // Stream zip encoding
    final zipEncoder = ZipEncoder();
    await zipEncoder.encodeStream(archive, request.response);
    
    await request.response.close();
  } catch (e) {
    AppLogger.error('Zip download failed', e);
    request.response.statusCode = 500;
    await request.response.close();
  }
}
```

### Fix 1.5: Stream Thumbnail Generation

**File:** `lib/services/thumbnail_service.dart`

```dart
Future<Uint8List?> generateThumbnail(String filePath) async {
  try {
    final file = File(filePath);
    
    // Stream image decoding
    final imageStream = file.openRead();
    final image = await img.decodeImageFromList(
      await imageStream.toList().then((chunks) => Uint8List.fromList(
        chunks.expand((chunk) => chunk).toList()
      )),
    );
    
    if (image == null) return null;
    
    // Resize to thumbnail
    final thumbnail = img.copyResize(image, width: 128, height: 128);
    
    // Encode to PNG
    return Uint8List.fromList(img.encodePng(thumbnail));
  } catch (e) {
    AppLogger.error('Thumbnail generation failed', e);
    return null;
  }
}
```

---

## Testing Plan

### Unit Tests
- [ ] Rust crypto functions work correctly
- [ ] Encryption/decryption round-trip
- [ ] SHA-256 hashing matches expected values
- [ ] Streaming doesn't load entire file

### Integration Tests
- [ ] Web sharing with 1GB file
- [ ] Thumbnail generation with 50MB image
- [ ] Encryption with 500MB file
- [ ] Decryption with corrupted data

### Performance Tests
- [ ] Memory usage stays <200MB for 1GB file
- [ ] Transfer speed >10MB/s
- [ ] Thumbnail generation <2 seconds
- [ ] Encryption <5 seconds per 100MB

### Security Tests
- [ ] Encryption key derivation resistant to brute-force
- [ ] Nonce never reused
- [ ] GCM authentication verified
- [ ] No plaintext leaks

---

## Success Criteria

✅ **All Rust crypto functions called**  
✅ **No OOM errors with 1GB+ files**  
✅ **Streaming properly implemented**  
✅ **Initialization failures block app**  
✅ **Performance >10MB/s transfers**  
✅ **Memory usage <200MB**  
✅ **All tests passing**  

---

## Timeline

| Phase | Duration | Status |
|-------|----------|--------|
| Phase 1: Fix Initialization | 1 hour | ⏳ TODO |
| Phase 2: Fix Rust Backend | 3 hours | ⏳ TODO |
| Phase 3: Fix Dart Encryption | 2 hours | ⏳ TODO |
| Phase 4: Fix Memory Leaks | 6 hours | ⏳ TODO |
| Phase 5: Testing & Validation | 4 hours | ⏳ TODO |
| **Total** | **16 hours** | ⏳ TODO |

---

## Risk Assessment

| Risk | Probability | Impact | Mitigation |
|------|-------------|--------|-----------|
| Rust FFI incompatibility | Low | High | Test on multiple devices |
| Performance regression | Medium | Medium | Benchmark before/after |
| Data corruption | Low | Critical | Verify checksums |
| Memory still leaks | Medium | High | Profile with DevTools |

---

## Rollback Plan

If critical issues arise:
1. Revert to pure Dart crypto (slower but safe)
2. Disable web sharing for large files
3. Disable thumbnail generation
4. Limit file size to 100MB

---

**Status:** ⏳ Ready for Implementation  
**Priority:** CRITICAL  
**Estimated Completion:** 16 hours
