use aes_gcm::{
    aead::{Aead, KeyInit},
    Aes256Gcm, Nonce,
};
use flutter_rust_bridge::frb;
use rand::Rng;
use sha2::{Digest, Sha256};

/// AES-256-GCM encryption with SIMD optimization when available.
#[frb]
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

/// AES-256-GCM decryption with SIMD optimization when available.
#[frb]
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

/// Generate a random 256-bit (32-byte) encryption key.
#[frb]
pub fn generate_key() -> Vec<u8> {
    let mut rng = rand::thread_rng();
    let mut key = vec![0u8; 32];
    rng.fill(&mut key[..]);
    key
}

/// Generate a random 96-bit (12-byte) GCM nonce.
#[frb]
pub fn generate_nonce() -> Vec<u8> {
    let mut rng = rand::thread_rng();
    let mut nonce = vec![0u8; 12];
    rng.fill(&mut nonce[..]);
    nonce
}

/// Calculate SHA-256 hash of raw bytes.
#[frb]
pub fn hash_sha256(data: Vec<u8>) -> Vec<u8> {
    let mut hasher = Sha256::new();
    hasher.update(&data);
    hasher.finalize().to_vec()
}

/// Calculate SHA-256 hash of a file using an 8 KB streaming buffer.
#[frb]
pub fn hash_file(path: String) -> Result<Vec<u8>, String> {
    use std::fs::File;
    use std::io::{BufReader, Read};

    let file = File::open(&path).map_err(|e| format!("Failed to open file: {}", e))?;
    let mut reader = BufReader::new(file);
    let mut buffer = vec![0u8; 8192];
    let mut hasher = Sha256::new();

    loop {
        match reader.read(&mut buffer) {
            Ok(0) => break,
            Ok(n) => hasher.update(&buffer[..n]),
            Err(e) => return Err(format!("Failed to read file: {}", e)),
        }
    }

    Ok(hasher.finalize().to_vec())
}

/// Optimised SHA-256 file hash using a 64 KB streaming buffer — best for large files.
#[frb]
pub fn hash_file_optimized(path: String) -> Result<Vec<u8>, String> {
    use std::fs::File;
    use std::io::{BufReader, Read};

    let file = File::open(&path).map_err(|e| format!("Failed to open file: {}", e))?;
    let mut reader = BufReader::with_capacity(65536, file);
    let mut buffer = vec![0u8; 65536];
    let mut hasher = Sha256::new();

    loop {
        match reader.read(&mut buffer) {
            Ok(0) => break,
            Ok(n) => hasher.update(&buffer[..n]),
            Err(e) => return Err(format!("Failed to read file: {}", e)),
        }
    }

    Ok(hasher.finalize().to_vec())
}

/// Verify file integrity by comparing its SHA-256 hash against an expected hex string.
#[frb]
pub fn verify_file_integrity(file_path: String, expected_hash: String) -> Result<bool, String> {
    let actual_hash = hash_file(file_path)?;
    let actual_hex = hex::encode(&actual_hash);
    Ok(actual_hex == expected_hash)
}

/// Batch hash multiple files, returning one hash per file in the same order.
#[frb]
pub fn batch_hash_files(file_paths: Vec<String>) -> Result<Vec<Vec<u8>>, String> {
    let mut results = Vec::with_capacity(file_paths.len());
    for path in file_paths {
        results.push(hash_file_optimized(path)?);
    }
    Ok(results)
}

/// Derive a 32-byte key from a password and salt using a single SHA-256 round.
/// For production use consider PBKDF2 or Argon2 instead.
#[frb]
pub fn derive_key_from_password(password: String, salt: Vec<u8>) -> Vec<u8> {
    let mut hasher = Sha256::new();
    hasher.update(password.as_bytes());
    hasher.update(&salt);
    hasher.finalize().to_vec()
}

/// Validate that a hex key string is exactly 64 characters of valid hex.
/// Returns an error string on failure, or Ok(()) on success.
#[frb]
pub fn validate_key_string(key_str: String) -> Result<(), String> {
    if key_str.len() != 64 {
        return Err(format!(
            "Key must be 64 hex characters, got {}",
            key_str.len()
        ));
    }
    for ch in key_str.chars() {
        if !ch.is_ascii_hexdigit() {
            return Err(format!("Invalid hex character: '{}'", ch));
        }
    }
    Ok(())
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
    fn test_encrypt_decrypt_roundtrip() {
        let plaintext = b"Hello, World!".to_vec();
        let key = generate_key();
        let nonce = generate_nonce();

        let ciphertext =
            encrypt_aes_gcm(plaintext.clone(), key.clone(), nonce.clone())
                .expect("Encryption failed");
        let decrypted =
            decrypt_aes_gcm(ciphertext, key, nonce).expect("Decryption failed");

        assert_eq!(plaintext, decrypted);
    }

    #[test]
    fn test_hash_sha256() {
        let data = b"test data".to_vec();
        let hash = hash_sha256(data);
        assert_eq!(hash.len(), 32);
    }

    #[test]
    fn test_validate_key_string_valid() {
        let valid_key =
            "0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef";
        assert!(validate_key_string(valid_key.to_string()).is_ok());
    }

    #[test]
    fn test_validate_key_string_too_short() {
        assert!(validate_key_string("too_short".to_string()).is_err());
    }

    #[test]
    fn test_validate_key_string_invalid_hex() {
        let invalid =
            "0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdeg";
        assert!(validate_key_string(invalid.to_string()).is_err());
    }

    #[test]
    fn test_derive_key_from_password() {
        let password = "test_password".to_string();
        let salt = b"test_salt".to_vec();
        let key1 = derive_key_from_password(password.clone(), salt.clone());
        let key2 = derive_key_from_password(password, salt);
        assert_eq!(key1, key2);
        assert_eq!(key1.len(), 32);
    }
}
