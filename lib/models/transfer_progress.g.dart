// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'transfer_progress.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$TransferProgressImpl _$$TransferProgressImplFromJson(
  Map<String, dynamic> json,
) => _$TransferProgressImpl(
  fileId: json['fileId'] as String,
  totalBytes: (json['totalBytes'] as num).toInt(),
  transferredBytes: (json['transferredBytes'] as num).toInt(),
  startedAt: DateTime.parse(json['startedAt'] as String),
  speed: (json['speed'] as num).toDouble(),
  remainingSeconds: (json['remainingSeconds'] as num).toInt(),
  chunksTransferred: (json['chunksTransferred'] as num?)?.toInt() ?? 0,
  totalChunks: (json['totalChunks'] as num?)?.toInt() ?? 0,
  accuracy: (json['accuracy'] as num?)?.toDouble() ?? 0.0,
  lastError: json['lastError'] as String?,
);

Map<String, dynamic> _$$TransferProgressImplToJson(
  _$TransferProgressImpl instance,
) => <String, dynamic>{
  'fileId': instance.fileId,
  'totalBytes': instance.totalBytes,
  'transferredBytes': instance.transferredBytes,
  'startedAt': instance.startedAt.toIso8601String(),
  'speed': instance.speed,
  'remainingSeconds': instance.remainingSeconds,
  'chunksTransferred': instance.chunksTransferred,
  'totalChunks': instance.totalChunks,
  'accuracy': instance.accuracy,
  'lastError': instance.lastError,
};
