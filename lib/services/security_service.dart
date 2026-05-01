import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flux/src/rust/api/crypto.dart' as rust_crypto;

/// Service for security operations
class SecurityService {
  static const String _deviceFingerprintKey = 'device_fingerprint';
  static const String _securityEventsKey = 'security_events';

  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();

  late String _deviceFingerprint;
  bool _isInitialized = false;

  /// Initialize security service
  Future<void> initialize() async {
    if (_isInitialized) return;

    // Generate or retrieve device fingerprint
    _deviceFingerprint = await _getOrCreateDeviceFingerprint();

    _isInitialized = true;
  }

  /// Get device fingerprint
  String get deviceFingerprint => _deviceFingerprint;

  /// Store sensitive data securely
  Future<void> storeSecurely(String key, String value) async {
    await _secureStorage.write(key: key, value: value);
  }

  /// Retrieve sensitive data
  Future<String?> retrieveSecurely(String key) async {
    return await _secureStorage.read(key: key);
  }

  /// Delete sensitive data
  Future<void> deleteSecurely(String key) async {
    await _secureStorage.delete(key: key);
  }

  /// Clear all secure storage
  Future<void> clearAllSecure() async {
    await _secureStorage.deleteAll();
  }

  /// Generate device fingerprint
  Future<String> _getOrCreateDeviceFingerprint() async {
    // Try to retrieve existing fingerprint
    final existing = await _secureStorage.read(key: _deviceFingerprintKey);
    if (existing != null) {
      return existing;
    }

    // Generate new fingerprint
    final fingerprint = await _generateDeviceFingerprint();

    // Store it securely
    await _secureStorage.write(key: _deviceFingerprintKey, value: fingerprint);

    return fingerprint;
  }

  /// Generate unique device fingerprint
  Future<String> _generateDeviceFingerprint() async {
    try {
      final androidInfo = await _deviceInfo.androidInfo;

      // Combine multiple device identifiers
      final fingerprintData = {
        'device': androidInfo.device,
        'manufacturer': androidInfo.manufacturer,
        'model': androidInfo.model,
        'product': androidInfo.product,
        'hardware': androidInfo.hardware,
        'fingerprint': androidInfo.fingerprint,
        'buildId': androidInfo.id,
      };

      // Create hash using Rust
      final jsonString = jsonEncode(fingerprintData);
      final hash = await hashData(jsonString);

      return hash;
    } catch (e) {
      // Fallback: use timestamp and random
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final random = DateTime.now().microsecond;
      final fallback = '$timestamp-$random';
      return await hashData(fallback);
    }
  }

  /// Verify device fingerprint
  Future<bool> verifyDeviceFingerprint(String fingerprint) async {
    return fingerprint == _deviceFingerprint;
  }

  /// Hash sensitive data using Rust SHA-256 — SIMD accelerated, no Dart fallback.
  Future<String> hashData(String data) async {
    final dataBytes = utf8.encode(data);
    final hashBytes = await rust_crypto.hashSha256(data: dataBytes);
    return _bytesToHex(hashBytes);
  }

  /// Verify hashed data
  Future<bool> verifyHashedData(String data, String hash) async {
    final computedHash = await hashData(data);
    return computedHash == hash;
  }

  /// Convert bytes to hex string
  static String _bytesToHex(List<int> bytes) {
    return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }

  /// Log security event
  Future<void> logSecurityEvent(SecurityEvent event) async {
    try {
      final eventsJson = await _secureStorage.read(key: _securityEventsKey);
      final events = eventsJson != null
          ? List<Map<String, dynamic>>.from(jsonDecode(eventsJson))
          : [];

      events.add(event.toJson());

      // Keep only last 100 events
      if (events.length > 100) {
        events.removeAt(0);
      }

      await _secureStorage.write(
        key: _securityEventsKey,
        value: jsonEncode(events),
      );
    } catch (e) {
      // Silently fail to avoid disrupting app
    }
  }

  /// Get security events
  Future<List<SecurityEvent>> getSecurityEvents() async {
    try {
      final eventsJson = await _secureStorage.read(key: _securityEventsKey);
      if (eventsJson == null) return [];

      final List<dynamic> decoded = jsonDecode(eventsJson);
      return decoded
          .map((item) => SecurityEvent.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// Clear security events
  Future<void> clearSecurityEvents() async {
    await _secureStorage.delete(key: _securityEventsKey);
  }
}

/// Security event
class SecurityEvent {
  final String type;
  final String description;
  final DateTime timestamp;
  final Map<String, dynamic>? metadata;
  final SecurityLevel level;

  SecurityEvent({
    required this.type,
    required this.description,
    DateTime? timestamp,
    this.metadata,
    this.level = SecurityLevel.info,
  }) : timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'description': description,
      'timestamp': timestamp.toIso8601String(),
      'metadata': metadata,
      'level': level.toString(),
    };
  }

  factory SecurityEvent.fromJson(Map<String, dynamic> json) {
    return SecurityEvent(
      type: json['type'] as String,
      description: json['description'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      metadata: json['metadata'] as Map<String, dynamic>?,
      level: SecurityLevel.values.firstWhere(
        (e) => e.toString() == json['level'],
        orElse: () => SecurityLevel.info,
      ),
    );
  }
}

/// Security event level
enum SecurityLevel { info, warning, critical }
