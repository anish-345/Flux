// Async operations module — higher-level async helpers exposed to Dart via FRB.
// Low-level streaming is in file_transfer.rs (stream_file_chunks_async, copy_file_with_progress).

use flutter_rust_bridge::frb;
use tokio::fs::File;
use tokio::io::AsyncReadExt;

/// Async SHA-256 file hash with streaming (64 KB buffer).
#[frb]
pub async fn hash_file_async(path: String) -> Result<Vec<u8>, String> {
    use sha2::{Digest, Sha256};

    let mut file =
        File::open(&path).await.map_err(|e| format!("Failed to open file: {}", e))?;

    let mut hasher = Sha256::new();
    let mut buffer = vec![0u8; 65536];

    loop {
        match file.read(&mut buffer).await {
            Ok(0) => break,
            Ok(n) => hasher.update(&buffer[..n]),
            Err(e) => return Err(format!("Failed to read file: {}", e)),
        }
    }

    Ok(hasher.finalize().to_vec())
}

/// Async file metadata — get size without loading the file.
#[frb]
pub async fn get_file_size_async(path: String) -> Result<u64, String> {
    let metadata = tokio::fs::metadata(&path)
        .await
        .map_err(|e| format!("Failed to get file metadata: {}", e))?;
    Ok(metadata.len())
}

/// Async file existence check.
#[frb]
pub async fn file_exists_async(path: String) -> bool {
    tokio::fs::metadata(&path).await.is_ok()
}

#[cfg(test)]
mod tests {
    use super::*;

    #[tokio::test]
    async fn test_hash_file_async() {
        let test_path = "/tmp/test_hash_async_ops.bin";
        let test_data = b"test data for hashing";

        let mut file = File::create(test_path).await.expect("Failed to create test file");
        file.write_all(test_data).await.expect("Failed to write test data");
        file.flush().await.expect("Failed to flush");

        let hash = hash_file_async(test_path.to_string())
            .await
            .expect("Async hash failed");
        assert_eq!(hash.len(), 32);

        tokio::fs::remove_file(test_path).await.ok();
    }

    #[tokio::test]
    async fn test_get_file_size_async() {
        let test_path = "/tmp/test_size_async_ops.bin";
        let mut file = File::create(test_path).await.expect("Failed to create test file");
        file.write_all(&vec![0u8; 512]).await.expect("Failed to write");
        file.flush().await.expect("Failed to flush");

        let size = get_file_size_async(test_path.to_string())
            .await
            .expect("Failed to get size");
        assert_eq!(size, 512);

        tokio::fs::remove_file(test_path).await.ok();
    }
}
