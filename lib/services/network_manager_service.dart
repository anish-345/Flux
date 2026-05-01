import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:flux/services/connectivity_service.dart';
import 'package:flux/services/hotspot_service.dart';
import 'package:flux/services/windows_network_service.dart';
import 'package:flux/utils/logger.dart';

/// Network connection state
enum NetworkState {
  wifiConnected,
  hotspotActive,
  hotspotConnected,
  noConnection,
  checking,
}

/// Service for managing network connectivity with WiFi/Hotspot fallback
class NetworkManagerService {
  static final NetworkManagerService _instance = NetworkManagerService._internal();
  factory NetworkManagerService() => _instance;
  NetworkManagerService._internal();

  final Connectivity _connectivity = Connectivity();
  final NetworkInfo _networkInfoService = NetworkInfo();
  final ConnectivityService _connectivityService = ConnectivityService();
  final HotspotService _hotspotService = HotspotService();
  final WindowsNetworkService _windowsNetworkService = WindowsNetworkService();

  StreamSubscription<ConnectivityResult>? _connectivitySubscription;
  final StreamController<NetworkState> _stateController = StreamController<NetworkState>.broadcast();
  final StreamController<Map<String, dynamic>> _infoController = StreamController<Map<String, dynamic>>.broadcast();

  NetworkState _currentState = NetworkState.checking;
  Map<String, dynamic> _networkInfo = {};

  /// Get current network state
  NetworkState get currentState => _currentState;

  /// Stream of network state changes
  Stream<NetworkState> get stateStream => _stateController.stream;

  /// Stream of network info updates
  Stream<Map<String, dynamic>> get infoStream => _infoController.stream;

  /// Initialize the service and start monitoring
  Future<void> initialize() async {
    AppLogger.info('Initializing NetworkManagerService');
    
    // Check initial state
    await _checkNetworkState();

    // Listen to connectivity changes
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
      (result) async {
        AppLogger.info('Connectivity changed: $result');
        await _checkNetworkState();
      },
    );
  }

  /// Dispose and cleanup
  Future<void> dispose() async {
    await _connectivitySubscription?.cancel();
    await _stateController.close();
    await _infoController.close();
  }

  /// Check Windows-specific network state
  Future<void> _checkWindowsNetworkState() async {
    try {
      // Log all adapters for debugging
      _windowsNetworkService.logNetworkAdapters();
      
      final winInfo = await _windowsNetworkService.getNetworkInfo();
      final isAvailable = winInfo['isAvailable'] as bool;
      final ipAddress = winInfo['ipAddress'] as String?;
      final wifiSSID = winInfo['wifiSSID'] as String?;
      final isWifi = winInfo['isWifi'] as bool;
      final isEthernet = winInfo['isEthernet'] as bool;
      
      if (isAvailable && ipAddress != null) {
        if (isWifi && wifiSSID != null) {
          _networkInfo = {
            'type': 'wifi',
            'ssid': wifiSSID,
            'ipAddress': ipAddress,
            'gateway': null, // Not critical for transfers
            'isConnected': true,
          };
          _currentState = NetworkState.wifiConnected;
          AppLogger.info('Windows: Connected to WiFi "$wifiSSID" at $ipAddress');
        } else if (isEthernet) {
          _networkInfo = {
            'type': 'ethernet',
            'ipAddress': ipAddress,
            'isConnected': true,
          };
          _currentState = NetworkState.wifiConnected; // Treat ethernet as connected
          AppLogger.info('Windows: Connected via Ethernet at $ipAddress');
        } else {
          // Generic network connection
          _networkInfo = {
            'type': 'network',
            'ipAddress': ipAddress,
            'isConnected': true,
          };
          _currentState = NetworkState.wifiConnected;
          AppLogger.info('Windows: Network available at $ipAddress');
        }
      } else {
        _networkInfo = {
          'type': 'none',
          'isConnected': false,
        };
        _currentState = NetworkState.noConnection;
        AppLogger.warning('Windows: No network connection');
      }
      
      _stateController.add(_currentState);
      _infoController.add(_networkInfo);
    } catch (e) {
      AppLogger.error('Windows network check failed', e);
      _networkInfo = {
        'type': 'none',
        'isConnected': false,
        'error': e.toString(),
      };
      _currentState = NetworkState.noConnection;
      _stateController.add(_currentState);
    }
  }

  /// Check current network state
  Future<void> _checkNetworkState() async {
    try {
      _currentState = NetworkState.checking;
      _stateController.add(_currentState);

      // On Windows, use native Windows network detection
      if (Platform.isWindows) {
        await _checkWindowsNetworkState();
        return;
      }

      // Check WiFi first (for non-Windows platforms)
      final wifiEnabled = await _connectivityService.isConnectedToWiFi();
      if (wifiEnabled) {
        final ssid = await _networkInfoService.getWifiName();
        final ip = await _networkInfoService.getWifiIP();
        
        // Get gateway with fallback for Windows
        String? gateway;
        try {
          gateway = await _networkInfoService.getWifiGatewayIP();
        } catch (e) {
          gateway = null;
        }
        
        _networkInfo = {
          'type': 'wifi',
          'ssid': ssid,
          'ipAddress': ip,
          'gateway': gateway,
          'isConnected': true,
        };
        
        _currentState = NetworkState.wifiConnected;
        AppLogger.info('Connected to WiFi: $ssid ($ip)');
      } else {
        // Check if we're connected to a hotspot (mobile network)
        final mobileEnabled = await _connectivityService.isConnectedToMobile();
        
        // Check if we're hosting a hotspot
        final isHotspotActive = await _hotspotService.isHotspotEnabled();
        
        if (isHotspotActive) {
          _networkInfo = {
            'type': 'hotspot_host',
            'ssid': _hotspotService.getHotspotSSID(),
            'ipAddress': await _networkInfoService.getWifiIP(),
            'isConnected': true,
          };
          _currentState = NetworkState.hotspotActive;
          AppLogger.info('Hosting hotspot: ${_networkInfo['ssid']}');
        } else if (mobileEnabled) {
          _networkInfo = {
            'type': 'mobile',
            'ipAddress': await _networkInfoService.getWifiIP(),
            'isConnected': true,
          };
          _currentState = NetworkState.noConnection;
          AppLogger.warning('Mobile data only - may not support local transfers');
        } else {
          _networkInfo = {
            'type': 'none',
            'isConnected': false,
          };
          _currentState = NetworkState.noConnection;
          AppLogger.warning('No network connection');
        }
      }

      _stateController.add(_currentState);
      _infoController.add(_networkInfo);
    } catch (e) {
      AppLogger.error('Failed to check network state', e);
      _currentState = NetworkState.noConnection;
      _stateController.add(_currentState);
    }
  }

  /// Ensure we have a network connection (WiFi or Hotspot)
  Future<Map<String, dynamic>> ensureNetworkConnection() async {
    // Check current state
    await _checkNetworkState();

    // If already on WiFi, we're good
    if (_currentState == NetworkState.wifiConnected) {
      return {
        'success': true,
        'method': 'wifi',
        'info': _networkInfo,
      };
    }

    // If hosting hotspot, we're good
    if (_currentState == NetworkState.hotspotActive) {
      return {
        'success': true,
        'method': 'hotspot_host',
        'info': _networkInfo,
      };
    }

    // Try to enable hotspot as fallback
    if (Platform.isAndroid) {
      try {
        final hotspotResult = await _hotspotService.enableHotspot();
        if (hotspotResult) {
          await _checkNetworkState();
          return {
            'success': true,
            'method': 'hotspot_enabled',
            'info': _networkInfo,
          };
        }
      } catch (e) {
        AppLogger.error('Failed to enable hotspot', e);
      }
    }

    return {
      'success': false,
      'method': 'none',
      'error': 'No WiFi connection and hotspot could not be enabled',
      'info': _networkInfo,
    };
  }

  /// Get recommended action for user
  Map<String, dynamic> getRecommendedAction() {
    switch (_currentState) {
      case NetworkState.wifiConnected:
        return {
          'action': 'none',
          'message': 'Connected to WiFi network',
          'canTransfer': true,
        };
      
      case NetworkState.hotspotActive:
        return {
          'action': 'none',
          'message': 'Hosting hotspot - other devices can connect',
          'canTransfer': true,
          'hotspotInfo': _networkInfo,
        };
      
      case NetworkState.hotspotConnected:
        return {
          'action': 'none',
          'message': 'Connected to device hotspot',
          'canTransfer': true,
        };
      
      case NetworkState.noConnection:
        if (Platform.isAndroid) {
          return {
            'action': 'enable_hotspot',
            'message': 'No WiFi connection. Enable hotspot to share files.',
            'canTransfer': false,
            'buttonText': 'Enable Hotspot',
          };
        } else if (Platform.isWindows) {
          return {
            'action': 'connect_wifi',
            'message': 'Please connect to a WiFi network or mobile hotspot to share files.',
            'canTransfer': false,
            'buttonText': 'Open WiFi Settings',
          };
        }
        return {
          'action': 'connect_wifi',
          'message': 'Please connect to a WiFi network to share files.',
          'canTransfer': false,
        };
      
      case NetworkState.checking:
        return {
          'action': 'wait',
          'message': 'Checking network connection...',
          'canTransfer': false,
        };
    }
  }

  /// Get network summary for UI
  Map<String, dynamic> getNetworkSummary() {
    final recommendation = getRecommendedAction();
    
    return {
      'state': _currentState.toString(),
      'isConnected': _networkInfo['isConnected'] ?? false,
      'networkType': _networkInfo['type'] ?? 'unknown',
      'ssid': _networkInfo['ssid'],
      'ipAddress': _networkInfo['ipAddress'],
      'gateway': _networkInfo['gateway'],
      'canTransfer': recommendation['canTransfer'],
      'message': recommendation['message'],
      'actionRequired': recommendation['action'] != 'none',
      'recommendedAction': recommendation,
    };
  }

  /// Check if file transfer is possible
  Future<bool> canTransferFiles() async {
    await _checkNetworkState();
    return _currentState == NetworkState.wifiConnected ||
           _currentState == NetworkState.hotspotActive ||
           _currentState == NetworkState.hotspotConnected;
  }

  /// Get local IP address for sharing
  Future<String?> getLocalIpAddress() async {
    try {
      // Use Windows native service on Windows
      if (Platform.isWindows) {
        final ip = await _windowsNetworkService.getLocalIP();
        if (ip != null) return ip;
      }
      
      // Standard method for other platforms
      final ip = await _networkInfoService.getWifiIP();
      if (ip != null && ip != '0.0.0.0') {
        return ip;
      }
      
      // Fallback: try to get any local IP
      final interfaces = await NetworkInterface.list(
        type: InternetAddressType.IPv4,
        includeLoopback: false,
      );
      
      for (final interface in interfaces) {
        for (final addr in interface.addresses) {
          if (!addr.isLoopback && _isPrivateIp(addr.address)) {
            return addr.address;
          }
        }
      }
      
      return null;
    } catch (e) {
      AppLogger.error('Failed to get local IP', e);
      return null;
    }
  }

  /// Check if an IP address is in a private range
  /// Supports: 192.168.x.x, 10.x.x.x, 172.16-31.x.x
  bool _isPrivateIp(String ip) {
    // 192.168.0.0/16
    if (ip.startsWith('192.168.')) return true;
    
    // 10.0.0.0/8
    if (ip.startsWith('10.')) return true;
    
    // 172.16.0.0/12 (172.16.0.0 to 172.31.255.255)
    if (ip.startsWith('172.')) {
      final parts = ip.split('.');
      if (parts.length >= 2) {
        final secondOctet = int.tryParse(parts[1]);
        if (secondOctet != null && secondOctet >= 16 && secondOctet <= 31) {
          return true;
        }
      }
    }
    
    return false;
  }

  /// Wait for network connection
  Future<bool> waitForConnection({Duration timeout = const Duration(seconds: 30)}) async {
    final completer = Completer<bool>();
    late Timer timeoutTimer;
    StreamSubscription? sub;

    // Check if already connected
    if (await canTransferFiles()) {
      return true;
    }

    // Subscribe to state changes
    sub = _stateController.stream.listen((state) {
      if (state == NetworkState.wifiConnected ||
          state == NetworkState.hotspotActive ||
          state == NetworkState.hotspotConnected) {
        timeoutTimer.cancel();
        sub?.cancel();
        if (!completer.isCompleted) {
          completer.complete(true);
        }
      }
    });

    // Set timeout
    timeoutTimer = Timer(timeout, () {
      sub?.cancel();
      if (!completer.isCompleted) {
        completer.complete(false);
      }
    });

    return completer.future;
  }
}

/// Extension to convert NetworkState to display string
extension NetworkStateString on NetworkState {
  String get displayName {
    switch (this) {
      case NetworkState.wifiConnected:
        return 'WiFi Connected';
      case NetworkState.hotspotActive:
        return 'Hotspot Active';
      case NetworkState.hotspotConnected:
        return 'Hotspot Connected';
      case NetworkState.noConnection:
        return 'No Connection';
      case NetworkState.checking:
        return 'Checking...';
    }
  }

  IconData get icon {
    switch (this) {
      case NetworkState.wifiConnected:
        return Icons.wifi_rounded;
      case NetworkState.hotspotActive:
        return Icons.wifi_tethering_rounded;
      case NetworkState.hotspotConnected:
        return Icons.phonelink_ring_rounded;
      case NetworkState.noConnection:
        return Icons.wifi_off_rounded;
      case NetworkState.checking:
        return Icons.signal_wifi_statusbar_null_rounded;
    }
  }

  Color get color {
    switch (this) {
      case NetworkState.wifiConnected:
        return const Color(0xFF22C55E);
      case NetworkState.hotspotActive:
        return const Color(0xFF0EA5E9);
      case NetworkState.hotspotConnected:
        return const Color(0xFF8B5CF6);
      case NetworkState.noConnection:
        return const Color(0xFFEF4444);
      case NetworkState.checking:
        return const Color(0xFFF59E0B);
    }
  }
}
