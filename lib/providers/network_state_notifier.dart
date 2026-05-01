import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flux/services/network_manager_service.dart';
import 'package:flux/services/hotspot_service.dart';
import 'package:flux/services/connectivity_service.dart';
import 'package:flux/utils/logger.dart';

/// Network state for transfer operations
enum NetworkState {
  idle,
  connecting,
  wifiConnected,
  hotspotActive,
  error,
}

/// Network state data
class NetworkStateData {
  final NetworkState state;
  final String? ipAddress;
  final String? ssid;
  final String? errorMessage;

  const NetworkStateData({
    required this.state,
    this.ipAddress,
    this.ssid,
    this.errorMessage,
  });

  NetworkStateData copyWith({
    NetworkState? state,
    String? ipAddress,
    String? ssid,
    String? errorMessage,
  }) {
    return NetworkStateData(
      state: state ?? this.state,
      ipAddress: ipAddress ?? this.ipAddress,
      ssid: ssid ?? this.ssid,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  /// Check if connected
  bool get isConnected => state == NetworkState.wifiConnected || state == NetworkState.hotspotActive;

  /// Check if hotspot is active
  bool get isHotspotActive => state == NetworkState.hotspotActive;
}

/// Provider for network state
final networkStateProvider = StateNotifierProvider<NetworkStateNotifier, NetworkStateData>((ref) {
  return NetworkStateNotifier();
});

/// Notifier for managing network connection state
/// Handles WiFi, hotspot, and connection logic in the background
class NetworkStateNotifier extends StateNotifier<NetworkStateData> {
  final NetworkManagerService _networkManager = NetworkManagerService();
  final HotspotService _hotspotService = HotspotService();
  final ConnectivityService _connectivityService = ConnectivityService();

  NetworkStateNotifier() : super(const NetworkStateData(state: NetworkState.idle));

  /// Ensure best network connection is available
  /// Automatically chooses between WiFi and hotspot
  Future<bool> ensureBestNetworkConnection({bool preferHotspot = false}) async {
    state = state.copyWith(state: NetworkState.connecting);

    try {
      // Check current network state
      final currentState = _networkManager.currentState;

      // If already on WiFi and not preferring hotspot, use that
      if (currentState.name == 'wifiConnected' && !preferHotspot) {
        final ip = await _networkManager.getLocalIpAddress();
        final ssid = await _connectivityService.getWiFiSSID();
        state = NetworkStateData(
          state: NetworkState.wifiConnected,
          ipAddress: ip,
          ssid: ssid,
        );
        AppLogger.info('Using existing WiFi connection: $ip');
        return true;
      }

      // If preferring hotspot or not on WiFi, try to enable hotspot
      if (preferHotspot || currentState.name != 'wifiConnected') {
        final hotspotEnabled = await _hotspotService.enableHotspot();
        if (hotspotEnabled) {
          // Wait for hotspot to be ready
          await Future.delayed(const Duration(seconds: 2));
          final ip = await _networkManager.getLocalIpAddress();
          final hotspotSsid = await _hotspotService.getHotspotSSID();
          state = NetworkStateData(
            state: NetworkState.hotspotActive,
            ipAddress: ip,
            ssid: hotspotSsid,
          );
          AppLogger.info('Using hotspot: $ip');
          return true;
        }
      }

      // Try to connect to existing WiFi
      final networkResult = await _networkManager.ensureNetworkConnection();
      if (networkResult['success']) {
        final ip = await _networkManager.getLocalIpAddress();
        final ssid = await _connectivityService.getWiFiSSID();
        state = NetworkStateData(
          state: NetworkState.wifiConnected,
          ipAddress: ip,
          ssid: ssid,
        );
        AppLogger.info('Network connected: $ip');
        return true;
      }

      state = state.copyWith(
        state: NetworkState.error,
        errorMessage: 'Unable to establish network connection',
      );
      return false;
    } catch (e) {
      AppLogger.error('Network connection failed', e);
      state = state.copyWith(
        state: NetworkState.error,
        errorMessage: e.toString(),
      );
      return false;
    }
  }

  /// Reset network state to idle
  void reset() {
    state = const NetworkStateData(state: NetworkState.idle);
  }

  /// Get current IP address
  String? get ipAddress => state.ipAddress;

  /// Get current SSID
  String? get ssid => state.ssid;

  /// Check if connected
  bool get isConnected => state.state == NetworkState.wifiConnected || state.state == NetworkState.hotspotActive;

  /// Check if hotspot is active
  bool get isHotspotActive => state.state == NetworkState.hotspotActive;
}
