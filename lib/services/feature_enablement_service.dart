import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'base_service.dart';

/// Enum for feature status
enum FeatureStatus { available, unavailable, disabled, permissionDenied, error }

/// Enum for feature types
enum FeatureType { bluetooth, wifi, hotspot, location }

/// Result of feature enablement attempt
class FeatureEnablementResult {
  final FeatureType feature;
  final FeatureStatus status;
  final String? message;
  final bool wasEnabled;
  final bool isNowEnabled;

  FeatureEnablementResult({
    required this.feature,
    required this.status,
    this.message,
    required this.wasEnabled,
    required this.isNowEnabled,
  });

  bool get success => isNowEnabled;
  bool get requiresUserAction => status == FeatureStatus.disabled;
}

/// Service for managing feature enablement with automatic activation
class FeatureEnablementService extends BaseService {
  static final FeatureEnablementService _instance =
      FeatureEnablementService._internal();

  factory FeatureEnablementService() {
    return _instance;
  }

  FeatureEnablementService._internal();

  final Connectivity _connectivity = Connectivity();

  /// Check and enable Bluetooth with proper error handling
  Future<FeatureEnablementResult> ensureBluetoothEnabled() async {
    try {
      logInfo('Checking Bluetooth status...');

      // Check if Bluetooth is supported
      if (!await FlutterBluePlus.isSupported) {
        logError('Bluetooth not supported on this device', null);
        return FeatureEnablementResult(
          feature: FeatureType.bluetooth,
          status: FeatureStatus.unavailable,
          message: 'Bluetooth is not supported on this device',
          wasEnabled: false,
          isNowEnabled: false,
        );
      }

      // Get current state
      final currentState = FlutterBluePlus.adapterStateNow;
      final wasEnabled = currentState == BluetoothAdapterState.on;

      logDebug('Current Bluetooth state: $currentState');

      // Check permissions first
      final permissionStatus = await _checkBluetoothPermissions();
      if (permissionStatus != PermissionStatus.granted) {
        logWarning('Bluetooth permissions not granted');
        return FeatureEnablementResult(
          feature: FeatureType.bluetooth,
          status: FeatureStatus.permissionDenied,
          message: 'Bluetooth permissions are required',
          wasEnabled: wasEnabled,
          isNowEnabled: false,
        );
      }

      // If already enabled, return success
      if (wasEnabled) {
        logInfo('Bluetooth is already enabled');
        return FeatureEnablementResult(
          feature: FeatureType.bluetooth,
          status: FeatureStatus.available,
          message: 'Bluetooth is already enabled',
          wasEnabled: true,
          isNowEnabled: true,
        );
      }

      // Try to enable Bluetooth (Android only)
      if (!kIsWeb && Platform.isAndroid) {
        try {
          logInfo('Attempting to enable Bluetooth...');
          await FlutterBluePlus.turnOn();

          // Wait for Bluetooth to turn on
          await Future.delayed(const Duration(milliseconds: 500));

          // Verify it's actually on
          final newState = FlutterBluePlus.adapterStateNow;
          final isNowEnabled = newState == BluetoothAdapterState.on;

          if (isNowEnabled) {
            logInfo('✅ Bluetooth enabled successfully');
            return FeatureEnablementResult(
              feature: FeatureType.bluetooth,
              status: FeatureStatus.available,
              message: 'Bluetooth enabled successfully',
              wasEnabled: false,
              isNowEnabled: true,
            );
          } else {
            logWarning('Bluetooth is still disabled after enablement attempt');
            return FeatureEnablementResult(
              feature: FeatureType.bluetooth,
              status: FeatureStatus.disabled,
              message: 'Bluetooth is disabled. Please enable it manually.',
              wasEnabled: false,
              isNowEnabled: false,
            );
          }
        } catch (e) {
          logError('Failed to enable Bluetooth', e);
          return FeatureEnablementResult(
            feature: FeatureType.bluetooth,
            status: FeatureStatus.error,
            message: 'Error enabling Bluetooth: $e',
            wasEnabled: false,
            isNowEnabled: false,
          );
        }
      } else if (Platform.isIOS || Platform.isMacOS) {
        // iOS/macOS: User must enable manually
        logInfo('iOS/macOS: User must enable Bluetooth manually');
        return FeatureEnablementResult(
          feature: FeatureType.bluetooth,
          status: FeatureStatus.disabled,
          message: 'Please enable Bluetooth in Settings',
          wasEnabled: false,
          isNowEnabled: false,
        );
      }

      return FeatureEnablementResult(
        feature: FeatureType.bluetooth,
        status: FeatureStatus.error,
        message: 'Unknown platform',
        wasEnabled: false,
        isNowEnabled: false,
      );
    } catch (e) {
      logError('Unexpected error checking Bluetooth', e);
      return FeatureEnablementResult(
        feature: FeatureType.bluetooth,
        status: FeatureStatus.error,
        message: 'Unexpected error: $e',
        wasEnabled: false,
        isNowEnabled: false,
      );
    }
  }

  /// Check and enable WiFi with proper error handling
  Future<FeatureEnablementResult> ensureWiFiEnabled() async {
    try {
      logInfo('Checking WiFi status...');

      final List<ConnectivityResult> connectivity =
          await _connectivity.checkConnectivity() as List<ConnectivityResult>;
      // connectivity is a List<ConnectivityResult>
      final wasEnabled = connectivity.contains(ConnectivityResult.wifi);

      logDebug('Current WiFi status: $connectivity');

      if (wasEnabled) {
        logInfo('WiFi is already enabled');
        return FeatureEnablementResult(
          feature: FeatureType.wifi,
          status: FeatureStatus.available,
          message: 'WiFi is already enabled',
          wasEnabled: true,
          isNowEnabled: true,
        );
      }

      // Check location permission (required for WiFi scanning on Android)
      final locationPermission = await Permission.location.request();
      if (!locationPermission.isGranted) {
        logWarning('Location permission required for WiFi scanning');
        return FeatureEnablementResult(
          feature: FeatureType.wifi,
          status: FeatureStatus.permissionDenied,
          message: 'Location permission is required for WiFi',
          wasEnabled: false,
          isNowEnabled: false,
        );
      }

      // WiFi cannot be enabled programmatically on most platforms
      // User must enable manually
      logInfo('WiFi is disabled. User must enable manually.');
      return FeatureEnablementResult(
        feature: FeatureType.wifi,
        status: FeatureStatus.disabled,
        message: 'Please enable WiFi in Settings',
        wasEnabled: false,
        isNowEnabled: false,
      );
    } catch (e) {
      logError('Error checking WiFi status', e);
      return FeatureEnablementResult(
        feature: FeatureType.wifi,
        status: FeatureStatus.error,
        message: 'Error checking WiFi: $e',
        wasEnabled: false,
        isNowEnabled: false,
      );
    }
  }

  /// Check and enable location services
  Future<FeatureEnablementResult> ensureLocationEnabled() async {
    try {
      logInfo('Checking location permission...');

      final status = await Permission.location.request();

      if (status.isGranted) {
        logInfo('Location permission granted');
        return FeatureEnablementResult(
          feature: FeatureType.location,
          status: FeatureStatus.available,
          message: 'Location permission granted',
          wasEnabled: true,
          isNowEnabled: true,
        );
      } else if (status.isDenied) {
        logWarning('Location permission denied');
        return FeatureEnablementResult(
          feature: FeatureType.location,
          status: FeatureStatus.permissionDenied,
          message: 'Location permission is required',
          wasEnabled: false,
          isNowEnabled: false,
        );
      } else if (status.isPermanentlyDenied) {
        logWarning('Location permission permanently denied');
        return FeatureEnablementResult(
          feature: FeatureType.location,
          status: FeatureStatus.permissionDenied,
          message: 'Location permission permanently denied. Open app settings.',
          wasEnabled: false,
          isNowEnabled: false,
        );
      }

      return FeatureEnablementResult(
        feature: FeatureType.location,
        status: FeatureStatus.error,
        message: 'Unknown permission status',
        wasEnabled: false,
        isNowEnabled: false,
      );
    } catch (e) {
      logError('Error checking location permission', e);
      return FeatureEnablementResult(
        feature: FeatureType.location,
        status: FeatureStatus.error,
        message: 'Error checking location: $e',
        wasEnabled: false,
        isNowEnabled: false,
      );
    }
  }

  /// Check all required features and return status
  Future<Map<FeatureType, FeatureEnablementResult>> checkAllFeatures() async {
    try {
      logInfo('Checking all required features...');

      final results = <FeatureType, FeatureEnablementResult>{};

      results[FeatureType.bluetooth] = await ensureBluetoothEnabled();
      results[FeatureType.wifi] = await ensureWiFiEnabled();
      results[FeatureType.location] = await ensureLocationEnabled();

      logInfo('Feature check complete');
      return results;
    } catch (e) {
      logError('Error checking features', e);
      rethrow;
    }
  }

  /// Get user-friendly error message
  String getErrorMessage(FeatureEnablementResult result) {
    switch (result.status) {
      case FeatureStatus.available:
        return '${result.feature.name} is ready to use';
      case FeatureStatus.unavailable:
        return '${result.feature.name} is not supported on this device';
      case FeatureStatus.disabled:
        return 'Please enable ${result.feature.name} in Settings';
      case FeatureStatus.permissionDenied:
        return '${result.feature.name} permission is required';
      case FeatureStatus.error:
        return 'Error with ${result.feature.name}: ${result.message}';
    }
  }

  /// Private helper to check Bluetooth permissions
  Future<PermissionStatus> _checkBluetoothPermissions() async {
    if (Platform.isAndroid) {
      // Android 12+ requires BLUETOOTH_SCAN and BLUETOOTH_CONNECT
      final scanStatus = await Permission.bluetoothScan.request();
      final connectStatus = await Permission.bluetoothConnect.request();

      if (scanStatus.isGranted && connectStatus.isGranted) {
        return PermissionStatus.granted;
      }
      return PermissionStatus.denied;
    } else if (Platform.isIOS) {
      // iOS handles Bluetooth permissions automatically
      return PermissionStatus.granted;
    }
    return PermissionStatus.granted;
  }
}
