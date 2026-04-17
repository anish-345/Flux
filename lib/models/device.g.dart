// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'device.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$DeviceImpl _$$DeviceImplFromJson(Map<String, dynamic> json) => _$DeviceImpl(
  id: json['id'] as String,
  name: json['name'] as String,
  ipAddress: json['ipAddress'] as String,
  port: (json['port'] as num).toInt(),
  type: $enumDecode(_$DeviceTypeEnumMap, json['type']),
  connectionType: $enumDecode(_$ConnectionTypeEnumMap, json['connectionType']),
  discoveredAt: DateTime.parse(json['discoveredAt'] as String),
  isConnected: json['isConnected'] as bool? ?? false,
  isTrusted: json['isTrusted'] as bool? ?? false,
  publicKey: json['publicKey'] as String?,
  deviceModel: json['deviceModel'] as String?,
  osVersion: json['osVersion'] as String?,
);

Map<String, dynamic> _$$DeviceImplToJson(_$DeviceImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'ipAddress': instance.ipAddress,
      'port': instance.port,
      'type': _$DeviceTypeEnumMap[instance.type]!,
      'connectionType': _$ConnectionTypeEnumMap[instance.connectionType]!,
      'discoveredAt': instance.discoveredAt.toIso8601String(),
      'isConnected': instance.isConnected,
      'isTrusted': instance.isTrusted,
      'publicKey': instance.publicKey,
      'deviceModel': instance.deviceModel,
      'osVersion': instance.osVersion,
    };

const _$DeviceTypeEnumMap = {
  DeviceType.mobile: 'mobile',
  DeviceType.tablet: 'tablet',
  DeviceType.desktop: 'desktop',
  DeviceType.laptop: 'laptop',
  DeviceType.unknown: 'unknown',
};

const _$ConnectionTypeEnumMap = {
  ConnectionType.bluetooth: 'bluetooth',
  ConnectionType.wifi: 'wifi',
  ConnectionType.hotspot: 'hotspot',
  ConnectionType.usb: 'usb',
  ConnectionType.unknown: 'unknown',
};
