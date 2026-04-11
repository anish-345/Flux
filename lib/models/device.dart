import 'package:freezed_annotation/freezed_annotation.dart';

part 'device.freezed.dart';
part 'device.g.dart';

/// Represents a connected device for file sharing
@freezed
class Device with _$Device {
  const factory Device({
    required String id,
    required String name,
    required String ipAddress,
    required int port,
    required DeviceType type,
    required ConnectionType connectionType,
    required DateTime discoveredAt,
    @Default(false) bool isConnected,
    @Default(false) bool isTrusted,
    String? publicKey,
    String? deviceModel,
    String? osVersion,
  }) = _Device;

  factory Device.fromJson(Map<String, dynamic> json) => _$DeviceFromJson(json);
}

enum DeviceType { mobile, tablet, desktop, laptop, unknown }

enum ConnectionType { bluetooth, wifi, hotspot, usb, unknown }

extension DeviceTypeExtension on DeviceType {
  String get displayName {
    switch (this) {
      case DeviceType.mobile:
        return 'Mobile';
      case DeviceType.tablet:
        return 'Tablet';
      case DeviceType.desktop:
        return 'Desktop';
      case DeviceType.laptop:
        return 'Laptop';
      case DeviceType.unknown:
        return 'Unknown';
    }
  }

  String get icon {
    switch (this) {
      case DeviceType.mobile:
        return '📱';
      case DeviceType.tablet:
        return '📱';
      case DeviceType.desktop:
        return '🖥️';
      case DeviceType.laptop:
        return '💻';
      case DeviceType.unknown:
        return '❓';
    }
  }
}

extension ConnectionTypeExtension on ConnectionType {
  String get displayName {
    switch (this) {
      case ConnectionType.bluetooth:
        return 'Bluetooth';
      case ConnectionType.wifi:
        return 'WiFi';
      case ConnectionType.hotspot:
        return 'Hotspot';
      case ConnectionType.usb:
        return 'USB';
      case ConnectionType.unknown:
        return 'Unknown';
    }
  }

  String get icon {
    switch (this) {
      case ConnectionType.bluetooth:
        return '🔵';
      case ConnectionType.wifi:
        return '📶';
      case ConnectionType.hotspot:
        return '🌐';
      case ConnectionType.usb:
        return '🔌';
      case ConnectionType.unknown:
        return '❓';
    }
  }
}
