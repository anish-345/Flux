use aes_gcm::{
    aead::{Aead, KeyInit, Payload},
    Aes256Gcm, Nonce,
};
use rand::Rng;
use sha2::{Digest, Sha256};

/// AES-256-GCM encryption
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

/// AES-256-GCM decryption
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

/// Calculate SHA-256 hash of a file
pub fn hash_file(path: String) -> Result<Vec<u8>, String> {
    use std::fs::File;
    use std::io::{BufReader, Read};

    let file = File::open(&path).map_err(|e| format!("Failed to open file: {}", e))?;
    let mut reader = BufReader::with_capacity(1024 * 1024, file); // 1MB buffer
    let mut hasher = Sha256::new();
    let mut buffer = [0u8; 8192];

    loop {
        let n = reader
            .read(&mut buffer)
            .map_err(|e| format!("Failed to read file: {}", e))?;
        if n == 0 {
            break;
        }
        hasher.update(&buffer[..n]);
    }

    Ok(hasher.finalize().to_vec())
}

/// Verify file integrity by comparing hashes
pub fn verify_file_integrity(file_path: String, expected_hash: String) -> Result<bool, String> {
    let actual_hash = hash_file(file_path)?;
    let actual_hex = hex::encode(&actual_hash);
    Ok(actual_hex == expected_hash)
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
}
