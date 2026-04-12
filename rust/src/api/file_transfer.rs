use std::fs::File;
use std::io::{Read, Write};
use std::path::Path;

const CHUNK_SIZE: usize = 1024 * 1024; // 1MB chunks

/// Chunk a file into smaller pieces for transfer
pub fn chunk_file(file_path: String, chunk_size: usize) -> Result<Vec<Vec<u8>>, String> {
    let mut file = File::open(&file_path)
        .map_err(|e| format!("Failed to open file: {}", e))?;

    let mut chunks = Vec::new();
    let mut buffer = vec![0u8; chunk_size];

    loop {
        match file.read(&mut buffer) {
            Ok(0) => break, // EOF
            Ok(n) => {
                chunks.push(buffer[..n].to_vec());
            }
            Err(e) => return Err(format!("Failed to read file: {}", e)),
        }
    }

    Ok(chunks)
}

/// Reassemble chunks into a file
pub fn reassemble_file(chunks: Vec<Vec<u8>>, output_path: String) -> Result<(), String> {
    // Path traversal protection: prevent use of ".." in paths
    let path = Path::new(&output_path);
    if path.components().any(|c| matches!(c, std::path::Component::ParentDir)) {
        return Err("Path traversal attempt detected".to_string());
    }

    let mut file = File::create(&output_path)
        .map_err(|e| format!("Failed to create file: {}", e))?;

    for chunk in chunks {
        file.write_all(&chunk)
            .map_err(|e| format!("Failed to write to file: {}", e))?;
    }

    Ok(())
}

/// Calculate file hash for integrity verification
pub fn calculate_file_hash(file_path: String) -> Result<String, String> {
    use sha2::{Digest, Sha256};

    let mut file = File::open(&file_path)
        .map_err(|e| format!("Failed to open file: {}", e))?;

    let mut hasher = Sha256::new();
    let mut buffer = [0u8; 8192];

    loop {
        match file.read(&mut buffer) {
            Ok(0) => break,
            Ok(n) => hasher.update(&buffer[..n]),
            Err(e) => return Err(format!("Failed to read file: {}", e)),
        }
    }

    Ok(hex::encode(hasher.finalize()))
}

/// Verify file integrity
pub fn verify_file_integrity(file_path: String, expected_hash: String) -> Result<bool, String> {
    let actual_hash = calculate_file_hash(file_path)?;
    Ok(actual_hash == expected_hash)
}

/// Get file size
pub fn get_file_size(file_path: String) -> Result<u64, String> {
    let metadata = std::fs::metadata(&file_path)
        .map_err(|e| format!("Failed to get file metadata: {}", e))?;
    Ok(metadata.len())
}

/// Get file name from path
pub fn get_file_name(file_path: String) -> Result<String, String> {
    Path::new(&file_path)
        .file_name()
        .and_then(|name| name.to_str())
        .map(|s| s.to_string())
        .ok_or_else(|| "Failed to extract file name".to_string())
}

#[cfg(test)]
mod tests {
    use super::*;
    use std::io::Write;

    #[test]
    fn test_chunk_file() {
        // Create a temporary test file
        let test_path = std::env::temp_dir().join("test_chunk.bin");
        let mut file = File::create(&test_path).expect("Failed to create test file");
        file.write_all(&vec![0u8; 2048])
            .expect("Failed to write test data");

        let chunks = chunk_file(test_path.to_str().unwrap().to_string(), 512).expect("Chunking failed");
        assert_eq!(chunks.len(), 4); // 2048 / 512 = 4 chunks

        std::fs::remove_file(test_path).ok();
    }

    #[test]
    fn test_get_file_size() {
        let test_path = std::env::temp_dir().join("test_size.bin");
        let mut file = File::create(&test_path).expect("Failed to create test file");
        file.write_all(&vec![0u8; 1024])
            .expect("Failed to write test data");

        let size = get_file_size(test_path.to_str().unwrap().to_string()).expect("Failed to get size");
        assert_eq!(size, 1024);

        std::fs::remove_file(test_path).ok();
    }
}
