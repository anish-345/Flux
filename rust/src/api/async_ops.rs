use tokio::fs::File;
use tokio::io::{AsyncReadExt, AsyncWriteExt};
use crate::api::file_transfer::{get_buffer, return_buffer};

/// Async version of file chunking for better performance
pub async fn chunk_file_async(
    file_path: String, 
    chunk_size: usize
) -> Result<Vec<Vec<u8>>, String> {
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
    let mut file = File::create(&output_path).await
        .map_err(|e| format!("Failed to create file: {}", e))?;

    for chunk in chunks {
        file.write_all(&chunk).await
            .map_err(|e| format!("Failed to write to file: {}", e))?;
    }

    Ok(())
}

/// Async streaming file copy with progress callback
pub async fn copy_file_with_progress(
    source_path: String,
    destination_path: String,
    chunk_size: usize,
    progress_callback: impl Fn(u64) + Send + Sync,
) -> Result<u64, String> {
    let mut source = File::open(&source_path).await
        .map_err(|e| format!("Failed to open source file: {}", e))?;
    
    let mut destination = File::create(&destination_path).await
        .map_err(|e| format!("Failed to create destination file: {}", e))?;

    let mut buffer = get_buffer(chunk_size);
    let mut total_bytes = 0u64;

    loop {
        match source.read(&mut buffer).await {
            Ok(0) => break, // EOF
            Ok(n) => {
                destination.write_all(&buffer[..n]).await
                    .map_err(|e| format!("Failed to write chunk: {}", e))?;
                
                total_bytes += n as u64;
                progress_callback(total_bytes);
                
                // Reuse buffer for next chunk
                if buffer.len() != chunk_size {
                    buffer = get_buffer(chunk_size);
                }
            }
            Err(e) => {
                return_buffer(buffer);
                return Err(format!("Failed to read chunk: {}", e));
            }
        }
    }
    
    return_buffer(buffer);
    Ok(total_bytes)
}

/// Async file hash calculation with streaming
pub async fn hash_file_async(path: String) -> Result<Vec<u8>, String> {
    use sha2::{Sha256, Digest};
    
    let mut file = File::open(&path).await
        .map_err(|e| format!("Failed to open file: {}", e))?;
    
    let mut hasher = Sha256::new();
    let mut buffer = get_buffer(8192);

    loop {
        match file.read(&mut buffer).await {
            Ok(0) => break,
            Ok(n) => hasher.update(&buffer[..n]),
            Err(e) => {
                return_buffer(buffer);
                return Err(format!("Failed to read file: {}", e));
            }
        }
    }
    
    return_buffer(buffer);
    Ok(hasher.finalize().to_vec())
}

/// Async file metadata operations
pub mod metadata {
    /// Get file size asynchronously
    pub async fn get_file_size_async(path: String) -> Result<u64, String> {
        let metadata = tokio::fs::metadata(&path).await
            .map_err(|e| format!("Failed to get file metadata: {}", e))?;
        Ok(metadata.len())
    }
    
    /// Check if file exists asynchronously
    pub async fn file_exists_async(path: String) -> bool {
        tokio::fs::metadata(&path).await.is_ok()
    }
    
    /// Get file modification time asynchronously
    pub async fn get_file_modification_time_async(path: String) -> Result<std::time::SystemTime, String> {
        let metadata = tokio::fs::metadata(&path).await
            .map_err(|e| format!("Failed to get file metadata: {}", e))?;
        Ok(metadata.modified().map_err(|e| format!("Failed to get modification time: {}", e))?)
    }
}

/// Async network operations
pub mod network {
    use tokio::net::{TcpStream, TcpListener};
    use tokio::io::{AsyncReadExt, AsyncWriteExt};
    use std::time::Duration;
    
    /// Async TCP client connection
    pub async fn connect_async(address: String, port: u16) -> Result<TcpStream, String> {
        let addr = format!("{}:{}", address, port);
        let stream = TcpStream::connect(&addr).await
            .map_err(|e| format!("Failed to connect: {}", e))?;
        
        stream.set_nodelay(true)
            .map_err(|e| format!("Failed to set TCP_NODELAY: {}", e))?;
        
        Ok(stream)
    }
    
    /// Async TCP server
    pub async fn create_server_async(port: u16) -> Result<TcpListener, String> {
        let addr = format!("0.0.0.0:{}", port);
        let listener = TcpListener::bind(&addr).await
            .map_err(|e| format!("Failed to bind to {}: {}", addr, e))?;
        
        Ok(listener)
    }
    
    /// Async data transfer with timeout
    pub async fn transfer_data_async(
        mut stream: TcpStream,
        data: Vec<u8>,
        timeout: Duration,
    ) -> Result<(), String> {
        tokio::time::timeout(timeout, async {
            stream.write_all(&data).await
                .map_err(|e| format!("Failed to write data: {}", e))
        }).await
        .map_err(|_| "Transfer timeout")?
    }
    
    /// Async data receive with timeout
    pub async fn receive_data_async(
        mut stream: TcpStream,
        buffer_size: usize,
        timeout: Duration,
    ) -> Result<Vec<u8>, String> {
        let result = tokio::time::timeout(timeout, async {
            let mut buffer = vec![0u8; buffer_size];
            match stream.read(&mut buffer).await {
                Ok(n) => {
                    buffer.truncate(n);
                    Ok(buffer)
                }
                Err(e) => Err(format!("Failed to read data: {}", e)),
            }
        }).await;
        
        match result {
            Ok(Ok(data)) => Ok(data),
            Ok(Err(e)) => Err(e),
            Err(_) => Err("Receive timeout".to_string()),
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    
    #[tokio::test]
    async fn test_chunk_file_async() {
        // Create a temporary test file
        let test_path = "/tmp/test_chunk_async.bin";
        let test_data = vec![0u8; 2048];
        
        // Write test data
        let mut file = File::create(test_path).await.expect("Failed to create test file");
        file.write_all(&test_data).await.expect("Failed to write test data");
        file.flush().await.expect("Failed to flush");
        
        // Test async chunking
        let chunks = chunk_file_async(test_path.to_string(), 512).await.expect("Async chunking failed");
        assert_eq!(chunks.len(), 4); // 2048 / 512 = 4 chunks
        
        // Verify data integrity
        let mut reconstructed = Vec::new();
        for chunk in chunks {
            reconstructed.extend_from_slice(&chunk);
        }
        assert_eq!(reconstructed, test_data);

        // Clean up
        tokio::fs::remove_file(test_path).await.ok();
    }
    
    #[tokio::test]
    async fn test_copy_file_with_progress() {
        let source_path = "/tmp/test_source_async.bin";
        let dest_path = "/tmp/test_dest_async.bin";
        let test_data = vec![0u8; 1024];
        
        // Create source file
        let mut file = File::create(source_path).await.expect("Failed to create source file");
        file.write_all(&test_data).await.expect("Failed to write source data");
        file.flush().await.expect("Failed to flush");
        
        let mut progress_called = false;
        let progress_callback = |bytes: u64| {
            progress_called = true;
            assert_eq!(bytes, 1024);
        };
        
        // Test async copy with progress
        let bytes_copied = copy_file_with_progress(
            source_path.to_string(),
            dest_path.to_string(),
            256,
            progress_callback,
        ).await.expect("Async copy failed");
        
        assert_eq!(bytes_copied, 1024);
        assert!(progress_called);
        
        // Verify destination file
        let dest_data = tokio::fs::read(dest_path).await.expect("Failed to read destination file");
        assert_eq!(dest_data, test_data);
        
        // Clean up
        tokio::fs::remove_file(source_path).await.ok();
        tokio::fs::remove_file(dest_path).await.ok();
    }
    
    #[tokio::test]
    async fn test_hash_file_async() {
        let test_path = "/tmp/test_hash_async.bin";
        let test_data = b"test data for hashing";
        
        // Create test file
        let mut file = File::create(test_path).await.expect("Failed to create test file");
        file.write_all(test_data).await.expect("Failed to write test data");
        file.flush().await.expect("Failed to flush");
        
        // Test async hash
        let hash = hash_file_async(test_path.to_string()).await.expect("Async hash failed");
        assert_eq!(hash.len(), 32); // SHA-256 produces 32 bytes
        
        // Clean up
        tokio::fs::remove_file(test_path).await.ok();
    }
}