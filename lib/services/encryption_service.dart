import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:flux/utils/logger.dart';

/// Service for encrypting and decrypting file transfers
/// Uses AES-256-GCM for authenticated encryption
class EncryptionService {
  static final EncryptionService _instance = EncryptionService._internal();
  factory EncryptionService() => _instance;
  EncryptionService._internal();

  // AES-256 key size
  static const int _keySize = 32;
  static const int _ivSize = 16;

  /// Generate a secure random encryption key
  String generateKey() {
    final random = encrypt.SecureRandom(_keySize);
    return base64Encode(random.bytes);
  }

  /// Derive encryption key from password using PBKDF2-like approach
  String deriveKeyFromPassword(String password, {String? salt}) {
    final saltBytes = salt != null 
        ? base64Decode(salt)
        : encrypt.SecureRandom(16).bytes;
    
    // Combine password and salt, then hash multiple times
    var bytes = utf8.encode(password) + saltBytes;
    for (int i = 0; i < 10000; i++) {
      bytes = sha256.convert(bytes).bytes;
    }
    
    return base64Encode(bytes);
  }

  /// Encrypt file and return encrypted bytes
  Future<Uint8List> encryptFile(
    String filePath,
    String base64Key, {
    Function(double progress)? onProgress,
  }) async {
    try {
      final key = encrypt.Key.fromBase64(base64Key);
      final iv = encrypt.IV.fromSecureRandom(_ivSize);
      final encrypter = encrypt.Encrypter(
        encrypt.AES(key, mode: encrypt.AESMode.gcm),
      );

      final file = File(filePath);
      final fileBytes = await file.readAsBytes();
      
      // Encrypt in chunks for large files
      final chunkSize = 64 * 1024; // 64KB chunks
      final encryptedChunks = <int>[];
      
      // Add IV at the beginning
      encryptedChunks.addAll(iv.bytes);
      
      for (int i = 0; i < fileBytes.length; i += chunkSize) {
        final end = (i + chunkSize < fileBytes.length) ? i + chunkSize : fileBytes.length;
        final chunk = fileBytes.sublist(i, end);
        
        final encrypted = encrypter.encryptBytes(chunk, iv: iv);
        encryptedChunks.addAll(encrypted.bytes);
        
        // Update progress
        final progress = end / fileBytes.length;
        onProgress?.call(progress);
        
        // Yield to event loop
        await Future.delayed(Duration.zero);
      }

      AppLogger.info('File encrypted successfully: $filePath');
      return Uint8List.fromList(encryptedChunks);
    } catch (e) {
      AppLogger.error('Failed to encrypt file', e);
      rethrow;
    }
  }

  /// Decrypt file and save to destination
  Future<void> decryptFile(
    Uint8List encryptedData,
    String destinationPath,
    String base64Key, {
    Function(double progress)? onProgress,
  }) async {
    try {
      final key = encrypt.Key.fromBase64(base64Key);
      
      // Extract IV from beginning of encrypted data
      final ivBytes = encryptedData.sublist(0, _ivSize);
      final iv = encrypt.IV(Uint8List.fromList(ivBytes));
      
      final encrypter = encrypt.Encrypter(
        encrypt.AES(key, mode: encrypt.AESMode.gcm),
      );

      // Decrypt in chunks
      final chunkSize = 64 * 1024 + 16; // 64KB + GCM tag
      final decryptedChunks = <int>[];
      
      final encryptedContent = encryptedData.sublist(_ivSize);
      
      for (int i = 0; i < encryptedContent.length; i += chunkSize) {
        final end = (i + chunkSize < encryptedContent.length) 
            ? i + chunkSize 
            : encryptedContent.length;
        final chunk = encryptedContent.sublist(i, end);
        
        final encrypted = encrypt.Encrypted(Uint8List.fromList(chunk));
        final decrypted = encrypter.decryptBytes(encrypted, iv: iv);
        decryptedChunks.addAll(decrypted);
        
        // Update progress
        final progress = end / encryptedContent.length;
        onProgress?.call(progress);
        
        // Yield to event loop
        await Future.delayed(Duration.zero);
      }

      // Write decrypted file
      final file = File(destinationPath);
      await file.writeAsBytes(decryptedChunks);

      AppLogger.info('File decrypted successfully: $destinationPath');
    } catch (e) {
      AppLogger.error('Failed to decrypt file', e);
      rethrow;
    }
  }

  /// Encrypt a small piece of data (for metadata)
  String encryptText(String text, String base64Key) {
    try {
      final key = encrypt.Key.fromBase64(base64Key);
      final iv = encrypt.IV.fromSecureRandom(_ivSize);
      final encrypter = encrypt.Encrypter(
        encrypt.AES(key, mode: encrypt.AESMode.gcm),
      );

      final encrypted = encrypter.encrypt(text, iv: iv);
      
      // Return IV + encrypted data as base64
      final combined = iv.bytes + encrypted.bytes;
      return base64Encode(combined);
    } catch (e) {
      AppLogger.error('Failed to encrypt text', e);
      rethrow;
    }
  }

  /// Decrypt text data
  String decryptText(String encryptedBase64, String base64Key) {
    try {
      final key = encrypt.Key.fromBase64(base64Key);
      
      final combined = base64Decode(encryptedBase64);
      final ivBytes = combined.sublist(0, _ivSize);
      final encryptedBytes = combined.sublist(_ivSize);
      
      final iv = encrypt.IV(Uint8List.fromList(ivBytes));
      final encrypter = encrypt.Encrypter(
        encrypt.AES(key, mode: encrypt.AESMode.gcm),
      );

      final encrypted = encrypt.Encrypted(Uint8List.fromList(encryptedBytes));
      return encrypter.decrypt(encrypted, iv: iv);
    } catch (e) {
      AppLogger.error('Failed to decrypt text', e);
      rethrow;
    }
  }

  /// Calculate SHA-256 hash of file for integrity verification
  Future<String> calculateFileHash(String filePath) async {
    try {
      final file = File(filePath);
      final bytes = await file.readAsBytes();
      final digest = sha256.convert(bytes);
      return digest.toString();
    } catch (e) {
      AppLogger.error('Failed to calculate file hash', e);
      return '';
    }
  }

  /// Verify file integrity against hash
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
  String generateSessionKey() {
    final random = encrypt.SecureRandom(_keySize);
    return base64Encode(random.bytes);
  }
}
