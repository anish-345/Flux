import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flux/models/file_metadata.dart';
import 'package:flux/utils/logger.dart';

/// Provider for managing active file transfers with proper async handling
final fileTransferProvider =
    AsyncNotifierProvider<FileTransferNotifier, List<TransferStatus>>(
      FileTransferNotifier.new,
    );

/// Provider for getting transfer history
final transferHistoryProvider =
    AsyncNotifierProvider<TransferHistoryNotifier, List<TransferHistory>>(
      TransferHistoryNotifier.new,
    );

/// Provider for getting active transfers only
final activeTransfersProvider = Provider<AsyncValue<List<TransferStatus>>>((
  ref,
) {
  final transfers = ref.watch(fileTransferProvider);
  return transfers.whenData(
    (list) => list.where((t) => t.state.isActive).toList(),
  );
});

/// Provider for getting completed transfers
final completedTransfersProvider = Provider<AsyncValue<List<TransferStatus>>>((
  ref,
) {
  final transfers = ref.watch(fileTransferProvider);
  return transfers.whenData(
    (list) => list.where((t) => t.state.isTerminal).toList(),
  );
});

/// Provider for getting total transfer progress
final totalTransferProgressProvider = Provider<double>((ref) {
  final transfers = ref.watch(fileTransferProvider);

  return transfers.when(
    data: (list) {
      if (list.isEmpty) return 0.0;
      final totalBytes = list.fold<int>(0, (sum, t) => sum + t.totalBytes);
      final transferredBytes = list.fold<int>(
        0,
        (sum, t) => sum + t.transferredBytes,
      );
      if (totalBytes == 0) return 0.0;
      return transferredBytes / totalBytes;
    },
    loading: () => 0.0,
    error: (error, stackTrace) => 0.0,
  );
});

class FileTransferNotifier extends AsyncNotifier<List<TransferStatus>> {
  @override
  FutureOr<List<TransferStatus>> build() async {
    // Initialize from storage or return empty list
    return [];
  }

  Future<void> addTransfer(TransferStatus transfer) async {
    state = await AsyncValue.guard(() async {
      final current = await future;
      AppLogger.info('Transfer added: ${transfer.fileId}');
      return [...current, transfer];
    });
  }

  Future<void> updateTransfer(
    String fileId,
    TransferStatus updatedTransfer,
  ) async {
    state = await AsyncValue.guard(() async {
      final current = await future;
      AppLogger.info('Transfer updated: $fileId');
      return current.map((transfer) {
        if (transfer.fileId == fileId) {
          return updatedTransfer;
        }
        return transfer;
      }).toList();
    });
  }

  Future<void> updateTransferProgress(
    String fileId,
    int transferredBytes,
    double speed,
    int remainingSeconds,
  ) async {
    state = await AsyncValue.guard(() async {
      final current = await future;
      return current.map((transfer) {
        if (transfer.fileId == fileId) {
          return transfer.copyWith(
            transferredBytes: transferredBytes,
            speed: speed,
            remainingSeconds: remainingSeconds,
          );
        }
        return transfer;
      }).toList();
    });
  }

  Future<void> pauseTransfer(String fileId) async {
    state = await AsyncValue.guard(() async {
      final current = await future;
      AppLogger.info('Transfer paused: $fileId');
      return current.map((transfer) {
        if (transfer.fileId == fileId) {
          return transfer.copyWith(state: TransferState.paused);
        }
        return transfer;
      }).toList();
    });
  }

  Future<void> resumeTransfer(String fileId) async {
    state = await AsyncValue.guard(() async {
      final current = await future;
      AppLogger.info('Transfer resumed: $fileId');
      return current.map((transfer) {
        if (transfer.fileId == fileId) {
          return transfer.copyWith(state: TransferState.inProgress);
        }
        return transfer;
      }).toList();
    });
  }

  Future<void> cancelTransfer(String fileId) async {
    state = await AsyncValue.guard(() async {
      final current = await future;
      AppLogger.info('Transfer cancelled: $fileId');
      return current.map((transfer) {
        if (transfer.fileId == fileId) {
          return transfer.copyWith(state: TransferState.cancelled);
        }
        return transfer;
      }).toList();
    });
  }

  Future<void> completeTransfer(String fileId) async {
    state = await AsyncValue.guard(() async {
      final current = await future;
      AppLogger.info('Transfer completed: $fileId');
      return current.map((transfer) {
        if (transfer.fileId == fileId) {
          return transfer.copyWith(
            state: TransferState.completed,
            completedAt: DateTime.now(),
          );
        }
        return transfer;
      }).toList();
    });
  }

  Future<void> failTransfer(String fileId, String error) async {
    state = await AsyncValue.guard(() async {
      final current = await future;
      AppLogger.info('Transfer failed: $fileId - $error');
      return current.map((transfer) {
        if (transfer.fileId == fileId) {
          return transfer.copyWith(
            state: TransferState.failed,
            error: error,
            completedAt: DateTime.now(),
          );
        }
        return transfer;
      }).toList();
    });
  }

  Future<void> removeTransfer(String fileId) async {
    state = await AsyncValue.guard(() async {
      final current = await future;
      AppLogger.info('Transfer removed: $fileId');
      return current.where((transfer) => transfer.fileId != fileId).toList();
    });
  }

  Future<void> clearCompletedTransfers() async {
    state = await AsyncValue.guard(() async {
      final current = await future;
      AppLogger.info('Completed transfers cleared');
      return current.where((transfer) => !transfer.state.isTerminal).toList();
    });
  }

  TransferStatus? getTransferById(String fileId) {
    return state.whenData((transfers) {
      try {
        return transfers.firstWhere((transfer) => transfer.fileId == fileId);
      } catch (e) {
        return null;
      }
    }).value;
  }

  int getActiveTransfersCount() {
    return state.whenData((transfers) {
          return transfers.where((transfer) => transfer.state.isActive).length;
        }).value ??
        0;
  }

  double getTotalTransferProgress() {
    return state.whenData((transfers) {
          if (transfers.isEmpty) return 0.0;
          final totalBytes = transfers.fold<int>(
            0,
            (sum, t) => sum + t.totalBytes,
          );
          final transferredBytes = transfers.fold<int>(
            0,
            (sum, t) => sum + t.transferredBytes,
          );
          if (totalBytes == 0) return 0.0;
          return transferredBytes / totalBytes;
        }).value ??
        0.0;
  }
}

class TransferHistoryNotifier extends AsyncNotifier<List<TransferHistory>> {
  @override
  FutureOr<List<TransferHistory>> build() async {
    // Initialize from storage or return empty list
    return [];
  }

  Future<void> addHistoryEntry(TransferHistory entry) async {
    state = await AsyncValue.guard(() async {
      final current = await future;
      AppLogger.info('History entry added: ${entry.id}');
      return [entry, ...current];
    });
  }

  Future<void> clearHistory() async {
    state = await AsyncValue.guard(() async {
      AppLogger.info('Transfer history cleared');
      return [];
    });
  }

  Future<void> removeHistoryEntry(String entryId) async {
    state = await AsyncValue.guard(() async {
      final current = await future;
      AppLogger.info('History entry removed: $entryId');
      return current.where((entry) => entry.id != entryId).toList();
    });
  }

  List<TransferHistory> getHistoryByDevice(String deviceId) {
    return state.whenData((history) {
          return history.where((entry) => entry.deviceId == deviceId).toList();
        }).value ??
        [];
  }

  List<TransferHistory> getHistoryByDirection(TransferDirection direction) {
    return state.whenData((history) {
          return history
              .where((entry) => entry.direction == direction)
              .toList();
        }).value ??
        [];
  }

  List<TransferHistory> getHistoryByDateRange(
    DateTime startDate,
    DateTime endDate,
  ) {
    return state.whenData((history) {
          return history
              .where(
                (entry) =>
                    entry.timestamp.isAfter(startDate) &&
                    entry.timestamp.isBefore(endDate),
              )
              .toList();
        }).value ??
        [];
  }

  int getSuccessfulTransfersCount() {
    return state.whenData((history) {
          return history.where((entry) => entry.success).length;
        }).value ??
        0;
  }

  int getFailedTransfersCount() {
    return state.whenData((history) {
          return history.where((entry) => !entry.success).length;
        }).value ??
        0;
  }

  int getTotalBytesTransferred() {
    return state.whenData((history) {
          return history.fold<int>(0, (sum, entry) => sum + entry.fileSize);
        }).value ??
        0;
  }
}
