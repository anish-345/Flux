import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:flux/src/rust/api/crypto.dart' as rust_crypto;
import 'package:flux/utils/logger.dart';

/// Service for encrypting and decrypting file transfers
/// Uses Rust backend for AES-256-GCM with SIMD acceleration
class EncryptionService {
  static final EncryptionService _instance = EncryptionService._internal();
  factory EncryptionService() => _instance;
  EncryptionService._internal();

  // AES-256 GCM nonce size — used by encryptText/decryptText
  static const int _ivSize = 12;

  /// Convert bytes to hex string
  static String _bytesToHex(List<int> bytes) {
    return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }

  /// Generate a secure random encryption key using Rust
  Future<String> generateKey() async {
    final keyBytes = await rust_crypto.generateKey();
    return base64Encode(keyBytes);
  }

  /// Generate a secure random nonce using Rust
  Future<String> generateNonce() async {
    final nonceBytes = await rust_crypto.generateNonce();
    return base64Encode(nonceBytes);
  }

  /// Derive encryption key from password using Rust (SHA-256 based KDF)
  Future<String> deriveKeyFromPassword(String password, {String? salt}) async {
    final saltBytes = salt != null
        ? base64Decode(salt)
        : (await rust_crypto.generateNonce());

    final derivedKey = await rust_crypto.deriveKeyFromPassword(
      password: password,
      salt: saltBytes,
    );
    return base64Encode(derivedKey);
  }

  // Chunk size for the hash fallback path only
  static const int _hashChunkSize = 1024 * 1024; // 1 MB

  /// Encrypt a small piece of data (for metadata) using Rust
  Future<String> encryptText(String text, String base64Key) async {
    try {
      final textBytes = utf8.encode(text);
      final keyBytes = base64Decode(base64Key);
      final nonceBytes = await rust_crypto.generateNonce();

      // Use Rust for encryption
      final encryptedBytes = await rust_crypto.encryptAesGcm(
        plaintext: textBytes,
        key: keyBytes,
        nonce: nonceBytes,
      );

      // Return nonce + encrypted data as base64
      final combined = Uint8List.fromList(nonceBytes + encryptedBytes);
      return base64Encode(combined);
    } catch (e) {
      AppLogger.error('Failed to encrypt text via Rust', e);
      rethrow;
    }
  }

  /// Decrypt text data using Rust
  Future<String> decryptText(String encryptedBase64, String base64Key) async {
    try {
      final combined = base64Decode(encryptedBase64);
      final nonceBytes = combined.sublist(0, _ivSize);
      final ciphertextBytes = combined.sublist(_ivSize);
      final keyBytes = base64Decode(base64Key);

      // Use Rust for decryption
      final decryptedBytes = await rust_crypto.decryptAesGcm(
        ciphertext: ciphertextBytes,
        key: keyBytes,
        nonce: nonceBytes,
      );

      return utf8.decode(decryptedBytes);
    } catch (e) {
      AppLogger.error('Failed to decrypt text via Rust', e);
      rethrow;
    }
  }

  /// Calculate SHA-256 hash of file using Rust for integrity verification
  Future<String> calculateFileHash(String filePath) async {
    try {
      final hashBytes = await rust_crypto.hashFileOptimized(path: filePath);
      return _bytesToHex(hashBytes);
    } catch (e) {
      AppLogger.warning(
        'Rust hashFileOptimized failed for $filePath: $e — using Dart fallback',
      );
      // Chunked fallback: never holds more than _hashChunkSize bytes at once.
      final raf = await File(filePath).open();
      Digest? result;
      final sink = sha256.startChunkedConversion(
        ChunkedConversionSink<Digest>.withCallback((digests) {
          result = digests.single;
        }),
      );
      final buffer = Uint8List(_hashChunkSize);
      try {
        while (true) {
          final n = await raf.readInto(buffer);
          if (n == 0) break;
          sink.add(buffer.sublist(0, n));
        }
        sink.close();
      } finally {
        await raf.close();
      }
      return result!.toString();
    }
  }

  /// Verify file integrity against hash using Rust
  Future<bool> verifyFileIntegrity(String filePath, String expectedHash) async {
    try {
      final actualHash = await calculateFileHash(filePath);
      return actualHash.toLowerCase() == expectedHash.toLowerCase();
    } catch (e) {
      AppLogger.error('Failed to verify file integrity', e);
      return false;
    }
  }

  /// Generate a secure session key for a transfer
  Future<String> generateSessionKey() async {
    return generateKey();
  }
}
