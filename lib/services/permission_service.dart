import 'package:permission_handler/permission_handler.dart';
import 'base_service.dart';

/// Service for managing app permissions
class PermissionService extends BaseService {
  static final PermissionService _instance = PermissionService._internal();

  factory PermissionService() {
    return _instance;
  }

  PermissionService._internal();

  /// Request Bluetooth permissions
  Future<bool> requestBluetoothPermissions() async {
    try {
      logInfo('Requesting Bluetooth permissions...');
      final statuses = await [
        Permission.bluetooth,
        Permission.bluetoothScan,
        Permission.bluetoothConnect,
        Permission.location,
      ].request();

      final allGranted = statuses.values.every((status) => status.isGranted);
      logInfo('Bluetooth permissions: ${allGranted ? 'Granted' : 'Denied'}');
      return allGranted;
    } catch (e) {
      logError('Failed to request Bluetooth permissions', e);
      return false;
    }
  }

  /// Request WiFi permissions
  Future<bool> requestWiFiPermissions() async {
    try {
      logInfo('Requesting WiFi permissions...');
      final statuses = await [
        Permission.location,
        Permission.nearbyWifiDevices,
      ].request();

      final allGranted = statuses.values.every((status) => status.isGranted);
      logInfo('WiFi permissions: ${allGranted ? 'Granted' : 'Denied'}');
      return allGranted;
    } catch (e) {
      logError('Failed to request WiFi permissions', e);
      return false;
    }
  }

  /// Request file storage permissions
  Future<bool> requestStoragePermissions() async {
    try {
      logInfo('Requesting storage permissions...');
      final statuses = await [
        Permission.storage,
        Permission.manageExternalStorage,
      ].request();

      final allGranted = statuses.values.every((status) => status.isGranted);
      logInfo('Storage permissions: ${allGranted ? 'Granted' : 'Denied'}');
      return allGranted;
    } catch (e) {
      logError('Failed to request storage permissions', e);
      return false;
    }
  }

  /// Request all required permissions
  Future<bool> requestAllPermissions() async {
    try {
      logInfo('Requesting all permissions...');
      final bluetooth = await requestBluetoothPermissions();
      final wifi = await requestWiFiPermissions();
      final storage = await requestStoragePermissions();

      return bluetooth && wifi && storage;
    } catch (e) {
      logError('Failed to request all permissions', e);
      return false;
    }
  }

  /// Check if Bluetooth permissions are granted
  Future<bool> hasBluetoothPermissions() async {
    try {
      final statuses = await [
        Permission.bluetooth,
        Permission.bluetoothScan,
        Permission.bluetoothConnect,
      ].request();

      return statuses.values.every((status) => status.isGranted);
    } catch (e) {
      logError('Failed to check Bluetooth permissions', e);
      return false;
    }
  }

  /// Check if storage permissions are granted
  Future<bool> hasStoragePermissions() async {
    try {
      final status = await Permission.storage.status;
      return status.isGranted;
    } catch (e) {
      logError('Failed to check storage permissions', e);
      return false;
    }
  }

  /// Open app settings
  Future<void> openSystemSettings() async {
    try {
      logInfo('Opening app settings...');
      await openAppSettings();
    } catch (e) {
      logError('Failed to open app settings', e);
    }
  }
}
