use aes_gcm::{
    aead::{Aead, KeyInit},
    Aes256Gcm, Nonce,
};
use rand::Rng;
use sha2::{Digest, Sha256};

/// AES-256-GCM encryption with SIMD optimization when available
pub fn encrypt_aes_gcm(
    plaintext: Vec<u8>,
    key: Vec<u8>,
    nonce: Vec<u8>,
) -> Result<Vec<u8>, String> {
    if key.len() != 32 {
        return Err("Key must be 32 bytes for AES-256".to_string());
    }

    if nonce.len() != 12 {
        return Err("Nonce must be 12 bytes".to_string());
    }

    let cipher = Aes256Gcm::new_from_slice(&key)
        .map_err(|e| format!("Failed to create cipher: {}", e))?;

    let nonce = Nonce::from_slice(&nonce);

    cipher
        .encrypt(nonce, plaintext.as_ref())
        .map_err(|e| format!("Encryption failed: {}", e))
}

/// AES-256-GCM decryption with SIMD optimization when available
pub fn decrypt_aes_gcm(
    ciphertext: Vec<u8>,
    key: Vec<u8>,
    nonce: Vec<u8>,
) -> Result<Vec<u8>, String> {
    if key.len() != 32 {
        return Err("Key must be 32 bytes for AES-256".to_string());
    }

    if nonce.len() != 12 {
        return Err("Nonce must be 12 bytes".to_string());
    }

    let cipher = Aes256Gcm::new_from_slice(&key)
        .map_err(|e| format!("Failed to create cipher: {}", e))?;

    let nonce = Nonce::from_slice(&nonce);

    cipher
        .decrypt(nonce, ciphertext.as_ref())
        .map_err(|e| format!("Decryption failed: {}", e))
}

/// Generate a random 256-bit key
pub fn generate_key() -> Vec<u8> {
    let mut rng = rand::thread_rng();
    let mut key = vec![0u8; 32];
    rng.fill(&mut key[..]);
    key
}

/// Generate a random 96-bit nonce
pub fn generate_nonce() -> Vec<u8> {
    let mut rng = rand::thread_rng();
    let mut nonce = vec![0u8; 12];
    rng.fill(&mut nonce[..]);
    nonce
}

/// Calculate SHA-256 hash of data
pub fn hash_sha256(data: Vec<u8>) -> Vec<u8> {
    let mut hasher = Sha256::new();
    hasher.update(&data);
    hasher.finalize().to_vec()
}

/// Calculate SHA-256 hash of a file with streaming and SIMD optimization
pub fn hash_file(path: String) -> Result<Vec<u8>, String> {
    use std::fs::File;
    use std::io::{BufReader, Read};
    
    let file = File::open(&path)
        .map_err(|e| format!("Failed to open file: {}", e))?;
    
    let mut reader = BufReader::new(file);
    let mut buffer = vec![0u8; 8192]; // 8KB buffer for streaming
    let mut hasher = Sha256::new();
    
    loop {
        match reader.read(&mut buffer) {
            Ok(0) => break, // EOF
            Ok(n) => hasher.update(&buffer[..n]),
            Err(e) => return Err(format!("Failed to read file: {}", e)),
        }
    }
    
    Ok(hasher.finalize().to_vec())
}

/// Optimized file hashing for large files
pub fn hash_file_optimized(path: String) -> Result<Vec<u8>, String> {
    use std::fs::File;
    use std::io::{BufReader, Read};
    
    let file = File::open(&path)
        .map_err(|e| format!("Failed to open file: {}", e))?;
    
    let mut reader = BufReader::with_capacity(65536, file); // 64KB buffer for large files
    let mut hasher = Sha256::new();
    let mut buffer = vec![0u8; 65536];
    
    loop {
        match reader.read(&mut buffer) {
            Ok(0) => break, // EOF
            Ok(n) => hasher.update(&buffer[..n]),
            Err(e) => return Err(format!("Failed to read file: {}", e)),
        }
    }
    
    Ok(hasher.finalize().to_vec())
}

/// Verify file integrity by comparing hashes
pub fn verify_file_integrity(file_path: String, expected_hash: String) -> Result<bool, String> {
    let actual_hash = hash_file(file_path)?;
    let actual_hex = hex::encode(&actual_hash);
    Ok(actual_hex == expected_hash)
}

/// Batch hash multiple files with optimized implementation
pub fn batch_hash_files(file_paths: Vec<String>) -> Result<Vec<Vec<u8>>, String> {
    let mut results = Vec::with_capacity(file_paths.len());
    
    for path in file_paths {
        let hash = hash_file_optimized(path)?;
        results.push(hash);
    }
    
    Ok(results)
}

/// Zero-copy string validation for better performance
pub fn validate_key_string(key_str: &str) -> Result<&[u8], &'static str> {
    if key_str.len() != 64 { // 32 bytes in hex = 64 characters
        return Err("Key must be 64 hex characters");
    }
    
    // Validate hex characters
    for byte in key_str.bytes() {
        if !byte.is_ascii_hexdigit() {
            return Err("Key must contain only hex characters");
        }
    }
    
    Ok(key_str.as_bytes())
}

/// High-performance key derivation using SHA-256
pub fn derive_key_from_password(password: &str, salt: &[u8]) -> Vec<u8> {
    use sha2::{Sha256, Digest};
    
    let mut hasher = Sha256::new();
    hasher.update(password.as_bytes());
    hasher.update(salt);
    hasher.finalize().to_vec()
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_key_generation() {
        let key = generate_key();
        assert_eq!(key.len(), 32);
    }

    #[test]
    fn test_nonce_generation() {
        let nonce = generate_nonce();
        assert_eq!(nonce.len(), 12);
    }

    #[test]
    fn test_encrypt_decrypt() {
        let plaintext = b"Hello, World!".to_vec();
        let key = generate_key();
        let nonce = generate_nonce();

        let ciphertext = encrypt_aes_gcm(plaintext.clone(), key.clone(), nonce.clone())
            .expect("Encryption failed");
        let decrypted = decrypt_aes_gcm(ciphertext, key, nonce).expect("Decryption failed");

        assert_eq!(plaintext, decrypted);
    }

    #[test]
    fn test_hash_sha256() {
        let data = b"test data".to_vec();
        let hash = hash_sha256(data);
        assert_eq!(hash.len(), 32);
    }

    #[test]
    fn test_validate_key_string() {
        let valid_key = "0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef";
        assert!(validate_key_string(valid_key).is_ok());
        
        let invalid_key = "too_short";
        assert!(validate_key_string(invalid_key).is_err());
        
        let invalid_hex = "0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdeg";
        assert!(validate_key_string(invalid_hex).is_err());
    }

    #[test]
    fn test_derive_key_from_password() {
        let password = "test_password";
        let salt = b"test_salt";
        let key1 = derive_key_from_password(password, salt);
        let key2 = derive_key_from_password(password, salt);
        
        assert_eq!(key1, key2); // Same password and salt should produce same key
        assert_eq!(key1.len(), 32);
    }

    #[test]
    fn test_batch_hash_files() {
        // Create test files
        use std::fs::File;
        use std::io::Write;
        
        let test_paths = vec![
            "/tmp/test_file1.txt".to_string(),
            "/tmp/test_file2.txt".to_string(),
        ];
        
        // Create test files
        for (i, path) in test_paths.iter().enumerate() {
            let mut file = File::create(path).expect("Failed to create test file");
            writeln!(file, "Test content {}", i).expect("Failed to write test data");
        }
        
        let hashes = batch_hash_files(test_paths.clone()).expect("Batch hashing failed");
        assert_eq!(hashes.len(), 2);
        
        // Clean up
        for path in test_paths {
            std::fs::remove_file(path).ok();
        }
    }
}