// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'transfer_history.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$TransferHistoryImpl _$$TransferHistoryImplFromJson(
  Map<String, dynamic> json,
) => _$TransferHistoryImpl(
  id: json['id'] as String,
  deviceId: json['deviceId'] as String,
  deviceName: json['deviceName'] as String,
  fileName: json['fileName'] as String,
  fileSize: (json['fileSize'] as num).toInt(),
  direction: $enumDecode(_$TransferDirectionEnumMap, json['direction']),
  timestamp: DateTime.parse(json['timestamp'] as String),
  success: json['success'] as bool,
  error: json['error'] as String?,
);

Map<String, dynamic> _$$TransferHistoryImplToJson(
  _$TransferHistoryImpl instance,
) => <String, dynamic>{
  'id': instance.id,
  'deviceId': instance.deviceId,
  'deviceName': instance.deviceName,
  'fileName': instance.fileName,
  'fileSize': instance.fileSize,
  'direction': _$TransferDirectionEnumMap[instance.direction]!,
  'timestamp': instance.timestamp.toIso8601String(),
  'success': instance.success,
  'error': instance.error,
};

const _$TransferDirectionEnumMap = {
  TransferDirection.send: 'send',
  TransferDirection.receive: 'receive',
};
