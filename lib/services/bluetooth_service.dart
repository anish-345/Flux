import 'package:flutter_blue_plus/flutter_blue_plus.dart' as fbp;
import 'package:flux/models/device.dart';
import 'base_service.dart';

/// Service for managing Bluetooth connections
class BluetoothService extends BaseService {
  static final BluetoothService _instance = BluetoothService._internal();

  factory BluetoothService() {
    return _instance;
  }

  BluetoothService._internal();

  /// Stream of discovered devices
  Stream<List<Device>> get discoveredDevicesStream {
    return fbp.FlutterBluePlus.scanResults.map((results) {
      final devices = <Device>[];
      for (final result in results) {
        devices.add(
          Device(
            id: result.device.remoteId.str,
            name: result.device.name.isNotEmpty
                ? result.device.name
                : 'Unknown',
            ipAddress: '0.0.0.0',
            port: 5000,
            type: DeviceType.mobile,
            connectionType: ConnectionType.bluetooth,
            discoveredAt: DateTime.now(),
            isConnected: false,
            isTrusted: false,
          ),
        );
      }
      return devices;
    });
  }

  /// Stream of connection state changes
  Stream<Map<String, dynamic>> get connectionStateStream {
    return Stream.empty();
  }

  /// Check if Bluetooth is available
  Future<bool> isBluetoothAvailable() async {
    try {
      final isAvailable = await fbp.FlutterBluePlus.isAvailable;
      logDebug('Bluetooth available: $isAvailable');
      return isAvailable;
    } catch (e) {
      logError('Failed to check Bluetooth availability', e);
      return false;
    }
  }

  /// Check if Bluetooth is turned on
  Future<bool> isBluetoothOn() async {
    try {
      final isOn = await fbp.FlutterBluePlus.isOn;
      logDebug('Bluetooth on: $isOn');
      return isOn;
    } catch (e) {
      logError('Failed to check Bluetooth state', e);
      return false;
    }
  }

  /// Start scanning for Bluetooth devices
  Future<void> startScan({
    Duration timeout = const Duration(seconds: 10),
  }) async {
    try {
      logInfo('Starting Bluetooth scan...');
      await fbp.FlutterBluePlus.startScan(timeout: timeout);
      logInfo('Bluetooth scan started');
    } catch (e) {
      logError('Failed to start Bluetooth scan', e);
    }
  }

  /// Stop scanning for Bluetooth devices
  Future<void> stopScan() async {
    try {
      logInfo('Stopping Bluetooth scan...');
      await fbp.FlutterBluePlus.stopScan();
      logInfo('Bluetooth scan stopped');
    } catch (e) {
      logError('Failed to stop Bluetooth scan', e);
    }
  }

  /// Start device discovery
  Future<void> startDiscovery() async {
    try {
      logInfo('Starting device discovery...');
      await startScan();
      logInfo('Device discovery started');
    } catch (e) {
      logError('Failed to start device discovery', e);
    }
  }

  /// Get stream of discovered devices (raw scan results)
  Stream<List<fbp.ScanResult>> get scanResults =>
      fbp.FlutterBluePlus.scanResults;

  /// Connect to a device by BluetoothDevice
  Future<void> connectToDevice(fbp.BluetoothDevice device) async {
    try {
      logInfo('Connecting to device: ${device.name}');
      await device.connect();
      logInfo('Connected to device: ${device.name}');
    } catch (e) {
      logError('Failed to connect to device', e);
    }
  }

  /// Connect to a device by ID (string)
  Future<void> connectToDeviceById(String deviceId) async {
    try {
      logInfo('Connecting to device: $deviceId');
      final device = fbp.BluetoothDevice(
        remoteId: fbp.DeviceIdentifier(deviceId),
      );
      await device.connect();
      logInfo('Connected to device: $deviceId');
    } catch (e) {
      logError('Failed to connect to device', e);
    }
  }

  /// Disconnect from a device by BluetoothDevice
  Future<void> disconnectFromDevice(fbp.BluetoothDevice device) async {
    try {
      logInfo('Disconnecting from device: ${device.name}');
      await device.disconnect();
      logInfo('Disconnected from device: ${device.name}');
    } catch (e) {
      logError('Failed to disconnect from device', e);
    }
  }

  /// Disconnect from a device by ID (string)
  Future<void> disconnectFromDeviceById(String deviceId) async {
    try {
      logInfo('Disconnecting from device: $deviceId');
      final device = fbp.BluetoothDevice(
        remoteId: fbp.DeviceIdentifier(deviceId),
      );
      await device.disconnect();
      logInfo('Disconnected from device: $deviceId');
    } catch (e) {
      logError('Failed to disconnect from device', e);
    }
  }

  /// Get connected devices
  Future<List<fbp.BluetoothDevice>> getConnectedDevices() async {
    try {
      final devices = await fbp.FlutterBluePlus.connectedDevices;
      logDebug('Connected devices: ${devices.length}');
      return devices;
    } catch (e) {
      logError('Failed to get connected devices', e);
      return [];
    }
  }

  /// Get device services
  Future<List<fbp.BluetoothService>> getDeviceServices(
    fbp.BluetoothDevice device,
  ) async {
    try {
      logInfo('Getting services for device: ${device.name}');
      final services = await device.discoverServices();
      logInfo('Found ${services.length} services');
      return services;
    } catch (e) {
      logError('Failed to get device services', e);
      return [];
    }
  }

  /// Listen to connection state changes
  Stream<fbp.BluetoothConnectionState> onConnectionStateChanged(
    fbp.BluetoothDevice device,
  ) {
    return device.connectionState;
  }

  /// Listen to device state changes
  Stream<fbp.BluetoothConnectionState> onDeviceStateChanged(
    fbp.BluetoothDevice device,
  ) {
    return device.connectionState;
  }
}
