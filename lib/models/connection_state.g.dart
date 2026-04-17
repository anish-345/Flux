// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'connection_state.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$AppConnectionStateImpl _$$AppConnectionStateImplFromJson(
  Map<String, dynamic> json,
) => _$AppConnectionStateImpl(
  isInternetConnected: json['isInternetConnected'] as bool,
  isBluetoothEnabled: json['isBluetoothEnabled'] as bool,
  isWiFiEnabled: json['isWiFiEnabled'] as bool,
  isHotspotEnabled: json['isHotspotEnabled'] as bool,
  currentWiFiSSID: json['currentWiFiSSID'] as String?,
  deviceIPAddress: json['deviceIPAddress'] as String?,
  availableNetworks:
      (json['availableNetworks'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      const [],
  isDiscovering: json['isDiscovering'] as bool? ?? false,
  discoveredDevicesCount:
      (json['discoveredDevicesCount'] as num?)?.toInt() ?? 0,
);

Map<String, dynamic> _$$AppConnectionStateImplToJson(
  _$AppConnectionStateImpl instance,
) => <String, dynamic>{
  'isInternetConnected': instance.isInternetConnected,
  'isBluetoothEnabled': instance.isBluetoothEnabled,
  'isWiFiEnabled': instance.isWiFiEnabled,
  'isHotspotEnabled': instance.isHotspotEnabled,
  'currentWiFiSSID': instance.currentWiFiSSID,
  'deviceIPAddress': instance.deviceIPAddress,
  'availableNetworks': instance.availableNetworks,
  'isDiscovering': instance.isDiscovering,
  'discoveredDevicesCount': instance.discoveredDevicesCount,
};

_$ConnectionInfoImpl _$$ConnectionInfoImplFromJson(Map<String, dynamic> json) =>
    _$ConnectionInfoImpl(
      deviceId: json['deviceId'] as String,
      deviceName: json['deviceName'] as String,
      status: $enumDecode(_$ConnectionStatusEnumMap, json['status']),
      connectedAt: DateTime.parse(json['connectedAt'] as String),
      disconnectedAt: json['disconnectedAt'] == null
          ? null
          : DateTime.parse(json['disconnectedAt'] as String),
      bytesTransferred: (json['bytesTransferred'] as num?)?.toInt() ?? 0,
      filesTransferred: (json['filesTransferred'] as num?)?.toInt() ?? 0,
      error: json['error'] as String?,
    );

Map<String, dynamic> _$$ConnectionInfoImplToJson(
  _$ConnectionInfoImpl instance,
) => <String, dynamic>{
  'deviceId': instance.deviceId,
  'deviceName': instance.deviceName,
  'status': _$ConnectionStatusEnumMap[instance.status]!,
  'connectedAt': instance.connectedAt.toIso8601String(),
  'disconnectedAt': instance.disconnectedAt?.toIso8601String(),
  'bytesTransferred': instance.bytesTransferred,
  'filesTransferred': instance.filesTransferred,
  'error': instance.error,
};

const _$ConnectionStatusEnumMap = {
  ConnectionStatus.connecting: 'connecting',
  ConnectionStatus.connected: 'connected',
  ConnectionStatus.authenticated: 'authenticated',
  ConnectionStatus.disconnecting: 'disconnecting',
  ConnectionStatus.disconnected: 'disconnected',
  ConnectionStatus.error: 'error',
};
