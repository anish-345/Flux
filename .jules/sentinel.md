## 2026-04-15 - [OOM Vulnerability in File Hashing]
**Vulnerability:** The `hash_file` function in the Rust layer used `std::fs::read`, which loads the entire file into memory. Since the app supports transfers up to 5GB, this would cause a Denial of Service (DoS) through memory exhaustion (OOM) on most devices.
**Learning:** Architecture specifications (like 5GB file support) must be reflected in the choice of I/O operations in the implementation layer. Using convenience functions like `std::fs::read` is dangerous for applications handling arbitrary user files.
**Prevention:** Always use streaming I/O (BufReader) and incremental updates for cryptographic operations (Hashing, Encryption) when dealing with files of unknown or potentially large size.
