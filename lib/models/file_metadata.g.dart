// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'file_metadata.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$FileMetadataImpl _$$FileMetadataImplFromJson(Map<String, dynamic> json) =>
    _$FileMetadataImpl(
      id: json['id'] as String,
      name: json['name'] as String,
      size: (json['size'] as num).toInt(),
      mimeType: json['mimeType'] as String,
      hash: json['hash'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      modifiedAt: DateTime.parse(json['modifiedAt'] as String),
      isDirectory: json['isDirectory'] as bool? ?? false,
      path: json['path'] as String?,
      description: json['description'] as String?,
    );

Map<String, dynamic> _$$FileMetadataImplToJson(_$FileMetadataImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'size': instance.size,
      'mimeType': instance.mimeType,
      'hash': instance.hash,
      'createdAt': instance.createdAt.toIso8601String(),
      'modifiedAt': instance.modifiedAt.toIso8601String(),
      'isDirectory': instance.isDirectory,
      'path': instance.path,
      'description': instance.description,
    };

_$TransferStatusImpl _$$TransferStatusImplFromJson(Map<String, dynamic> json) =>
    _$TransferStatusImpl(
      fileId: json['fileId'] as String,
      fileName: json['fileName'] as String,
      state: $enumDecode(_$TransferStateEnumMap, json['state']),
      totalBytes: (json['totalBytes'] as num).toInt(),
      transferredBytes: (json['transferredBytes'] as num).toInt(),
      startedAt: DateTime.parse(json['startedAt'] as String),
      completedAt: json['completedAt'] == null
          ? null
          : DateTime.parse(json['completedAt'] as String),
      error: json['error'] as String?,
      speed: (json['speed'] as num?)?.toDouble() ?? 0.0,
      remainingSeconds: (json['remainingSeconds'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$$TransferStatusImplToJson(
  _$TransferStatusImpl instance,
) => <String, dynamic>{
  'fileId': instance.fileId,
  'fileName': instance.fileName,
  'state': _$TransferStateEnumMap[instance.state]!,
  'totalBytes': instance.totalBytes,
  'transferredBytes': instance.transferredBytes,
  'startedAt': instance.startedAt.toIso8601String(),
  'completedAt': instance.completedAt?.toIso8601String(),
  'error': instance.error,
  'speed': instance.speed,
  'remainingSeconds': instance.remainingSeconds,
};

const _$TransferStateEnumMap = {
  TransferState.pending: 'pending',
  TransferState.inProgress: 'inProgress',
  TransferState.paused: 'paused',
  TransferState.completed: 'completed',
  TransferState.failed: 'failed',
  TransferState.cancelled: 'cancelled',
};

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
  durationSeconds: (json['durationSeconds'] as num?)?.toInt() ?? 0,
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
  'durationSeconds': instance.durationSeconds,
};

const _$TransferDirectionEnumMap = {
  TransferDirection.send: 'send',
  TransferDirection.receive: 'receive',
};
