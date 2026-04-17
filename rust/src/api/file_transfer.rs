use std::fs::File;
use std::io::{Read, Write};
use std::path::Path;
use std::sync::Mutex;
use std::collections::VecDeque;
use lazy_static::lazy_static;

const CHUNK_SIZE: usize = 1024 * 1024; // 1MB chunks

// Memory pool for buffer reuse
lazy_static! {
    static ref BUFFER_POOL: Mutex<VecDeque<Vec<u8>>> = Mutex::new(VecDeque::new());
}

/// Get a buffer from the pool or create a new one
pub fn get_buffer(size: usize) -> Vec<u8> {
    let mut pool = BUFFER_POOL.lock().unwrap();
    pool.pop_back().filter(|buf| buf.capacity() >= size)
        .unwrap_or_else(|| Vec::with_capacity(size.max(8192)))
}

/// Return a buffer to the pool for reuse
pub fn return_buffer(mut buf: Vec<u8>) {
    buf.clear();
    let mut pool = BUFFER_POOL.lock().unwrap();
    if pool.len() < 100 { // Limit pool size to prevent memory bloat
        pool.push_back(buf);
    }
}

/// Chunk a file into smaller pieces for transfer - STREAMING VERSION
/// This prevents memory exhaustion for large files
pub fn chunk_file_streaming(
    file_path: String, 
    chunk_size: usize,
    mut callback: impl FnMut(&[u8]) -> Result<(), String>
) -> Result<(), String> {
    let mut file = File::open(&file_path)
        .map_err(|e| format!("Failed to open file: {}", e))?;

    let mut buffer = get_buffer(chunk_size);
    
    loop {
        match file.read(&mut buffer) {
            Ok(0) => break, // EOF
            Ok(n) => {
                callback(&buffer[..n])?;
                // Reuse buffer for next chunk
                if buffer.len() != chunk_size {
                    buffer = get_buffer(chunk_size);
                }
            }
            Err(e) => {
                return_buffer(buffer);
                return Err(format!("Failed to read file: {}", e));
            }
        }
    }
    
    return_buffer(buffer);
    Ok(())
}

/// Legacy function - kept for compatibility but deprecated
#[deprecated(note = "Use chunk_file_streaming instead to avoid memory issues")]
pub fn chunk_file(file_path: String, chunk_size: usize) -> Result<Vec<Vec<u8>>, String> {
    let mut chunks = Vec::new();
    
    chunk_file_streaming(file_path, chunk_size, |chunk| {
        chunks.push(chunk.to_vec());
        Ok(())
    })?;
    
    Ok(chunks)
}

/// Reassemble chunks into a file with streaming
pub fn reassemble_file_streaming(
    chunk_stream: impl Iterator<Item = Vec<u8>>,
    output_path: String
) -> Result<(), String> {
    let mut file = File::create(&output_path)
        .map_err(|e| format!("Failed to create file: {}", e))?;

    for chunk in chunk_stream {
        file.write_all(&chunk)
            .map_err(|e| format!("Failed to write to file: {}", e))?;
    }

    Ok(())
}

/// Legacy function - kept for compatibility
pub fn reassemble_file(chunks: Vec<Vec<u8>>, output_path: String) -> Result<(), String> {
    reassemble_file_streaming(chunks.into_iter(), output_path)
}

/// Calculate file hash for integrity verification with streaming
pub fn calculate_file_hash_streaming(file_path: String) -> Result<String, String> {
    use sha2::{Digest, Sha256};

    let mut file = File::open(&file_path)
        .map_err(|e| format!("Failed to open file: {}", e))?;

    let mut hasher = Sha256::new();
    let mut buffer = get_buffer(8192);

    loop {
        match file.read(&mut buffer) {
            Ok(0) => break,
            Ok(n) => hasher.update(&buffer[..n]),
            Err(e) => {
                return_buffer(buffer);
                return Err(format!("Failed to read file: {}", e));
            }
        }
    }
    
    return_buffer(buffer);
    Ok(hex::encode(hasher.finalize()))
}

/// Legacy function - kept for compatibility
pub fn calculate_file_hash(file_path: String) -> Result<String, String> {
    calculate_file_hash_streaming(file_path)
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

/// Async version of file chunking for better performance
pub async fn chunk_file_async(
    file_path: String, 
    chunk_size: usize
) -> Result<Vec<Vec<u8>>, String> {
    use tokio::fs::File;
    use tokio::io::AsyncReadExt;
    
    let mut file = File::open(&file_path).await
        .map_err(|e| format!("Failed to open file: {}", e))?;

    let mut chunks = Vec::new();
    let mut buffer = get_buffer(chunk_size);

    loop {
        match file.read(&mut buffer).await {
            Ok(0) => break,
            Ok(n) => {
                chunks.push(buffer[..n].to_vec());
                // Reuse buffer for next chunk
                if buffer.len() != chunk_size {
                    buffer = get_buffer(chunk_size);
                }
            }
            Err(e) => {
                return_buffer(buffer);
                return Err(format!("Failed to read file: {}", e));
            }
        }
    }
    
    return_buffer(buffer);
    Ok(chunks)
}

/// Async version of file reassembly
pub async fn reassemble_file_async(
    chunks: Vec<Vec<u8>>, 
    output_path: String
) -> Result<(), String> {
    use tokio::fs::File;
    use tokio::io::AsyncWriteExt;
    
    let mut file = File::create(&output_path).await
        .map_err(|e| format!("Failed to create file: {}", e))?;

    for chunk in chunks {
        file.write_all(&chunk).await
            .map_err(|e| format!("Failed to write to file: {}", e))?;
    }

    Ok(())
}

#[cfg(test)]
mod tests {
    use super::*;
    use std::io::Write;

    #[test]
    fn test_chunk_file_streaming() {
        // Create a temporary test file
        let test_path = "/tmp/test_chunk_streaming.bin";
        let test_data = vec![0u8; 2048];
        let mut file = File::create(test_path).expect("Failed to create test file");
        file.write_all(&test_data).expect("Failed to write test data");

        let mut chunks = Vec::new();
        chunk_file_streaming(test_path.to_string(), 512, |chunk| {
            chunks.push(chunk.to_vec());
            Ok(())
        }).expect("Streaming chunking failed");

        assert_eq!(chunks.len(), 4); // 2048 / 512 = 4 chunks
        
        // Verify data integrity
        let mut reconstructed = Vec::new();
        for chunk in chunks {
            reconstructed.extend_from_slice(&chunk);
        }
        assert_eq!(reconstructed, test_data);

        std::fs::remove_file(test_path).ok();
    }

    #[test]
    fn test_memory_pool() {
        // Test buffer pool functionality
        let buf1 = get_buffer(1024);
        let buf2 = get_buffer(1024);
        
        assert_eq!(buf1.capacity(), 1024);
        assert_eq!(buf2.capacity(), 1024);
        
        return_buffer(buf1);
        return_buffer(buf2);
        
        // Should reuse from pool
        let buf3 = get_buffer(1024);
        assert_eq!(buf3.capacity(), 1024);
    }

    #[test]
    fn test_get_file_size() {
        let test_path = "/tmp/test_size.bin";
        let mut file = File::create(test_path).expect("Failed to create test file");
        file.write_all(&vec![0u8; 1024])
            .expect("Failed to write test data");

        let size = get_file_size(test_path.to_string()).expect("Failed to get size");
        assert_eq!(size, 1024);

        std::fs::remove_file(test_path).ok();
    }
}