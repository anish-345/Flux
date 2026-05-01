import 'package:freezed_annotation/freezed_annotation.dart';

part 'transfer_history.freezed.dart';
part 'transfer_history.g.dart';

/// Transfer direction enum
enum TransferDirection {
  send,
  receive,
}

/// Transfer status enum
enum TransferStatus {
  pending,
  inProgress,
  completed,
  failed,
  cancelled,
}

/// Transfer history model
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
  }) = _TransferHistory;

  factory TransferHistory.fromJson(Map<String, dynamic> json) =>
      _$TransferHistoryFromJson(json);
}
