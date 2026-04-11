import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flux/models/connection_state.dart';
import 'package:flux/services/connectivity_service.dart';
import 'package:flux/utils/logger.dart';

/// Provider for monitoring network and Bluetooth connectivity
final connectionProvider =
    StateNotifierProvider<ConnectionNotifier, AppConnectionState>((ref) {
      return ConnectionNotifier();
    });

class ConnectionNotifier extends StateNotifier<AppConnectionState> {
  late ConnectivityService _connectivityService;

  ConnectionNotifier()
    : super(
        const AppConnectionState(
          isInternetConnected: false,
          isBluetoothEnabled: false,
          isWiFiEnabled: false,
          isHotspotEnabled: false,
          currentWiFiSSID: null,
          deviceIPAddress: null,
          availableNetworks: [],
          isDiscovering: false,
          discoveredDevicesCount: 0,
        ),
      ) {
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      _connectivityService = ConnectivityService();
      await _connectivityService.initialize();
      _setupListeners();
      await _updateConnectionState();
      AppLogger.info('ConnectionNotifier initialized');
    } catch (e) {
      AppLogger.error('Failed to initialize ConnectionNotifier', e);
    }
  }

  void _setupListeners() {
    _connectivityService.connectivityStream.listen((_) {
      _updateConnectionState();
    });
  }

  Future<void> _updateConnectionState() async {
    try {
      final isInternetConnected = await _connectivityService
          .isInternetConnected();
      final isBluetoothEnabled = await _connectivityService
          .isBluetoothEnabled();
      final isWiFiEnabled = await _connectivityService.isWiFiEnabled();
      final currentSSID = await _connectivityService.getCurrentWiFiSSID();
      final deviceIP = await _connectivityService.getDeviceIPAddress();

      state = state.copyWith(
        isInternetConnected: isInternetConnected,
        isBluetoothEnabled: isBluetoothEnabled,
        isWiFiEnabled: isWiFiEnabled,
        currentWiFiSSID: currentSSID,
        deviceIPAddress: deviceIP,
      );
    } catch (e) {
      AppLogger.error('Failed to update connection state', e);
    }
  }

  Future<void> enableBluetooth() async {
    try {
      state = state.copyWith(isBluetoothEnabled: true);
      AppLogger.info('Bluetooth enabled');
    } catch (e) {
      AppLogger.error('Failed to enable Bluetooth', e);
    }
  }

  Future<void> disableBluetooth() async {
    try {
      state = state.copyWith(isBluetoothEnabled: false);
      AppLogger.info('Bluetooth disabled');
    } catch (e) {
      AppLogger.error('Failed to disable Bluetooth', e);
    }
  }

  Future<void> startDiscovery() async {
    try {
      state = state.copyWith(isDiscovering: true);
      AppLogger.info('Device discovery started');
    } catch (e) {
      AppLogger.error('Failed to start discovery', e);
    }
  }

  Future<void> stopDiscovery() async {
    try {
      state = state.copyWith(isDiscovering: false);
      AppLogger.info('Device discovery stopped');
    } catch (e) {
      AppLogger.error('Failed to stop discovery', e);
    }
  }

  void updateDiscoveredDevicesCount(int count) {
    state = state.copyWith(discoveredDevicesCount: count);
  }
}
