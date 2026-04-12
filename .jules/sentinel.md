## 2026-04-15 - [OOM Vulnerability in File Hashing]
**Vulnerability:** The `hash_file` function in the Rust layer used `std::fs::read`, which loads the entire file into memory. Since the app supports transfers up to 5GB, this would cause a Denial of Service (DoS) through memory exhaustion (OOM) on most devices.
**Learning:** Architecture specifications (like 5GB file support) must be reflected in the choice of I/O operations in the implementation layer. Using convenience functions like `std::fs::read` is dangerous for applications handling arbitrary user files.
**Prevention:** Always use streaming I/O (BufReader) and incremental updates for cryptographic operations (Hashing, Encryption) when dealing with files of unknown or potentially large size.

## 2026-04-15 - [Path Traversal in File Reassembly]
**Vulnerability:** `reassemble_file` accepted an arbitrary `output_path` from the sender. A malicious sender could provide a path like `../../system_file` to overwrite critical files.
**Learning:** File paths received from external sources (including other devices in a P2P network) must never be trusted.
**Prevention:** Sanitize paths by checking for `..` components or by enforcing that files are only written to a specific, safe directory using only the base filename.

## 2026-04-15 - [Cross-Platform Path Handling]
**Vulnerability:** Hardcoded path separators (`/`) and Unix-specific test paths (`/tmp/`) caused failures on Windows.
**Learning:** For a "truly cross-platform" app, all path logic must handle both Unix (`/`) and Windows (`\\`) separators, and tests should use platform-agnostic temp directories.
**Prevention:** Use `RegExp(r'[/\]')` for splitting paths in Dart and `std::env::temp_dir()` in Rust.
