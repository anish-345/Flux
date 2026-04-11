import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'base_service.dart';

/// Service for managing network connectivity
class ConnectivityService extends BaseService {
  static final ConnectivityService _instance = ConnectivityService._internal();

  factory ConnectivityService() {
    return _instance;
  }

  ConnectivityService._internal();

  final Connectivity _connectivity = Connectivity();
  final NetworkInfo _networkInfo = NetworkInfo();

  /// Stream of connectivity changes
  Stream<List<ConnectivityResult>> get connectivityStream =>
      _connectivity.onConnectivityChanged as Stream<List<ConnectivityResult>>;

  /// Get current connectivity status
  Future<List<ConnectivityResult>> getConnectivityStatus() async {
    try {
      final result =
          await _connectivity.checkConnectivity() as List<ConnectivityResult>;
      logDebug('Connectivity status: $result');
      return result;
    } catch (e) {
      logError('Failed to get connectivity status', e);
      return [];
    }
  }

  /// Check if device is connected to internet
  Future<bool> isConnectedToInternet() async {
    try {
      final result = await getConnectivityStatus();
      return result.contains(ConnectivityResult.mobile) ||
          result.contains(ConnectivityResult.wifi) ||
          result.contains(ConnectivityResult.ethernet);
    } catch (e) {
      logError('Failed to check internet connection', e);
      return false;
    }
  }

  /// Alias for isConnectedToInternet
  Future<bool> isInternetConnected() => isConnectedToInternet();

  /// Check if Bluetooth is enabled (placeholder - requires platform-specific implementation)
  Future<bool> isBluetoothEnabled() async {
    try {
      logDebug('Checking Bluetooth enabled status');
      return false;
    } catch (e) {
      logError('Failed to check Bluetooth enabled status', e);
      return false;
    }
  }

  /// Check if device is connected to WiFi
  Future<bool> isConnectedToWiFi() async {
    try {
      final result = await getConnectivityStatus();
      return result.contains(ConnectivityResult.wifi);
    } catch (e) {
      logError('Failed to check WiFi connection', e);
      return false;
    }
  }

  /// Alias for isConnectedToWiFi
  Future<bool> isWiFiEnabled() => isConnectedToWiFi();

  /// Check if device is connected to mobile network
  Future<bool> isConnectedToMobile() async {
    try {
      final result = await getConnectivityStatus();
      return result.contains(ConnectivityResult.mobile);
    } catch (e) {
      logError('Failed to check mobile connection', e);
      return false;
    }
  }

  /// Get WiFi SSID
  Future<String?> getWiFiSSID() async {
    try {
      final ssid = await _networkInfo.getWifiName();
      logDebug('WiFi SSID: $ssid');
      return ssid;
    } catch (e) {
      logError('Failed to get WiFi SSID', e);
      return null;
    }
  }

  /// Alias for getWiFiSSID
  Future<String?> getCurrentWiFiSSID() => getWiFiSSID();

  /// Get WiFi BSSID (MAC address)
  Future<String?> getWiFiBSSID() async {
    try {
      final bssid = await _networkInfo.getWifiBSSID();
      logDebug('WiFi BSSID: $bssid');
      return bssid;
    } catch (e) {
      logError('Failed to get WiFi BSSID', e);
      return null;
    }
  }

  /// Get device IP address
  Future<String?> getDeviceIPAddress() async {
    try {
      final ip = await _networkInfo.getWifiIP();
      logDebug('Device IP: $ip');
      return ip;
    } catch (e) {
      logError('Failed to get device IP address', e);
      return null;
    }
  }

  /// Get gateway IP address
  Future<String?> getGatewayIPAddress() async {
    try {
      final gateway = await _networkInfo.getWifiGatewayIP();
      logDebug('Gateway IP: $gateway');
      return gateway;
    } catch (e) {
      logError('Failed to get gateway IP address', e);
      return null;
    }
  }

  /// Listen to connectivity changes
  Stream<List<ConnectivityResult>> onConnectivityChanged() {
    return _connectivity.onConnectivityChanged
        as Stream<List<ConnectivityResult>>;
  }
}
