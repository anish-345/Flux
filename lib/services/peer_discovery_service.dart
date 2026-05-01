import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flux/models/device.dart';
import 'package:flux/services/base_service.dart';
import 'package:flux/services/network_manager_service.dart';
import 'package:flux/services/bluetooth_service.dart';
import 'package:flux/services/encryption_service.dart';
import 'package:flux/services/hotspot_service.dart';
import 'package:flux/services/connectivity_service.dart';
import 'package:flux/src/rust/api/mdns.dart' as rust_mdns;
import 'package:flux/utils/logger.dart';
import 'package:flux/services/wifi_credential_service.dart';
import 'package:wifi_iot/wifi_iot.dart';

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
  final String? hotspotSsid;
  final String? hotspotPassword;
  final String? hotspotIp;

  ConnectionInfo({
    required this.code,
    required this.ipAddress,
    required this.port,
    required this.deviceName,
    required this.ssid,
    required this.timestamp,
    this.sessionKey,
    this.hotspotSsid,
    this.hotspotPassword,
    this.hotspotIp,
  });

  Map<String, dynamic> toJson() => {
    'code': code,
    'ipAddress': ipAddress,
    'port': port,
    'deviceName': deviceName,
    'ssid': ssid,
    'timestamp': timestamp.toIso8601String(),
    'sessionKey': sessionKey,
    'hotspotSsid': hotspotSsid,
    'hotspotPassword': hotspotPassword,
    'hotspotIp': hotspotIp,
  };

  factory ConnectionInfo.fromJson(Map<String, dynamic> json) => ConnectionInfo(
    code: json['code'] as String,
    ipAddress: json['ipAddress'] as String,
    port: json['port'] as int,
    deviceName: json['deviceName'] as String,
    ssid: json['ssid'] as String? ?? '',
    timestamp: DateTime.parse(json['timestamp'] as String),
    sessionKey: json['sessionKey'] as String?,
    hotspotSsid: json['hotspotSsid'] as String?,
    hotspotPassword: json['hotspotPassword'] as String?,
    hotspotIp: json['hotspotIp'] as String?,
  );

  /// Convert to JSON string for QR code (no session key - exchanged during connection)
  String toQrString() {
    final data = jsonEncode({
      'code': code,
      'ipAddress': ipAddress,
      'port': port,
      'deviceName': deviceName,
      'ssid': ssid,
      'timestamp': timestamp.toIso8601String(),
      'hotspotSsid': hotspotSsid,
      'hotspotPassword': hotspotPassword,
      'hotspotIp': hotspotIp,
    });

    // Return plain JSON - session key will be exchanged during connection
    return data;
  }

  /// Parse from JSON string (no session key in QR)
  static ConnectionInfo? fromQrString(String qrString) {
    try {
      final json = jsonDecode(qrString) as Map<String, dynamic>;
      return ConnectionInfo(
        code: json['code'] as String,
        ipAddress: json['ipAddress'] as String,
        port: json['port'] as int,
        deviceName: json['deviceName'] as String,
        ssid: json['ssid'] as String? ?? '',
        timestamp: DateTime.parse(json['timestamp'] as String),
        sessionKey: null, // Session key will be generated during connection
        hotspotSsid: json['hotspotSsid'] as String?,
        hotspotPassword: json['hotspotPassword'] as String?,
        hotspotIp: json['hotspotIp'] as String?,
      );
    } catch (e) {
      return null;
    }
  }
}

/// Service for peer discovery and connection
/// Handles connection code generation, QR code data, and peer connection
class PeerDiscoveryService extends BaseService {
  static final PeerDiscoveryService _instance = PeerDiscoveryService._internal();

  factory PeerDiscoveryService() => _instance;
  PeerDiscoveryService._internal();

  final NetworkManagerService _networkManager = NetworkManagerService();
  final HotspotService _hotspotService = HotspotService();
  final ConnectivityService _connectivityService = ConnectivityService();

  final Map<String, Device> _discoveredPeers = {};
  final StreamController<Device> _peerDiscoveredController = StreamController<Device>.broadcast();
  final StreamController<Device> _peerDisconnectedController = StreamController<Device>.broadcast();
  final StreamController<Device> _peerConnectedController = StreamController<Device>.broadcast();
  ConnectionInfo? _myConnectionInfo;
  StreamSubscription? _networkSubscription;

  /// Stream of newly discovered peers
  Stream<Device> get onPeerDiscovered => _peerDiscoveredController.stream;

  /// Stream of connected peers
  Stream<Device> get onPeerConnected => _peerConnectedController.stream;

  /// Stream of disconnected peers
  Stream<Device> get onPeerDisconnected => _peerDisconnectedController.stream;

  /// Get my connection info to share via QR code
  ConnectionInfo? get myConnectionInfo => _myConnectionInfo;

  @override
  Future<void> initialize() async {
    await super.initialize();
    _startNetworkMonitoring();
  }

  @override
  Future<void> dispose() async {
    await _networkSubscription?.cancel();
    await _peerDiscoveredController.close();
    await _peerConnectedController.close();
    await _peerDisconnectedController.close();
    await super.dispose();
  }

  /// Start monitoring network connectivity changes
  void _startNetworkMonitoring() {
    _networkSubscription = _connectivityService.connectivityStream.listen((result) {
      AppLogger.info('🌐 Network connectivity changed: $result');
      _handleNetworkChange(result);
    });
  }

  /// Handle network connectivity changes
  void _handleNetworkChange(ConnectivityResult result) {
    if (result == ConnectivityResult.none) {
      AppLogger.warning('📴 Network disconnected - clearing all peer connections');
      _disconnectAllPeers();
    } else if (result == ConnectivityResult.mobile) {
      AppLogger.warning('📱 Switched to mobile data - will check connectivity on user action');
      // Don't automatically check on mobile data changes to save battery
    } else if (result == ConnectivityResult.wifi) {
      AppLogger.info('📶 Connected to WiFi - will check connectivity on user action');
      // Don't automatically check on WiFi changes to save battery
    }
  }

  /// Disconnect all peers when network is lost
  void _disconnectAllPeers() {
    for (final device in _discoveredPeers.values) {
      if (device.isConnected) {
        final disconnectedDevice = Device(
          id: device.id,
          name: device.name,
          ipAddress: device.ipAddress,
          port: device.port,
          type: device.type,
          connectionType: device.connectionType,
          discoveredAt: device.discoveredAt,
          isConnected: false,
        );
        
        _discoveredPeers[device.id] = disconnectedDevice;
        _peerDisconnectedController.add(disconnectedDevice);
        AppLogger.info('🔌 Disconnected peer: ${device.name}');
      }
    }
  }

  /// Check if peers are still reachable (battery-optimized).
  /// Call this only on user-initiated actions (e.g. refresh, send button tap).
  Future<void> checkPeerConnectivity({bool isUserInitiated = false}) async {
    // Only perform connectivity checks if user-initiated or app is in foreground
    if (!isUserInitiated) {
      // Skip background checks to save battery
      AppLogger.info('🔋 Skipping background connectivity check to save battery');
      return;
    }

    AppLogger.info('🔍 Performing user-initiated connectivity check');
    for (final device in _discoveredPeers.values.toList()) {
      if (device.isConnected) {
        final isReachable = await _isPeerReachable(device);
        if (!isReachable) {
          AppLogger.warning('❌ Peer ${device.name} no longer reachable');
          
          final disconnectedDevice = Device(
            id: device.id,
            name: device.name,
            ipAddress: device.ipAddress,
            port: device.port,
            type: device.type,
            connectionType: device.connectionType,
            discoveredAt: device.discoveredAt,
            isConnected: false,
          );
          
          _discoveredPeers[device.id] = disconnectedDevice;
          _peerDisconnectedController.add(disconnectedDevice);
        }
      }
    }
  }

  /// Check if a peer is reachable via TCP
  Future<bool> _isPeerReachable(Device device) async {
    try {
      final socket = await Socket.connect(
        device.ipAddress,
        device.port,
        timeout: const Duration(seconds: 2),
      );
      await socket.close();
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Generate connection info for sharing via QR code.
  ///
  /// Strategy:
  /// - If already on WiFi → embed the WiFi SSID + password in the QR so the
  ///   other device can join the same network automatically. No hotspot needed.
  /// - If NOT on WiFi → enable a hotspot and embed its credentials instead.
  Future<ConnectionInfo> generateConnectionInfo(
    String deviceName,
    int port, {
    bool forceHotspot = false, // default false — prefer WiFi sharing
  }) async {
    try {
      final code = _generateConnectionCode();
      final wifiIp = await _networkManager.getLocalIpAddress();
      final wifiSsid = await _connectivityService.getWiFiSSID();

      // Generate session key for encryption
      final encryptionService = EncryptionService();
      final sessionKey = await encryptionService.generateSessionKey();

      String? hotspotSsid;
      String? hotspotPassword;
      String? hotspotIp;

      final bool onWifi = wifiSsid != null && wifiSsid.isNotEmpty;

      if (!onWifi || forceHotspot) {
        // Not on WiFi — enable hotspot so the other device can connect
        AppLogger.info('Not on WiFi — enabling hotspot for P2P connection');
        final hotspotResult = await _hotspotService.enableHotspot();

        if (hotspotResult) {
          AppLogger.info('Waiting for Hotspot DHCP initialization...');
          for (int i = 0; i < 6; i++) {
            await Future.delayed(const Duration(seconds: 1));
            final testIp = await _networkManager.getLocalIpAddress();
            if (testIp != null && testIp != '0.0.0.0' && testIp != wifiIp) {
              hotspotIp = testIp;
              break;
            }
          }

          if (hotspotIp == null) {
            AppLogger.warning('Hotspot IP not ready, using current IP');
            hotspotIp = await _networkManager.getLocalIpAddress();
          }

          hotspotSsid = await _hotspotService.getHotspotSSID();
          hotspotPassword = await _hotspotService.getHotspotPassword();
          if (hotspotIp != null) {
            AppLogger.info('Hotspot ready with IP: $hotspotIp');
          }
        }
      } else {
        // Already on WiFi — try to get the WiFi password so the other device
        // can join the same network by scanning the QR code.
        // This avoids enabling a hotspot unnecessarily.
        AppLogger.info('On WiFi "$wifiSsid" — embedding credentials in QR');
        try {
          final wifiCreds = WifiCredentialService();
          final password = await wifiCreds.getCurrentWifiPassword();
          if (password != null) {
            // Embed as hotspot fields so the receiver's existing logic works
            hotspotSsid = wifiSsid;
            hotspotPassword = password;
            hotspotIp = wifiIp;
            AppLogger.info('WiFi password retrieved — embedded in QR');
          } else {
            AppLogger.info(
              'WiFi password not retrievable on this platform — '
              'receiver must join "$wifiSsid" manually',
            );
          }
        } catch (e) {
          AppLogger.warning('Could not get WiFi password: $e');
        }
      }

      _myConnectionInfo = ConnectionInfo(
        code: code,
        ipAddress: wifiIp ?? hotspotIp ?? '0.0.0.0',
        port: port,
        deviceName: deviceName,
        ssid: wifiSsid ?? '',
        timestamp: DateTime.now(),
        sessionKey: sessionKey,
        hotspotSsid: hotspotSsid,
        hotspotPassword: hotspotPassword,
        hotspotIp: hotspotIp,
      );

      AppLogger.info(
        'Generated connection info: ${_myConnectionInfo!.toQrString()}',
      );
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
        AppLogger.warning(
          'Connection info is too old: ${age.inMinutes} minutes',
        );
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
  Future<Device?> connectToPeer(
    ConnectionInfo peerInfo, {
    BluetoothService? bluetoothService,
  }) async {
    try {
      AppLogger.info('Connecting to peer: ${peerInfo.deviceName}');

      // Get our network info
      final mySsid = await _connectivityService.getWiFiSSID();
      final myIpAddress = await _networkManager.getLocalIpAddress();
      // Use actual server port from connection info, fallback to 5000 if not available
      final myPort = _myConnectionInfo?.port ?? 5000;

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
          AppLogger.warning(
            'Bluetooth not connected, falling back to SSID comparison',
          );
        }
      }

      // Step 2: Fallback to SSID comparison if Bluetooth check failed or wasn't available
      if (!onSameNetwork &&
          (bluetoothService == null || !bluetoothService.isConnected)) {
        onSameNetwork =
            mySsid != null &&
            mySsid.isNotEmpty &&
            peerInfo.ssid.isNotEmpty &&
            mySsid == peerInfo.ssid;
        AppLogger.info('SSID-based same-network check result: $onSameNetwork');
      }

      if (onSameNetwork) {
        // Direct WiFi connection (encrypted)
        AppLogger.info(
          'Devices on same network - using direct WiFi connection',
        );
        return await _connectViaWifi(peerInfo);
      } else {
        // Not on same network - try hotspot connection
        AppLogger.info(
          'Devices not on same network - trying hotspot connection',
        );
        
        // First try direct connection in case both devices have internet connectivity
        // This handles cases where both devices are on mobile data but can reach each other
        final directResult = await _connectViaWifi(peerInfo);
        if (directResult != null) {
          AppLogger.info('Direct connection succeeded despite different networks');
          return directResult;
        }
        
        // Fallback to hotspot connection
        AppLogger.info('Direct connection failed, trying hotspot connection');
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
      // Only use the actual server port from QR code - fallbacks hit wrong servers
      final portsToTry = [peerInfo.port];

      Socket? socket;
      int connectedPort = peerInfo.port;

      for (final port in portsToTry) {
        try {
          AppLogger.info('Trying to connect to ${peerInfo.ipAddress}:$port');
          socket = await Socket.connect(
            peerInfo.ipAddress,
            port,
            timeout: const Duration(seconds: 3),
          );
          connectedPort = port;
          break;
        } catch (e) {
          AppLogger.info('Connection to port $port failed: $e');
          continue;
        }
      }

      if (socket == null) {
        // Even if we can't establish TCP connection, we can still create the device
        // The user can try to transfer files and it will show a proper error if server is not running
        AppLogger.warning('Could not establish TCP connection to any port, but will create device anyway');
      } else {
        // Send connection handshake to notify host
        try {
          final handshake = {
            'type': 'connection_handshake',
            'deviceCode': peerInfo.code,
            'deviceName': peerInfo.deviceName,
            'timestamp': DateTime.now().toIso8601String(),
          };
          AppLogger.info('Sending handshake: ${jsonEncode(handshake)}');
          socket.write('${jsonEncode(handshake)}\n');
          await socket.flush();
          
          // Wait for response with timeout and robust byte pattern matching
          String? response;
          try {
            final responseBytes = <int>[];
            final handshakeOkBytes = utf8.encode('HANDSHAKE_OK');
            
            await for (final data in socket.timeout(const Duration(seconds: 5)).map((event) => event)) {
              responseBytes.addAll(data);
              
              // Search for HANDSHAKE_OK byte pattern to avoid decoding issues
              for (int i = 0; i <= responseBytes.length - handshakeOkBytes.length; i++) {
                bool found = true;
                for (int j = 0; j < handshakeOkBytes.length; j++) {
                  if (responseBytes[i + j] != handshakeOkBytes[j]) {
                    found = false;
                    break;
                  }
                }
                if (found) {
                  response = utf8.decode(responseBytes);
                  break;
                }
              }
              
              if (response != null) break;
            }
          } on TimeoutException catch (e) {
            AppLogger.warning('Handshake response timeout: $e');
          } catch (e) {
            AppLogger.warning('Failed to read handshake response: $e');
          }
          
          if (response != null && response.contains('HANDSHAKE_OK')) {
            AppLogger.info('Host acknowledged handshake successfully');
          } else {
            AppLogger.warning('Host did not acknowledge handshake');
          }
        } catch (e) {
          AppLogger.warning('Failed to send handshake: $e');
        } finally {
          await socket.close();
        }
        AppLogger.info('Successfully connected to ${peerInfo.ipAddress}:$connectedPort');
      }

      // Create device object - don't mark as connected just from socket test
      // Real connection state will be determined by actual connectivity
      final device = Device(
        id: peerInfo.code,
        name: peerInfo.deviceName,
        ipAddress: peerInfo.ipAddress,
        port: connectedPort,
        type: DeviceType.mobile,
        connectionType: ConnectionType.wifi,
        discoveredAt: DateTime.now(),
        isConnected: false, // Start as disconnected, will be updated by actual connectivity
      );

      // Check if device is actually reachable and mark as connected if so
      if (socket != null) {
        final isReachable = await _isPeerReachable(device);
        if (isReachable) {
          final connectedDevice = Device(
            id: device.id,
            name: device.name,
            ipAddress: device.ipAddress,
            port: device.port,
            type: device.type,
            connectionType: device.connectionType,
            discoveredAt: device.discoveredAt,
            isConnected: true,
          );
          
          _discoveredPeers[device.id] = connectedDevice;
          _peerConnectedController.add(connectedDevice);
          AppLogger.info('✅ Device is reachable and marked as connected: ${device.name}');
          return connectedDevice; // Return the connected device
        } else {
          AppLogger.warning('⚠️ Device not reachable after connection test: ${device.name}');
          // Don't add to discovered peers if not reachable
          return null;
        }
      } else {
        // Don't add to discovered peers if no socket connection
        return null;
      }
    } catch (e) {
      AppLogger.error('Failed to connect via WiFi', e);
      return null;
    }
  }

  /// Connect via hotspot (different networks)
  /// Client connects to host's hotspot using credentials from QR code
  Future<Device?> _connectViaHotspot(ConnectionInfo peerInfo) async {
    try {
      // Check if QR code contains hotspot credentials
      if (peerInfo.hotspotSsid == null || peerInfo.hotspotPassword == null) {
        AppLogger.warning('QR code does not contain hotspot credentials');
        return null;
      }

      AppLogger.info('Connecting to host hotspot: ${peerInfo.hotspotSsid}');

      // Connect to host's hotspot using wifi_iot
      final connected = await WiFiForIoTPlugin.connect(
        peerInfo.hotspotSsid!,
        password: peerInfo.hotspotPassword!,
        joinOnce: true,
        security: NetworkSecurity.WPA,
      );

      if (!connected) {
        throw Exception('Failed to connect to host hotspot');
      }

      AppLogger.info('Connected to host hotspot, waiting for IP assignment...');

      String? myIp;
      for (int i = 0; i < 10; i++) {
        await Future.delayed(const Duration(seconds: 1));
        myIp = await _networkManager.getLocalIpAddress();
        if (myIp != null && myIp != '0.0.0.0' && myIp != '127.0.0.1') {
          break; // Successfully got an IP from the host's DHCP
        }
      }

      if (myIp == null || myIp == '0.0.0.0' || myIp == '127.0.0.1') {
        throw Exception('Unable to get IP address on hotspot network');
      }

      AppLogger.info('Got IP on hotspot: $myIp');

      // Try TCP connection to host using the hotspot IP from QR code (fallback to main IP if missing)
      final targetIp = peerInfo.hotspotIp ?? peerInfo.ipAddress;
      final socket = await Socket.connect(
        targetIp,
        peerInfo.port,
        timeout: const Duration(seconds: 10),
      );

      // Send connection handshake to notify host (same as WiFi path)
      try {
        final handshake = {
          'type': 'connection_handshake',
          'deviceCode': peerInfo.code,
          'deviceName': peerInfo.deviceName,
          'timestamp': DateTime.now().toIso8601String(),
        };
        AppLogger.info('Sending hotspot handshake: ${jsonEncode(handshake)}');
        socket.write('${jsonEncode(handshake)}\n');
        await socket.flush();
        
        // Wait for response with timeout
        String? response;
        try {
          final responseBytes = <int>[];
          final handshakeOkBytes = utf8.encode('HANDSHAKE_OK');
          
          await for (final data in socket.timeout(const Duration(seconds: 5)).map((event) => event)) {
            responseBytes.addAll(data);
            
            // Search for HANDSHAKE_OK byte pattern
            for (int i = 0; i <= responseBytes.length - handshakeOkBytes.length; i++) {
              bool found = true;
              for (int j = 0; j < handshakeOkBytes.length; j++) {
                if (responseBytes[i + j] != handshakeOkBytes[j]) {
                  found = false;
                  break;
                }
              }
              if (found) {
                response = utf8.decode(responseBytes);
                break;
              }
            }
            
            if (response != null) break;
          }
        } catch (e) {
          AppLogger.warning('Failed to read handshake response: $e');
        }
        
        if (response != null && response.contains('HANDSHAKE_OK')) {
          AppLogger.info('Host acknowledged hotspot handshake successfully');
        } else {
          AppLogger.warning('Host did not acknowledge hotspot handshake');
        }
      } catch (e) {
        AppLogger.warning('Failed to send hotspot handshake: $e');
      } finally {
        await socket.close();
      }

      // Create device object
      final device = Device(
        id: peerInfo.code,
        name: peerInfo.deviceName,
        ipAddress: targetIp,
        port: peerInfo.port,
        type: DeviceType.mobile,
        connectionType: ConnectionType.wifi,
        discoveredAt: DateTime.now(),
        isConnected: true,
      );

      // Add to discovered peers but don't emit discovered event
      _discoveredPeers[device.id] = device;
      _peerConnectedController.add(device);

      AppLogger.info('Successfully connected via hotspot: ${device.name}');
      return device;
    } catch (e) {
      AppLogger.error('Failed to connect via hotspot', e);
      return null;
    }
  }

  /// Discover Flux peers on the local network using mDNS (Rust backend).
  ///
  /// Scans for `_http._tcp.local.` services with `app=flux` TXT property
  /// for [timeout] duration. Returns discovered devices immediately.
  Future<List<Device>> discoverPeersViaMdns({
    Duration timeout = const Duration(seconds: 5),
  }) async {
    try {
      AppLogger.info('Starting mDNS peer discovery (${timeout.inSeconds}s)...');

      final rawPeers = await rust_mdns.discoverFluxPeers(
        timeoutMs: BigInt.from(timeout.inMilliseconds),
      );

      final devices = <Device>[];
      for (final raw in rawPeers) {
        try {
          final json = jsonDecode(raw) as Map<String, dynamic>;
          final name = json['name'] as String? ?? 'Flux Device';
          final ip = json['ip'] as String? ?? '0.0.0.0';
          final port = (json['port'] as num?)?.toInt() ?? 8080;
          final url = json['url'] as String? ?? 'http://$ip:$port';

          final device = Device(
            id: '${ip}_$port',
            name: name,
            ipAddress: ip,
            port: port,
            type: DeviceType.mobile,
            connectionType: ConnectionType.wifi,
            discoveredAt: DateTime.now(),
            isConnected: false,
            deviceModel: url, // store friendly URL for display
          );

          if (!_discoveredPeers.containsKey(device.id)) {
            _discoveredPeers[device.id] = device;
            _peerDiscoveredController.add(device);
          }
          devices.add(device);
        } catch (e) {
          AppLogger.warning('Failed to parse mDNS peer entry: $raw — $e');
        }
      }

      AppLogger.info(
        'mDNS discovery complete: found ${devices.length} Flux peers',
      );
      return devices;
    } catch (e) {
      AppLogger.error('mDNS peer discovery failed', e);
      return [];
    }
  }

  /// Discover peers via Bluetooth (replaces UDP broadcast)
  Future<List<Device>> discoverPeers() async {
    try {
      AppLogger.info('Starting Bluetooth peer discovery...');

      final bluetoothService = BluetoothService();
      final isAvailable = await bluetoothService.isBluetoothAvailable();
      final isOn = await bluetoothService.isBluetoothOn();

      if (!isAvailable) {
        AppLogger.info('Bluetooth not supported on this device');
        return [];
      }
      
      if (!isOn) {
        AppLogger.info('Bluetooth is supported but not enabled - user can enable it for better discovery');
        // Don't show warning repeatedly - this is normal behavior
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
              AppLogger.info(
                'Discovered Flux peer via Bluetooth: ${device.name}',
              );
            }
          }
        }
      });

      // Wait for scan to complete
      await Future.delayed(const Duration(seconds: 10));
      await bluetoothService.stopScan();
      await subscription.cancel();

      AppLogger.info(
        'Bluetooth discovery complete: found ${discoveredPeers.length} peers',
      );
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
    final code = timestamp.toString().substring(
      timestamp.toString().length - 6,
    );
    return code;
  }

  /// Validate a 6-digit connection code
  bool isValidCode(String code) {
    return code.length == 6 && int.tryParse(code) != null;
  }
}
