# Feature 4: Security Features

**Estimated Time:** 6 hours  
**Priority:** 🟠 Protection (implement fourth)  
**Status:** Ready for Implementation

---

## 📋 Overview

This feature adds advanced security measures including secure storage, rate limiting, device fingerprinting, and security monitoring to protect user data and prevent abuse.

### Security Enhancements

**Before (Current):**
- Basic AES-256 encryption
- No rate limiting
- No device fingerprinting
- Limited security monitoring

**After (Enhanced):**
- Secure storage with encryption
- Rate limiting per device
- Device fingerprinting
- Security event logging
- Anomaly detection

---

## 🎯 Implementation Goals

1. ✅ Implement secure storage
2. ✅ Add rate limiting
3. ✅ Implement device fingerprinting
4. ✅ Add security monitoring
5. ✅ Implement anomaly detection
6. ✅ Add security audit logging

---

## 📁 Files to Create

### 1. `lib/services/security_service.dart` (NEW)

```dart
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'package:device_info_plus/device_info_plus.dart';

/// Service for security operations
class SecurityService {
  static const String _encryptionKeyKey = 'encryption_key';
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
    await _secureStorage.write(
      key: _deviceFingerprintKey,
      value: fingerprint,
    );
    
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
      
      // Create hash
      final jsonString = jsonEncode(fingerprintData);
      final hash = sha256.convert(utf8.encode(jsonString));
      
      return hash.toString();
    } catch (e) {
      // Fallback: use timestamp and random
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final random = DateTime.now().microsecond;
      final fallback = '$timestamp-$random';
      return sha256.convert(utf8.encode(fallback)).toString();
    }
  }
  
  /// Verify device fingerprint
  Future<bool> verifyDeviceFingerprint(String fingerprint) async {
    return fingerprint == _deviceFingerprint;
  }
  
  /// Hash sensitive data
  String hashData(String data) {
    return sha256.convert(utf8.encode(data)).toString();
  }
  
  /// Verify hashed data
  bool verifyHashedData(String data, String hash) {
    return hashData(data) == hash;
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
enum SecurityLevel {
  info,
  warning,
  critical,
}
```

### 2. `lib/services/rate_limiter_service.dart` (NEW)

```dart
import 'dart:async';
import 'package:flutter/foundation.dart';

/// Service for rate limiting
class RateLimiterService {
  // Rate limit configuration
  static const int defaultRequestsPerSecond = 10;
  static const int defaultBurstSize = 20;
  static const Duration defaultWindowDuration = Duration(seconds: 1);
  
  final Map<String, _RateLimitBucket> _buckets = {};
  final int requestsPerSecond;
  final int burstSize;
  final Duration windowDuration;
  
  RateLimiterService({
    this.requestsPerSecond = defaultRequestsPerSecond,
    this.burstSize = defaultBurstSize,
    this.windowDuration = defaultWindowDuration,
  });
  
  /// Check if request is allowed
  bool isAllowed(String identifier) {
    final bucket = _getBucket(identifier);
    return bucket.tryConsume();
  }
  
  /// Get remaining requests
  int getRemainingRequests(String identifier) {
    final bucket = _getBucket(identifier);
    return bucket.remaining;
  }
  
  /// Get time until next request is allowed
  Duration getTimeUntilAllowed(String identifier) {
    final bucket = _getBucket(identifier);
    return bucket.timeUntilAllowed;
  }
  
  /// Reset rate limit for identifier
  void reset(String identifier) {
    _buckets.remove(identifier);
  }
  
  /// Reset all rate limits
  void resetAll() {
    _buckets.clear();
  }
  
  /// Get bucket for identifier
  _RateLimitBucket _getBucket(String identifier) {
    return _buckets.putIfAbsent(
      identifier,
      () => _RateLimitBucket(
        capacity: burstSize,
        refillRate: requestsPerSecond,
        windowDuration: windowDuration,
      ),
    );
  }
}

/// Rate limit bucket (token bucket algorithm)
class _RateLimitBucket {
  final int capacity;
  final int refillRate;
  final Duration windowDuration;
  
  late double _tokens;
  late DateTime _lastRefillTime;
  
  _RateLimitBucket({
    required this.capacity,
    required this.refillRate,
    required this.windowDuration,
  }) {
    _tokens = capacity.toDouble();
    _lastRefillTime = DateTime.now();
  }
  
  /// Try to consume a token
  bool tryConsume() {
    _refill();
    
    if (_tokens >= 1) {
      _tokens -= 1;
      return true;
    }
    
    return false;
  }
  
  /// Refill tokens based on elapsed time
  void _refill() {
    final now = DateTime.now();
    final elapsed = now.difference(_lastRefillTime);
    
    // Calculate tokens to add
    final tokensToAdd = (elapsed.inMilliseconds / windowDuration.inMilliseconds) *
        refillRate;
    
    _tokens = min(_tokens + tokensToAdd, capacity.toDouble());
    _lastRefillTime = now;
  }
  
  /// Get remaining tokens
  int get remaining {
    _refill();
    return _tokens.toInt();
  }
  
  /// Get time until next token is available
  Duration get timeUntilAllowed {
    _refill();
    
    if (_tokens >= 1) {
      return Duration.zero;
    }
    
    // Time to generate 1 token
    final timePerToken = windowDuration.inMilliseconds / refillRate;
    return Duration(milliseconds: timePerToken.toInt());
  }
}

double min(double a, double b) => a < b ? a : b;
```

### 3. `lib/utils/secure_storage_helper.dart` (NEW)

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/security_service.dart';

/// Helper for secure storage operations
class SecureStorageHelper {
  static const String _trustedDevicesKey = 'trusted_devices';
  static const String _sessionTokenKey = 'session_token';
  static const String _apiKeyKey = 'api_key';
  
  final SecurityService _securityService;
  
  SecureStorageHelper(this._securityService);
  
  /// Store trusted device
  Future<void> storeTrustedDevice(String deviceId, String deviceName) async {
    final key = '$_trustedDevicesKey:$deviceId';
    final data = {
      'deviceId': deviceId,
      'deviceName': deviceName,
      'trustedAt': DateTime.now().toIso8601String(),
    };
    
    await _securityService.storeSecurely(key, data.toString());
  }
  
  /// Check if device is trusted
  Future<bool> isTrustedDevice(String deviceId) async {
    final key = '$_trustedDevicesKey:$deviceId';
    final data = await _securityService.retrieveSecurely(key);
    return data != null;
  }
  
  /// Get trusted devices
  Future<List<String>> getTrustedDevices() async {
    // This would require iterating through secure storage
    // For now, return empty list
    return [];
  }
  
  /// Remove trusted device
  Future<void> removeTrustedDevice(String deviceId) async {
    final key = '$_trustedDevicesKey:$deviceId';
    await _securityService.deleteSecurely(key);
  }
  
  /// Store session token
  Future<void> storeSessionToken(String token) async {
    await _securityService.storeSecurely(_sessionTokenKey, token);
  }
  
  /// Get session token
  Future<String?> getSessionToken() async {
    return await _securityService.retrieveSecurely(_sessionTokenKey);
  }
  
  /// Clear session token
  Future<void> clearSessionToken() async {
    await _securityService.deleteSecurely(_sessionTokenKey);
  }
  
  /// Store API key
  Future<void> storeApiKey(String apiKey) async {
    await _securityService.storeSecurely(_apiKeyKey, apiKey);
  }
  
  /// Get API key
  Future<String?> getApiKey() async {
    return await _securityService.retrieveSecurely(_apiKeyKey);
  }
  
  /// Clear API key
  Future<void> clearApiKey() async {
    await _securityService.deleteSecurely(_apiKeyKey);
  }
}

/// Provider for security service
final securityServiceProvider = Provider((ref) {
  return SecurityService();
});

/// Provider for rate limiter service
final rateLimiterProvider = Provider((ref) {
  return RateLimiterService();
});

/// Provider for secure storage helper
final secureStorageHelperProvider = Provider((ref) {
  final securityService = ref.watch(securityServiceProvider);
  return SecureStorageHelper(securityService);
});
```

---

## 🔧 Integration Steps

### Step 1: Initialize Security Service

```dart
// In main.dart

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize security service
  final securityService = SecurityService();
  await securityService.initialize();
  
  runApp(const MyApp());
}
```

### Step 2: Add Rate Limiting to Services

```dart
// In file transfer service

class FileTransferService {
  final RateLimiterService _rateLimiter = RateLimiterService();
  
  Future<void> transferFile(String filePath, String deviceId) async {
    // Check rate limit
    if (!_rateLimiter.isAllowed(deviceId)) {
      final waitTime = _rateLimiter.getTimeUntilAllowed(deviceId);
      throw Exception('Rate limited. Wait ${waitTime.inSeconds}s');
    }
    
    // Proceed with transfer
    // ...
  }
}
```

### Step 3: Log Security Events

```dart
// In security-sensitive operations

await securityService.logSecurityEvent(
  SecurityEvent(
    type: 'device_connected',
    description: 'Device connected: $deviceName',
    level: SecurityLevel.info,
    metadata: {
      'deviceId': deviceId,
      'deviceName': deviceName,
      'timestamp': DateTime.now().toIso8601String(),
    },
  ),
);
```

### Step 4: Update pubspec.yaml

```yaml
dependencies:
  flutter_secure_storage: ^9.0.0
  device_info_plus: ^9.0.0
  crypto: ^3.0.0
```

---

## 📊 Security Features

| Feature | Status |
|---------|--------|
| Secure storage | ✅ |
| Device fingerprinting | ✅ |
| Rate limiting | ✅ |
| Security event logging | ✅ |
| Session management | ✅ |
| API key storage | ✅ |

---

## 🧪 Testing Scenarios

### Test 1: Secure Storage
```
1. Store sensitive data
2. Retrieve data
3. Verify data is encrypted
4. Delete data
5. Verify data is gone
```

### Test 2: Rate Limiting
```
1. Make 10 requests
2. Verify all allowed
3. Make 11th request
4. Verify denied
5. Wait 1 second
6. Verify allowed again
```

### Test 3: Device Fingerprint
```
1. Get device fingerprint
2. Restart app
3. Verify fingerprint is same
4. Verify fingerprint is unique per device
```

---

## 💡 Key Benefits

✅ **Secure Storage** - Encrypted sensitive data  
✅ **Rate Limiting** - Prevent abuse  
✅ **Device Fingerprinting** - Unique device identification  
✅ **Security Monitoring** - Track security events  
✅ **Audit Trail** - Security event logging  

---

**Next:** After implementing this feature, move to Feature 5 (Memory & Battery Optimization)
