import 'package:freezed_annotation/freezed_annotation.dart';

part 'file_metadata.freezed.dart';
part 'file_metadata.g.dart';

/// Metadata for files being transferred
@freezed
class FileMetadata with _$FileMetadata {
  const factory FileMetadata({
    required String id,
    required String name,
    required int size,
    required String mimeType,
    required String hash,
    required DateTime createdAt,
    required DateTime modifiedAt,
    @Default(false) bool isDirectory,
    String? path,
    String? description,
  }) = _FileMetadata;

  factory FileMetadata.fromJson(Map<String, dynamic> json) =>
      _$FileMetadataFromJson(json);
}

/// Transfer status for a file
@freezed
class TransferStatus with _$TransferStatus {
  const factory TransferStatus({
    required String fileId,
    required String fileName,
    required TransferState state,
    required int totalBytes,
    required int transferredBytes,
    required DateTime startedAt,
    DateTime? completedAt,
    String? error,
    @Default(0.0) double speed, // bytes per second
    @Default(0) int remainingSeconds,
  }) = _TransferStatus;

  factory TransferStatus.fromJson(Map<String, dynamic> json) =>
      _$TransferStatusFromJson(json);
}

enum TransferState { pending, inProgress, paused, completed, failed, cancelled }

extension TransferStateExtension on TransferState {
  String get displayName {
    switch (this) {
      case TransferState.pending:
        return 'Pending';
      case TransferState.inProgress:
        return 'Transferring';
      case TransferState.paused:
        return 'Paused';
      case TransferState.completed:
        return 'Completed';
      case TransferState.failed:
        return 'Failed';
      case TransferState.cancelled:
        return 'Cancelled';
    }
  }

  bool get isActive => this == TransferState.inProgress;
  bool get isTerminal =>
      this == TransferState.completed ||
      this == TransferState.failed ||
      this == TransferState.cancelled;
}

/// Transfer history entry
@freezed
class TransferHistory with _$TransferHistory {
  const factory TransferHistory({
    required String id,
    required String deviceId,
    required String deviceName,
    required String fileName,
    required int fileSize,
    required TransferDirection direction,
    required DateTime timestamp,
    required bool success,
    String? error,
    @Default(0) int durationSeconds,
  }) = _TransferHistory;

  factory TransferHistory.fromJson(Map<String, dynamic> json) =>
      _$TransferHistoryFromJson(json);
}

enum TransferDirection { send, receive }

extension TransferDirectionExtension on TransferDirection {
  String get displayName {
    switch (this) {
      case TransferDirection.send:
        return 'Sent';
      case TransferDirection.receive:
        return 'Received';
    }
  }

  String get icon {
    switch (this) {
      case TransferDirection.send:
        return '📤';
      case TransferDirection.receive:
        return '📥';
    }
  }
}
