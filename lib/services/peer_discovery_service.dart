import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flux/models/device.dart';
import 'package:flux/services/network_manager_service.dart';
import 'package:flux/services/bluetooth_service.dart';
import 'package:flux/services/encryption_service.dart';
import 'package:flux/services/hotspot_service.dart';
import 'package:flux/services/connectivity_service.dart';
import 'package:flux/utils/logger.dart';

/// Provider for peer discovery service
final peerDiscoveryServiceProvider = Provider<PeerDiscoveryService>((ref) {
  return PeerDiscoveryService();
});

/// Connection info shared via QR code or manual entry
class ConnectionInfo {
  final String code;
  final String ipAddress;
  final int port;
  final String deviceName;
  final String ssid;
  final DateTime timestamp;
  final String? sessionKey;

  ConnectionInfo({
    required this.code,
    required this.ipAddress,
    required this.port,
    required this.deviceName,
    required this.ssid,
    required this.timestamp,
    this.sessionKey,
  });

  Map<String, dynamic> toJson() => {
    'code': code,
    'ipAddress': ipAddress,
    'port': port,
    'deviceName': deviceName,
    'ssid': ssid,
    'timestamp': timestamp.toIso8601String(),
  };

  factory ConnectionInfo.fromJson(Map<String, dynamic> json) => ConnectionInfo(
    code: json['code'] as String,
    ipAddress: json['ipAddress'] as String,
    port: json['port'] as int,
    deviceName: json['deviceName'] as String,
    ssid: json['ssid'] as String? ?? '',
    timestamp: DateTime.parse(json['timestamp'] as String),
  );

  /// Convert to encrypted JSON string for QR code
  String toQrString() {
    final encryptionService = EncryptionService();
    final sessionKey = this.sessionKey ?? encryptionService.generateSessionKey();
    
    final data = jsonEncode({
      'code': code,
      'ipAddress': ipAddress,
      'port': port,
      'deviceName': deviceName,
      'ssid': ssid,
      'timestamp': timestamp.toIso8601String(),
    });
    
    // Encrypt the data
    final encrypted = encryptionService.encryptText(data, sessionKey);
    
    // Return session key + encrypted data
    return '$sessionKey|$encrypted';
  }

  /// Parse from encrypted JSON string
  static ConnectionInfo? fromQrString(String qrString) {
    try {
      final parts = qrString.split('|');
      if (parts.length != 2) return null;
      
      final sessionKey = parts[0];
      final encryptedData = parts[1];
      
      final encryptionService = EncryptionService();
      final decrypted = encryptionService.decryptText(encryptedData, sessionKey);
      
      final json = jsonDecode(decrypted) as Map<String, dynamic>;
      return ConnectionInfo(
        code: json['code'] as String,
        ipAddress: json['ipAddress'] as String,
        port: json['port'] as int,
        deviceName: json['deviceName'] as String,
        ssid: json['ssid'] as String? ?? '',
        timestamp: DateTime.parse(json['timestamp'] as String),
        sessionKey: sessionKey,
      );
    } catch (e) {
      return null;
    }
  }
}

/// Service for peer discovery and connection
/// Handles connection code generation, QR code data, and peer connection
class PeerDiscoveryService {
  final NetworkManagerService _networkManager = NetworkManagerService();
  final HotspotService _hotspotService = HotspotService();
  final ConnectivityService _connectivityService = ConnectivityService();

  ConnectionInfo? _myConnectionInfo;
  final Map<String, Device> _discoveredPeers = {};
  final StreamController<Device> _peerDiscoveredController = StreamController<Device>.broadcast();
  final StreamController<Device> _peerConnectedController = StreamController<Device>.broadcast();

  PeerDiscoveryService();

  /// Stream of newly discovered peers
  Stream<Device> get onPeerDiscovered => _peerDiscoveredController.stream;

  /// Stream of connected peers
  Stream<Device> get onPeerConnected => _peerConnectedController.stream;

  /// Get my connection info to share via QR code
  ConnectionInfo? get myConnectionInfo => _myConnectionInfo;

  /// Generate connection info for sharing
  Future<ConnectionInfo> generateConnectionInfo(String deviceName, int port) async {
    try {
      final code = _generateConnectionCode();
      final ipAddress = await _networkManager.getLocalIpAddress();
      final ssid = await _connectivityService.getWiFiSSID();
      
      if (ipAddress == null) {
        throw Exception('Unable to get local IP address');
      }
      
      // Generate session key for encryption
      final encryptionService = EncryptionService();
      final sessionKey = encryptionService.generateSessionKey();
      
      _myConnectionInfo = ConnectionInfo(
        code: code,
        ipAddress: ipAddress,
        port: port,
        deviceName: deviceName,
        ssid: ssid ?? '',
        timestamp: DateTime.now(),
        sessionKey: sessionKey,
      );
      
      AppLogger.info('Generated connection info: ${_myConnectionInfo!.toQrString()}');
      return _myConnectionInfo!;
    } catch (e) {
      AppLogger.error('Failed to generate connection info', e);
      rethrow;
    }
  }

  /// Parse connection info from QR code or manual entry
  ConnectionInfo? parseConnectionInfo(String qrString) {
    try {
      final json = jsonDecode(qrString) as Map<String, dynamic>;
      final info = ConnectionInfo.fromJson(json);
      
      // Check if connection info is recent (within 5 minutes)
      final age = DateTime.now().difference(info.timestamp);
      if (age.inMinutes > 5) {
        AppLogger.warning('Connection info is too old: ${age.inMinutes} minutes');
        return null;
      }
      
      AppLogger.info('Parsed connection info from: ${info.deviceName}');
      return info;
    } catch (e) {
      AppLogger.error('Failed to parse connection info', e);
      return null;
    }
  }

  /// Connect to peer using connection info
  /// Uses Bluetooth for same-network detection, then determines connection method
  /// If not on same network, sender will enable hotspot automatically
  Future<Device?> connectToPeer(ConnectionInfo peerInfo, {BluetoothService? bluetoothService}) async {
    try {
      AppLogger.info('Connecting to peer: ${peerInfo.deviceName}');

      // Get our network info
      final mySsid = await _connectivityService.getWiFiSSID();
      final myIpAddress = await _networkManager.getLocalIpAddress();
      final myPort = 5000; // Default port

      bool onSameNetwork = false;

      // Step 1: Try Bluetooth-based same-network detection
      if (bluetoothService != null) {
        final isBluetoothConnected = bluetoothService.isConnected;
        if (isBluetoothConnected) {
          AppLogger.info('Checking same network via Bluetooth...');
          onSameNetwork = await bluetoothService.checkSameNetworkViaBluetooth(
            mySsid: mySsid ?? '',
            myIpAddress: myIpAddress ?? '',
            myPort: myPort,
          );
          AppLogger.info('Bluetooth same-network check result: $onSameNetwork');
        } else {
          AppLogger.warning('Bluetooth not connected, falling back to SSID comparison');
        }
      }

      // Step 2: Fallback to SSID comparison if Bluetooth check failed or wasn't available
      if (!onSameNetwork && (bluetoothService == null || !bluetoothService.isConnected)) {
        onSameNetwork = mySsid != null &&
            mySsid.isNotEmpty &&
            peerInfo.ssid.isNotEmpty &&
            mySsid == peerInfo.ssid;
        AppLogger.info('SSID-based same-network check result: $onSameNetwork');
      }

      if (onSameNetwork) {
        // Direct WiFi connection (encrypted)
        AppLogger.info('Devices on same network - using direct WiFi connection');
        return await _connectViaWifi(peerInfo);
      } else {
        // Not on same network - enable hotspot and connect
        AppLogger.info('Devices not on same network - enabling hotspot for connection');
        return await _connectViaHotspot(peerInfo);
      }
    } catch (e) {
      AppLogger.error('Failed to connect to peer', e);
      return null;
    }
  }
  
  /// Connect via direct WiFi (same network)
  Future<Device?> _connectViaWifi(ConnectionInfo peerInfo) async {
    try {
      // Try TCP connection to verify peer is reachable
      final socket = await Socket.connect(peerInfo.ipAddress, peerInfo.port, timeout: const Duration(seconds: 5));
      await socket.close();
      
      // Create device object
      final device = Device(
        id: peerInfo.code,
        name: peerInfo.deviceName,
        ipAddress: peerInfo.ipAddress,
        port: peerInfo.port,
        type: DeviceType.mobile,
        connectionType: ConnectionType.wifi,
        discoveredAt: DateTime.now(),
        isConnected: true,
      );
      
      // Add to discovered peers
      _discoveredPeers[device.id] = device;
      _peerDiscoveredController.add(device);
      
      AppLogger.info('Successfully connected via WiFi: ${device.name}');
      return device;
    } catch (e) {
      AppLogger.error('Failed to connect via WiFi', e);
      return null;
    }
  }
  
  /// Connect via hotspot (different networks)
  Future<Device?> _connectViaHotspot(ConnectionInfo peerInfo) async {
    try {
      // Enable hotspot on sender side
      final hotspotResult = await _hotspotService.enableHotspot();
      if (!hotspotResult) {
        throw Exception('Failed to enable hotspot');
      }
      
      // Wait for hotspot to be ready
      await Future.delayed(const Duration(seconds: 3));
      
      // Get hotspot IP
      final hotspotIp = await _networkManager.getLocalIpAddress();
      if (hotspotIp == null) {
        throw Exception('Unable to get hotspot IP');
      }
      
      AppLogger.info('Hotspot enabled on IP: $hotspotIp');
      
      // Try TCP connection via hotspot
      final socket = await Socket.connect(peerInfo.ipAddress, peerInfo.port, timeout: const Duration(seconds: 10));
      await socket.close();
      
      // Create device object
      final device = Device(
        id: peerInfo.code,
        name: peerInfo.deviceName,
        ipAddress: peerInfo.ipAddress,
        port: peerInfo.port,
        type: DeviceType.mobile,
        connectionType: ConnectionType.wifi,
        discoveredAt: DateTime.now(),
        isConnected: true,
      );
      
      // Add to discovered peers
      _discoveredPeers[device.id] = device;
      _peerDiscoveredController.add(device);
      
      AppLogger.info('Successfully connected via hotspot: ${device.name}');
      return device;
    } catch (e) {
      AppLogger.error('Failed to connect via hotspot', e);
      return null;
    }
  }

  /// Discover peers via Bluetooth (replaces UDP broadcast)
  Future<List<Device>> discoverPeers() async {
    try {
      AppLogger.info('Starting Bluetooth peer discovery...');
      
      final bluetoothService = BluetoothService();
      final isAvailable = await bluetoothService.isBluetoothAvailable();
      final isOn = await bluetoothService.isBluetoothOn();
      
      if (!isAvailable || !isOn) {
        AppLogger.warning('Bluetooth not available or not enabled');
        return [];
      }
      
      // Start Bluetooth scan
      await bluetoothService.startScan(timeout: const Duration(seconds: 10));
      
      final discoveredPeers = <Device>[];
      
      // Listen for scan results
      final subscription = bluetoothService.scanResults.listen((results) {
        for (final result in results) {
          if (result.device.platformName.contains('Flux')) {
            final device = Device(
              id: result.device.remoteId.str,
              name: result.device.platformName.isNotEmpty
                  ? result.device.platformName
                  : 'Flux Device',
              ipAddress: '0.0.0.0',
              port: 0,
              type: DeviceType.mobile,
              connectionType: ConnectionType.bluetooth,
              discoveredAt: DateTime.now(),
              isConnected: false,
            );
            
            if (!discoveredPeers.any((d) => d.id == device.id)) {
              discoveredPeers.add(device);
              _discoveredPeers[device.id] = device;
              _peerDiscoveredController.add(device);
              AppLogger.info('Discovered Flux peer via Bluetooth: ${device.name}');
            }
          }
        }
      });
      
      // Wait for scan to complete
      await Future.delayed(const Duration(seconds: 10));
      await bluetoothService.stopScan();
      await subscription.cancel();
      
      AppLogger.info('Bluetooth discovery complete: found ${discoveredPeers.length} peers');
      return discoveredPeers;
    } catch (e) {
      AppLogger.error('Bluetooth peer discovery failed', e);
      return [];
    }
  }

  /// Get list of discovered peers
  List<Device> getDiscoveredPeers() {
    return _discoveredPeers.values.toList();
  }

  /// Remove a peer from discovered list
  void removePeer(String peerId) {
    _discoveredPeers.remove(peerId);
  }

  /// Check if on same network as peer
  Future<bool> isOnSameNetwork(ConnectionInfo peerInfo) async {
    final mySsid = await _connectivityService.getWiFiSSID();
    return mySsid != null && 
           mySsid.isNotEmpty && 
           peerInfo.ssid.isNotEmpty && 
           mySsid == peerInfo.ssid;
  }

  /// Clear all discovered peers
  void clearPeers() {
    _discoveredPeers.clear();
  }

  /// Generate a 6-digit connection code
  String _generateConnectionCode() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final code = timestamp.toString().substring(timestamp.toString().length - 6);
    return code;
  }

  /// Validate a 6-digit connection code
  bool isValidCode(String code) {
    return code.length == 6 && int.tryParse(code) != null;
  }

  void dispose() {
    _peerDiscoveredController.close();
    _peerConnectedController.close();
  }
}
