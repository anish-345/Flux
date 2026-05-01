import 'package:uuid/uuid.dart';

/// Represents a queued file transfer
class QueuedTransfer {
  final String id;
  final String filePath;
  final String deviceId;
  final String deviceName;
  final int fileSize;
  final DateTime queuedAt;
  final TransferDirection direction;
  final TransferStatus status;
  final int? transferredBytes;
  final String? errorMessage;
  final int retryCount;
  final DateTime? lastRetryAt;

  QueuedTransfer({
    String? id,
    required this.filePath,
    required this.deviceId,
    required this.deviceName,
    required this.fileSize,
    DateTime? queuedAt,
    this.direction = TransferDirection.send,
    this.status = TransferStatus.pending,
    this.transferredBytes,
    this.errorMessage,
    this.retryCount = 0,
    this.lastRetryAt,
  }) : id = id ?? const Uuid().v4(),
       queuedAt = queuedAt ?? DateTime.now();

  /// Get progress (0.0 to 1.0)
  double get progress {
    if (fileSize == 0) return 0;
    return (transferredBytes ?? 0) / fileSize;
  }

  /// Get percentage complete
  int get percentComplete => (progress * 100).toInt();

  /// Check if transfer is complete
  bool get isComplete => status == TransferStatus.completed;

  /// Check if transfer failed
  bool get isFailed => status == TransferStatus.failed;

  /// Check if transfer is in progress
  bool get isInProgress => status == TransferStatus.inProgress;

  /// Check if transfer is pending
  bool get isPending => status == TransferStatus.pending;

  /// Check if transfer can be retried
  bool get canRetry => isFailed && retryCount < 3;

  /// Create a copy with updated fields
  QueuedTransfer copyWith({
    String? id,
    String? filePath,
    String? deviceId,
    String? deviceName,
    int? fileSize,
    DateTime? queuedAt,
    TransferDirection? direction,
    TransferStatus? status,
    int? transferredBytes,
    String? errorMessage,
    int? retryCount,
    DateTime? lastRetryAt,
  }) {
    return QueuedTransfer(
      id: id ?? this.id,
      filePath: filePath ?? this.filePath,
      deviceId: deviceId ?? this.deviceId,
      deviceName: deviceName ?? this.deviceName,
      fileSize: fileSize ?? this.fileSize,
      queuedAt: queuedAt ?? this.queuedAt,
      direction: direction ?? this.direction,
      status: status ?? this.status,
      transferredBytes: transferredBytes ?? this.transferredBytes,
      errorMessage: errorMessage ?? this.errorMessage,
      retryCount: retryCount ?? this.retryCount,
      lastRetryAt: lastRetryAt ?? this.lastRetryAt,
    );
  }

  /// Convert to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'filePath': filePath,
      'deviceId': deviceId,
      'deviceName': deviceName,
      'fileSize': fileSize,
      'queuedAt': queuedAt.toIso8601String(),
      'direction': direction.toString(),
      'status': status.toString(),
      'transferredBytes': transferredBytes,
      'errorMessage': errorMessage,
      'retryCount': retryCount,
      'lastRetryAt': lastRetryAt?.toIso8601String(),
    };
  }

  /// Create from JSON
  factory QueuedTransfer.fromJson(Map<String, dynamic> json) {
    return QueuedTransfer(
      id: json['id'] as String,
      filePath: json['filePath'] as String,
      deviceId: json['deviceId'] as String,
      deviceName: json['deviceName'] as String,
      fileSize: json['fileSize'] as int,
      queuedAt: DateTime.parse(json['queuedAt'] as String),
      direction: TransferDirection.values.firstWhere(
        (e) => e.toString() == json['direction'],
      ),
      status: TransferStatus.values.firstWhere(
        (e) => e.toString() == json['status'],
      ),
      transferredBytes: json['transferredBytes'] as int?,
      errorMessage: json['errorMessage'] as String?,
      retryCount: json['retryCount'] as int? ?? 0,
      lastRetryAt: json['lastRetryAt'] != null
          ? DateTime.parse(json['lastRetryAt'] as String)
          : null,
    );
  }
}

/// Transfer direction
enum TransferDirection { send, receive }

/// Transfer status
enum TransferStatus {
  pending,
  inProgress,
  completed,
  failed,
  cancelled,
  paused,
}
