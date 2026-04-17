import 'dart:async';
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

  final _connectionStateController =
      StreamController<Map<String, dynamic>>.broadcast();

  @override
  Future<void> initialize() async {
    // Listen to all device connection states globally if supported by FBP version
    // For now, we will manually emit events on connect/disconnect calls
  }

  /// Stream of discovered devices using onScanResults (fresh results)
  Stream<List<Device>> get discoveredDevicesStream {
    return fbp.FlutterBluePlus.onScanResults.map((results) {
      final devices = <Device>[];
      for (final result in results) {
        devices.add(
          Device(
            id: result.device.remoteId.str,
            name: result.device.platformName.isNotEmpty
                ? result.device.platformName
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

  /// Stream of Bluetooth adapter state changes
  Stream<fbp.BluetoothAdapterState> get adapterStateStream {
    return fbp.FlutterBluePlus.adapterState;
  }

  /// Stream of connection state changes
  Stream<Map<String, dynamic>> get connectionStateStream {
    return _connectionStateController.stream;
  }

  /// Check if Bluetooth is available
  Future<bool> isBluetoothAvailable() async {
    try {
      final isSupported = await fbp.FlutterBluePlus.isSupported;
      logDebug('Bluetooth supported: $isSupported');
      return isSupported;
    } catch (e) {
      logError('Failed to check Bluetooth availability', e);
      return false;
    }
  }

  /// Check if Bluetooth is turned on
  Future<bool> isBluetoothOn() async {
    try {
      final adapterState = await fbp.FlutterBluePlus.adapterState.first;
      final isOn = adapterState == fbp.BluetoothAdapterState.on;
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
      // Check if Bluetooth is enabled first
      final adapterState = await fbp.FlutterBluePlus.adapterState.first;
      if (adapterState != fbp.BluetoothAdapterState.on) {
        logError('Bluetooth is not enabled', null);
        throw Exception('Bluetooth is not enabled');
      }

      logInfo('Starting Bluetooth scan...');
      await fbp.FlutterBluePlus.startScan(timeout: timeout);
      logInfo('Bluetooth scan started');
    } catch (e) {
      logError('Failed to start Bluetooth scan', e);
      rethrow;
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
      rethrow;
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
      rethrow;
    }
  }

  /// Get stream of discovered devices (raw scan results)
  Stream<List<fbp.ScanResult>> get scanResults =>
      fbp.FlutterBluePlus.onScanResults;

  /// Connect to a device by BluetoothDevice
  Future<void> connectToDevice(fbp.BluetoothDevice device) async {
    try {
      logInfo('Connecting to device: ${device.platformName}');
      await device.connect();
      logInfo('Connected to device: ${device.platformName}');
    } catch (e) {
      logError('Failed to connect to device', e);
      rethrow;
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
      _connectionStateController.add({
        'deviceId': deviceId,
        'isConnected': true,
      });
      logInfo('Connected to device: $deviceId');
    } catch (e) {
      logError('Failed to connect to device', e);
      rethrow;
    }
  }

  /// Disconnect from a device by BluetoothDevice
  Future<void> disconnectFromDevice(fbp.BluetoothDevice device) async {
    try {
      logInfo('Disconnecting from device: ${device.platformName}');
      await device.disconnect();
      logInfo('Disconnected from device: ${device.platformName}');
    } catch (e) {
      logError('Failed to disconnect from device', e);
      rethrow;
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
      _connectionStateController.add({
        'deviceId': deviceId,
        'isConnected': false,
      });
      logInfo('Disconnected from device: $deviceId');
    } catch (e) {
      logError('Failed to disconnect from device', e);
      rethrow;
    }
  }

  /// Get connected devices
  Future<List<fbp.BluetoothDevice>> getConnectedDevices() async {
    try {
      final devices = fbp.FlutterBluePlus.connectedDevices;
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
      logInfo('Getting services for device: ${device.platformName}');
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
