import 'package:freezed_annotation/freezed_annotation.dart';

part 'connection_state.freezed.dart';
part 'connection_state.g.dart';

/// Overall connection state of the app
@freezed
class AppConnectionState with _$AppConnectionState {
  const factory AppConnectionState({
    required bool isInternetConnected,
    required bool isBluetoothEnabled,
    required bool isWiFiEnabled,
    required bool isHotspotEnabled,
    required String? currentWiFiSSID,
    required String? deviceIPAddress,
    @Default([]) List<String> availableNetworks,
    @Default(false) bool isDiscovering,
    @Default(0) int discoveredDevicesCount,
  }) = _AppConnectionState;

  factory AppConnectionState.fromJson(Map<String, dynamic> json) =>
      _$AppConnectionStateFromJson(json);
}

/// Represents the state of a single connection
@freezed
class ConnectionInfo with _$ConnectionInfo {
  const factory ConnectionInfo({
    required String deviceId,
    required String deviceName,
    required ConnectionStatus status,
    required DateTime connectedAt,
    DateTime? disconnectedAt,
    @Default(0) int bytesTransferred,
    @Default(0) int filesTransferred,
    String? error,
  }) = _ConnectionInfo;

  factory ConnectionInfo.fromJson(Map<String, dynamic> json) =>
      _$ConnectionInfoFromJson(json);
}

enum ConnectionStatus {
  connecting,
  connected,
  authenticated,
  disconnecting,
  disconnected,
  error,
}

extension ConnectionStatusExtension on ConnectionStatus {
  String get displayName {
    switch (this) {
      case ConnectionStatus.connecting:
        return 'Connecting...';
      case ConnectionStatus.connected:
        return 'Connected';
      case ConnectionStatus.authenticated:
        return 'Authenticated';
      case ConnectionStatus.disconnecting:
        return 'Disconnecting...';
      case ConnectionStatus.disconnected:
        return 'Disconnected';
      case ConnectionStatus.error:
        return 'Error';
    }
  }

  bool get isActive =>
      this == ConnectionStatus.connected ||
      this == ConnectionStatus.authenticated;

  bool get isLoading =>
      this == ConnectionStatus.connecting ||
      this == ConnectionStatus.disconnecting;
}
