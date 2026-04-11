use std::fs::File;
use std::io::{Read, Write, BufReader, BufWriter};
use std::path::Path;
use std::sync::{Arc, Mutex};
use std::time::Instant;

/// High-performance transfer engine for file operations
pub struct TransferEngine {
    /// Buffer size for optimal performance (1MB)
    buffer_size: usize,
    /// Progress callback
    progress_callback: Option<Arc<Mutex<Box<dyn Fn(u64, u64) + Send>>>>,
}

impl TransferEngine {
    /// Create a new transfer engine with default settings
    pub fn new() -> Self {
        TransferEngine {
            buffer_size: 1024 * 1024, // 1MB buffer
            progress_callback: None,
        }
    }

    /// Create a new transfer engine with custom buffer size
    pub fn with_buffer_size(buffer_size: usize) -> Self {
        TransferEngine {
            buffer_size,
            progress_callback: None,
        }
    }

    /// Set progress callback
    pub fn set_progress_callback<F>(&mut self, callback: F)
    where
        F: Fn(u64, u64) + Send + 'static,
    {
        self.progress_callback = Some(Arc::new(Mutex::new(Box::new(callback))));
    }

    /// Read file with optimal buffering
    pub fn read_file(&self, path: &str) -> Result<Vec<u8>, String> {
        let start = Instant::now();
        
        let file = File::open(path)
            .map_err(|e| format!("Failed to open file: {}", e))?;

        let file_size = file.metadata()
            .map_err(|e| format!("Failed to get file metadata: {}", e))?
            .len();

        let mut reader = BufReader::with_capacity(self.buffer_size, file);
        let mut buffer = Vec::with_capacity(file_size as usize);

        reader.read_to_end(&mut buffer)
            .map_err(|e| format!("Failed to read file: {}", e))?;

        let elapsed = start.elapsed();
        let speed_mbps = (file_size as f64 / 1024.0 / 1024.0) / elapsed.as_secs_f64();
        
        println!("Read {} bytes in {:?} ({:.2} MB/s)", file_size, elapsed, speed_mbps);

        Ok(buffer)
    }

    /// Write file with optimal buffering
    pub fn write_file(&self, path: &str, data: &[u8]) -> Result<(), String> {
        let start = Instant::now();
        
        let file = File::create(path)
            .map_err(|e| format!("Failed to create file: {}", e))?;

        let mut writer = BufWriter::with_capacity(self.buffer_size, file);
        writer.write_all(data)
            .map_err(|e| format!("Failed to write file: {}", e))?;

        writer.flush()
            .map_err(|e| format!("Failed to flush file: {}", e))?;

        let elapsed = start.elapsed();
        let speed_mbps = (data.len() as f64 / 1024.0 / 1024.0) / elapsed.as_secs_f64();
        
        println!("Wrote {} bytes in {:?} ({:.2} MB/s)", data.len(), elapsed, speed_mbps);

        Ok(())
    }

    /// Copy file with progress tracking
    pub fn copy_file_with_progress(&self, src: &str, dst: &str) -> Result<u64, String> {
        let start = Instant::now();
        
        let src_file = File::open(src)
            .map_err(|e| format!("Failed to open source file: {}", e))?;

        let total_size = src_file.metadata()
            .map_err(|e| format!("Failed to get source metadata: {}", e))?
            .len();

        let mut reader = BufReader::with_capacity(self.buffer_size, src_file);
        let dst_file = File::create(dst)
            .map_err(|e| format!("Failed to create destination file: {}", e))?;

        let mut writer = BufWriter::with_capacity(self.buffer_size, dst_file);
        let mut buffer = vec![0u8; self.buffer_size];
        let mut copied = 0u64;

        loop {
            let n = reader.read(&mut buffer)
                .map_err(|e| format!("Failed to read: {}", e))?;

            if n == 0 {
                break;
            }

            writer.write_all(&buffer[..n])
                .map_err(|e| format!("Failed to write: {}", e))?;

            copied += n as u64;

            // Call progress callback if set
            if let Some(ref callback) = self.progress_callback {
                if let Ok(cb) = callback.lock() {
                    cb(copied, total_size);
                }
            }
        }

        writer.flush()
            .map_err(|e| format!("Failed to flush: {}", e))?;

        let elapsed = start.elapsed();
        let speed_mbps = (total_size as f64 / 1024.0 / 1024.0) / elapsed.as_secs_f64();
        
        println!("Copied {} bytes in {:?} ({:.2} MB/s)", total_size, elapsed, speed_mbps);

        Ok(copied)
    }

    /// Calculate file hash with streaming for large files
    pub fn calculate_hash(&self, path: &str) -> Result<String, String> {
        use sha2::{Sha256, Digest};

        let file = File::open(path)
            .map_err(|e| format!("Failed to open file: {}", e))?;

        let mut reader = BufReader::with_capacity(self.buffer_size, file);
        let mut hasher = Sha256::new();
        let mut buffer = vec![0u8; self.buffer_size];

        loop {
            let n = reader.read(&mut buffer)
                .map_err(|e| format!("Failed to read: {}", e))?;

            if n == 0 {
                break;
            }

            hasher.update(&buffer[..n]);
        }

        let result = hasher.finalize();
        Ok(format!("{:x}", result))
    }

    /// Parallel file operations for multiple files
    pub fn copy_multiple_files(&self, files: Vec<(String, String)>) -> Result<Vec<u64>, String> {
        let mut results = Vec::new();

        for (src, dst) in files {
            let copied = self.copy_file_with_progress(&src, &dst)?;
            results.push(copied);
        }

        Ok(results)
    }

    /// Get file size efficiently
    pub fn get_file_size(&self, path: &str) -> Result<u64, String> {
        std::fs::metadata(path)
            .map(|m| m.len())
            .map_err(|e| format!("Failed to get file size: {}", e))
    }

    /// Check if file exists
    pub fn file_exists(&self, path: &str) -> bool {
        Path::new(path).exists()
    }

    /// Delete file safely
    pub fn delete_file(&self, path: &str) -> Result<(), String> {
        std::fs::remove_file(path)
            .map_err(|e| format!("Failed to delete file: {}", e))
    }

    /// Create directory if not exists
    pub fn create_directory(&self, path: &str) -> Result<(), String> {
        std::fs::create_dir_all(path)
            .map_err(|e| format!("Failed to create directory: {}", e))
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use std::fs;

    #[test]
    fn test_transfer_engine_creation() {
        let engine = TransferEngine::new();
        assert_eq!(engine.buffer_size, 1024 * 1024);
    }

    #[test]
    fn test_custom_buffer_size() {
        let engine = TransferEngine::with_buffer_size(512 * 1024);
        assert_eq!(engine.buffer_size, 512 * 1024);
    }

    #[test]
    fn test_file_operations() {
        let engine = TransferEngine::new();
        let test_file = "/tmp/test_transfer.txt";
        let test_data = b"Hello, Rust Transfer Engine!";

        // Write file
        assert!(engine.write_file(test_file, test_data).is_ok());

        // Check file exists
        assert!(engine.file_exists(test_file));

        // Get file size
        let size = engine.get_file_size(test_file).unwrap();
        assert_eq!(size, test_data.len() as u64);

        // Read file
        let read_data = engine.read_file(test_file).unwrap();
        assert_eq!(read_data, test_data);

        // Delete file
        assert!(engine.delete_file(test_file).is_ok());
        assert!(!engine.file_exists(test_file));
    }
}
