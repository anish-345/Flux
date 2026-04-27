// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'transfer_history.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$TransferHistoryImpl _$$TransferHistoryImplFromJson(
  Map<String, dynamic> json,
) => _$TransferHistoryImpl(
  id: json['id'] as String,
  fileName: json['fileName'] as String,
  fileSize: (json['fileSize'] as num).toInt(),
  direction: $enumDecode(_$TransferDirectionEnumMap, json['direction']),
  status: $enumDecode(_$TransferStatusEnumMap, json['status']),
  timestamp: DateTime.parse(json['timestamp'] as String),
  peerDeviceName: json['peerDeviceName'] as String?,
  peerIpAddress: json['peerIpAddress'] as String?,
  progress: (json['progress'] as num?)?.toDouble(),
  speed: (json['speed'] as num?)?.toDouble(),
  errorMessage: json['errorMessage'] as String?,
);

Map<String, dynamic> _$$TransferHistoryImplToJson(
  _$TransferHistoryImpl instance,
) => <String, dynamic>{
  'id': instance.id,
  'fileName': instance.fileName,
  'fileSize': instance.fileSize,
  'direction': _$TransferDirectionEnumMap[instance.direction]!,
  'status': _$TransferStatusEnumMap[instance.status]!,
  'timestamp': instance.timestamp.toIso8601String(),
  'peerDeviceName': instance.peerDeviceName,
  'peerIpAddress': instance.peerIpAddress,
  'progress': instance.progress,
  'speed': instance.speed,
  'errorMessage': instance.errorMessage,
};

const _$TransferDirectionEnumMap = {
  TransferDirection.sent: 'sent',
  TransferDirection.received: 'received',
};

const _$TransferStatusEnumMap = {
  TransferStatus.pending: 'pending',
  TransferStatus.inProgress: 'inProgress',
  TransferStatus.completed: 'completed',
  TransferStatus.failed: 'failed',
  TransferStatus.cancelled: 'cancelled',
};
