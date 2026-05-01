import 'dart:async';
import 'dart:io';
import 'package:battery_plus/battery_plus.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';

/// Service for managing device resources
class ResourceManagerService {
  // Memory limits
  static const int maxMemoryMB = 200;
  static const int warningMemoryMB = 150;
  static const int criticalMemoryMB = 180;

  // Battery thresholds
  static const int lowBatteryThreshold = 20; // %
  static const int criticalBatteryThreshold = 10; // %

  final Battery _battery = Battery();
  final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();

  late int _totalDeviceMemory;
  late bool _isLowEndDevice;

  Timer? _monitoringTimer;
  // Real memory usage tracked via ProcessInfo.currentRss
  int _currentMemoryUsage = 0;
  int _currentBatteryLevel = 100;
  bool _isLowBattery = false;
  bool _isCriticalBattery = false;

  bool _isInitialized = false;

  // Callbacks
  final List<VoidCallback> _onLowMemoryCallbacks = [];
  final List<VoidCallback> _onLowBatteryCallbacks = [];
  final List<VoidCallback> _onCriticalBatteryCallbacks = [];

  /// Initialize resource manager
  Future<void> initialize() async {
    if (_isInitialized) return;

    await _detectDeviceCapabilities();
    await _updateResourceStatus();
    _startMonitoring();

    _isInitialized = true;
  }

  /// Get current memory usage
  int get currentMemoryUsage => _currentMemoryUsage;

  /// Get current battery level
  int get currentBatteryLevel => _currentBatteryLevel;

  /// Check if low battery
  bool get isLowBattery => _isLowBattery;

  /// Check if critical battery
  bool get isCriticalBattery => _isCriticalBattery;

  /// Check if low-end device
  bool get isLowEndDevice => _isLowEndDevice;

  /// Get memory usage percentage
  double get memoryUsagePercent {
    if (_totalDeviceMemory == 0) return 0;
    return (_currentMemoryUsage / _totalDeviceMemory) * 100;
  }

  /// Register low memory callback
  void onLowMemory(VoidCallback callback) {
    _onLowMemoryCallbacks.add(callback);
  }

  /// Register low battery callback
  void onLowBattery(VoidCallback callback) {
    _onLowBatteryCallbacks.add(callback);
  }

  /// Register critical battery callback
  void onCriticalBattery(VoidCallback callback) {
    _onCriticalBatteryCallbacks.add(callback);
  }

  /// Detect device capabilities
  Future<void> _detectDeviceCapabilities() async {
    try {
      if (Platform.isAndroid) {
        final info = await _deviceInfo.androidInfo;
        // Use ProcessInfo.maxRss as a proxy for available RAM
        // Android devices typically have 2–16 GB; we cap at a safe estimate
        final rssMax = ProcessInfo.maxRss ~/ (1024 * 1024); // MB
        // If maxRss is unrealistically small (cold start), fall back to
        // a heuristic based on the SDK version
        _totalDeviceMemory = rssMax > 512
            ? rssMax
            : (info.version.sdkInt >= 31 ? 6144 : 3072);
      } else {
        // Windows / Linux / macOS — use maxRss
        final rssMax = ProcessInfo.maxRss ~/ (1024 * 1024);
        _totalDeviceMemory = rssMax > 512 ? rssMax : 4096;
      }

      _isLowEndDevice = _totalDeviceMemory < 2048;

      debugPrint(
        'Device Memory: ${_totalDeviceMemory}MB, low-end: $_isLowEndDevice',
      );
    } catch (e) {
      debugPrint('Error detecting device capabilities: $e');
      _totalDeviceMemory = 2048;
      _isLowEndDevice = true;
    }
  }

  /// Start monitoring resources
  void _startMonitoring() {
    _monitoringTimer = Timer.periodic(const Duration(seconds: 5), (_) async {
      await _updateResourceStatus();
    });
  }

  /// Update resource status
  Future<void> _updateResourceStatus() async {
    // Update battery level
    final batteryLevel = await _battery.batteryLevel;
    _currentBatteryLevel = batteryLevel;

    // Check battery thresholds
    final wasLowBattery = _isLowBattery;
    final wasCriticalBattery = _isCriticalBattery;

    _isCriticalBattery = batteryLevel <= criticalBatteryThreshold;
    _isLowBattery = batteryLevel <= lowBatteryThreshold;

    // Trigger callbacks
    if (_isCriticalBattery && !wasCriticalBattery) {
      _triggerCriticalBatteryCallbacks();
    } else if (_isLowBattery && !wasLowBattery) {
      _triggerLowBatteryCallbacks();
    }

    // Update memory usage (simulated)
    _updateMemoryUsage();
  }

  /// Update memory usage using ProcessInfo.currentRss (real RSS from the OS).
  /// No platform channels needed — dart:io exposes this on all platforms.
  void _updateMemoryUsage() {
    try {
      // ProcessInfo.currentRss returns bytes of resident set size
      final rssBytes = ProcessInfo.currentRss;
      _currentMemoryUsage = rssBytes ~/ (1024 * 1024); // convert to MB

      // Trigger low-memory callbacks if threshold crossed
      if (_currentMemoryUsage >= criticalMemoryMB) {
        for (final cb in _onLowMemoryCallbacks) {
          cb();
        }
      }

      debugPrint('Memory RSS: ${_currentMemoryUsage}MB');
    } catch (e) {
      // ProcessInfo may not be available on all platforms — fail silently
      debugPrint('Memory monitoring unavailable: $e');
    }
  }

  /// Trigger low battery callbacks
  void _triggerLowBatteryCallbacks() {
    for (final callback in _onLowBatteryCallbacks) {
      callback();
    }
  }

  /// Trigger critical battery callbacks
  void _triggerCriticalBatteryCallbacks() {
    for (final callback in _onCriticalBatteryCallbacks) {
      callback();
    }
  }

  /// Get recommended transfer settings based on resources
  TransferSettings getRecommendedTransferSettings() {
    if (_isCriticalBattery) {
      return TransferSettings(
        chunkSize: 64 * 1024, // 64 KB
        parallelChunks: 1,
        compressionEnabled: true,
        throttleSpeed: 512 * 1024, // 512 KB/s
      );
    } else if (_isLowBattery) {
      return TransferSettings(
        chunkSize: 128 * 1024, // 128 KB
        parallelChunks: 2,
        compressionEnabled: true,
        throttleSpeed: 1024 * 1024, // 1 MB/s
      );
    } else if (_isLowEndDevice) {
      return TransferSettings(
        chunkSize: 256 * 1024, // 256 KB
        parallelChunks: 2,
        compressionEnabled: false,
        throttleSpeed: 2 * 1024 * 1024, // 2 MB/s
      );
    } else {
      return TransferSettings(
        chunkSize: 512 * 1024, // 512 KB
        parallelChunks: 4,
        compressionEnabled: false,
        throttleSpeed: 10 * 1024 * 1024, // 10 MB/s
      );
    }
  }

  /// Clear cache and temporary files created by Flux
  Future<void> clearCache() async {
    try {
      int deletedFiles = 0;
      int freedBytes = 0;

      // Clear system temp directory entries created by Flux
      final tempDir = Directory.systemTemp;
      if (await tempDir.exists()) {
        await for (final entity in tempDir.list()) {
          if (entity is Directory && entity.path.contains('flux_share_')) {
            try {
              final stat = await entity.stat();
              freedBytes += stat.size;
              await entity.delete(recursive: true);
              deletedFiles++;
            } catch (_) {}
          }
        }
      }

      // On Android, also clear the FluxShare download staging area
      if (Platform.isAndroid) {
        final stagingDir = Directory('/data/local/tmp/flux');
        if (await stagingDir.exists()) {
          await for (final entity in stagingDir.list()) {
            try {
              final stat = await entity.stat();
              freedBytes += stat.size;
              await entity.delete(recursive: true);
              deletedFiles++;
            } catch (_) {}
          }
        }
      }

      debugPrint(
        'Cache cleared: $deletedFiles files, '
        '${(freedBytes / 1024).toStringAsFixed(1)} KB freed',
      );
    } catch (e) {
      debugPrint('Error clearing cache: $e');
    }
  }

  /// Dispose resources
  void dispose() {
    _monitoringTimer?.cancel();
  }
}

/// Transfer settings based on device resources
class TransferSettings {
  final int chunkSize;
  final int parallelChunks;
  final bool compressionEnabled;
  final int throttleSpeed;

  TransferSettings({
    required this.chunkSize,
    required this.parallelChunks,
    required this.compressionEnabled,
    required this.throttleSpeed,
  });
}
