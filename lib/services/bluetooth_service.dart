import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter_blue_plus/flutter_blue_plus.dart' as fbp;
import 'package:flux/models/device.dart';
import 'package:flux/utils/logger.dart';
import 'base_service.dart';

/// Service for managing Bluetooth connections and data transfer
class BluetoothService extends BaseService {
  static final BluetoothService _instance = BluetoothService._internal();

  factory BluetoothService() {
    return _instance;
  }

  BluetoothService._internal();

  final _connectionStateController =
      StreamController<Map<String, dynamic>>.broadcast();
  
  // Flux service UUID for identification
  static const String _fluxServiceUuid = '6e400001-b5a3-f393-e0a9-e50e24dcca9e';
  static const String _fluxCharacteristicUuid = '6e400002-b5a3-f393-e0a9-e50e24dcca9e';
  
  // Connected device and characteristic for data transfer
  fbp.BluetoothDevice? _connectedDevice;
  fbp.BluetoothCharacteristic? _writeCharacteristic;
  fbp.BluetoothCharacteristic? _readCharacteristic;
  
  // Scan state management to prevent conflicts
  bool _isScanning = false;

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
    // Bluetooth is only supported on mobile platforms for now
    if (!(Platform.isAndroid || Platform.isIOS)) {
      return false;
    }
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
    if (!(Platform.isAndroid || Platform.isIOS)) {
      return false;
    }
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
      // Check if already scanning to prevent conflicts
      if (_isScanning) {
        logInfo('Bluetooth scan already in progress, skipping...');
        return;
      }

      // Check if Bluetooth is enabled first
      final adapterState = await fbp.FlutterBluePlus.adapterState.first;
      if (adapterState != fbp.BluetoothAdapterState.on) {
        logError('Bluetooth is not enabled', null);
        throw Exception('Bluetooth is not enabled');
      }

      _isScanning = true;
      logInfo('Starting Bluetooth scan...');
      await fbp.FlutterBluePlus.startScan(timeout: timeout);
      logInfo('Bluetooth scan started');
    } catch (e) {
      _isScanning = false;
      logError('Failed to start Bluetooth scan', e);
      rethrow;
    }
  }

  /// Stop scanning for Bluetooth devices
  Future<void> stopScan() async {
    try {
      logInfo('Stopping Bluetooth scan...');
      await fbp.FlutterBluePlus.stopScan();
      _isScanning = false;
      logInfo('Bluetooth scan stopped');
    } catch (e) {
      _isScanning = false;
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

  /// Connect to Flux device and discover services
  Future<bool> connectToFluxDevice(fbp.BluetoothDevice device) async {
    try {
      AppLogger.info('Connecting to Flux device: ${device.platformName}');
      await device.connect();
      
      // Find Flux service
      final services = await device.discoverServices();
      for (final service in services) {
        if (service.uuid.toString() == _fluxServiceUuid) {
          // Find characteristics
          for (final characteristic in service.characteristics) {
            if (characteristic.uuid.toString() == _fluxCharacteristicUuid) {
              // Check if characteristic is readable or writable
              final properties = characteristic.properties;
              if (properties.read) {
                _readCharacteristic = characteristic;
                AppLogger.info('Found read characteristic');
              }
              if (properties.write || properties.writeWithoutResponse) {
                _writeCharacteristic = characteristic;
                AppLogger.info('Found write characteristic');
              }
            }
          }
        }
      }
      
      _connectedDevice = device;
      AppLogger.info('Connected to Flux device successfully');
      return true;
    } catch (e) {
      AppLogger.error('Failed to connect to Flux device', e);
      return false;
    }
  }

  /// Send data via Bluetooth
  Future<bool> sendData(String data) async {
    try {
      if (_writeCharacteristic == null) {
        AppLogger.error('Write characteristic not available');
        return false;
      }
      
      final bytes = utf8.encode(data);
      await _writeCharacteristic!.write(bytes, withoutResponse: false);
      AppLogger.info('Data sent via Bluetooth: ${data.length} bytes');
      return true;
    } catch (e) {
      AppLogger.error('Failed to send data via Bluetooth', e);
      return false;
    }
  }

  /// Send network info via Bluetooth for same-network detection
  Future<bool> sendNetworkInfo({
    required String ipAddress,
    required int port,
    required String ssid,
  }) async {
    final networkInfo = {
      'type': 'NETWORK_INFO',
      'ipAddress': ipAddress,
      'port': port,
      'ssid': ssid,
      'timestamp': DateTime.now().toIso8601String(),
    };
    return sendData(jsonEncode(networkInfo));
  }

  /// Receive network info from connected device
  Stream<Map<String, dynamic>>? getIncomingDataStream() {
    if (_readCharacteristic == null) return null;

    return _readCharacteristic!.onValueReceived.map((event) {
      try {
        final data = utf8.decode(event);
        return jsonDecode(data) as Map<String, dynamic>;
      } catch (e) {
        AppLogger.error('Failed to parse incoming data', e);
        return {};
      }
    });
  }

  /// Check if peer device is on the same network by exchanging network info via Bluetooth
  /// Returns true if both devices are on the same WiFi network, false otherwise
  Future<bool> checkSameNetworkViaBluetooth({
    required String mySsid,
    required String myIpAddress,
    int myPort = 5000,
    Duration timeout = const Duration(seconds: 5),
  }) async {
    try {
      if (_connectedDevice == null || _writeCharacteristic == null) {
        AppLogger.warning('No Bluetooth connection available for network check');
        return false;
      }

      AppLogger.info('Checking same network via Bluetooth...');

      // Send our network info to peer
      final myNetworkInfo = {
        'type': 'NETWORK_INFO_REQUEST',
        'ssid': mySsid,
        'ipAddress': myIpAddress,
        'port': myPort,
        'timestamp': DateTime.now().toIso8601String(),
      };

      final success = await sendData(jsonEncode(myNetworkInfo));
      if (!success) {
        AppLogger.error('Failed to send network info request via Bluetooth');
        return false;
      }

      // Wait for peer's response with timeout
      final completer = Completer<Map<String, dynamic>>();
      StreamSubscription? subscription;

      subscription = _readCharacteristic?.onValueReceived.listen(
        (event) {
          try {
            final data = utf8.decode(event);
            final jsonData = jsonDecode(data) as Map<String, dynamic>;
            if (jsonData['type'] == 'NETWORK_INFO_RESPONSE') {
              if (!completer.isCompleted) {
                completer.complete(jsonData);
              }
            }
          } catch (e) {
            AppLogger.error('Failed to parse network info response', e);
          }
        },
        onError: (e) {
          if (!completer.isCompleted) {
            completer.completeError(e);
          }
        },
      );

      try {
        final response = await completer.future.timeout(timeout);
        await subscription?.cancel();

        final peerSsid = response['ssid'] as String?;
      
        // Check if both devices have valid SSIDs and they match
        final onSameNetwork = mySsid.isNotEmpty &&
            peerSsid != null &&
            peerSsid.isNotEmpty &&
            mySsid == peerSsid;

        AppLogger.info(
          'Same network check via Bluetooth: mySSID=$mySsid, peerSSID=$peerSsid, result=$onSameNetwork',
        );

        return onSameNetwork;
      } on TimeoutException {
        await subscription?.cancel();
        AppLogger.warning('Bluetooth network check timed out');
        return false;
      }
    } catch (e) {
      AppLogger.error('Failed to check same network via Bluetooth', e);
      return false;
    }
  }

  /// Listen for network info requests and respond with our network info
  /// Call this when acting as receiver to enable same-network detection
  Future<void> startNetworkInfoListener({
    required String mySsid,
    required String myIpAddress,
    int myPort = 5000,
  }) async {
    try {
      if (_readCharacteristic == null) {
        AppLogger.warning('No read characteristic available for network info listener');
        return;
      }

      AppLogger.info('Starting network info listener via Bluetooth...');

      _readCharacteristic!.onValueReceived.listen((event) async {
        try {
          final data = utf8.decode(event);
          final jsonData = jsonDecode(data) as Map<String, dynamic>;

          if (jsonData['type'] == 'NETWORK_INFO_REQUEST') {
            AppLogger.info('Received network info request via Bluetooth');

            // Send our network info as response
            final response = {
              'type': 'NETWORK_INFO_RESPONSE',
              'ssid': mySsid,
              'ipAddress': myIpAddress,
              'port': myPort,
              'timestamp': DateTime.now().toIso8601String(),
            };

            await sendData(jsonEncode(response));
            AppLogger.info('Sent network info response via Bluetooth');
          }
        } catch (e) {
          AppLogger.error('Error in network info listener', e);
        }
      });
    } catch (e) {
      AppLogger.error('Failed to start network info listener', e);
    }
  }

  /// Disconnect from current device
  Future<void> disconnect() async {
    if (_connectedDevice != null) {
      await _connectedDevice!.disconnect();
      _connectedDevice = null;
      _writeCharacteristic = null;
      _readCharacteristic = null;
      AppLogger.info('Disconnected from Bluetooth device');
    }
  }

  /// Check if connected to a Flux device
  bool get isConnected => _connectedDevice != null;
}
