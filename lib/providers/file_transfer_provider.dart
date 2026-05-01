import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flux/models/file_metadata.dart';
import 'package:flux/utils/logger.dart';

/// Provider for managing active file transfers with proper async handling
/// Uses Map for O(1) updates instead of O(N) list operations
final fileTransferProvider =
    AsyncNotifierProvider<FileTransferNotifier, Map<String, TransferStatus>>(
      FileTransferNotifier.new,
    );

/// Provider for getting transfer history
final transferHistoryProvider =
    AsyncNotifierProvider<TransferHistoryNotifier, List<TransferHistory>>(
      TransferHistoryNotifier.new,
    );

/// Provider for getting active transfers only
final activeTransfersProvider = Provider<AsyncValue<List<TransferStatus>>>((ref) {
  final transfers = ref.watch(fileTransferProvider);
  return transfers.whenData(
    (map) => map.values.where((t) => t.state.isActive).toList(),
  );
});

/// Provider for getting completed transfers
final completedTransfersProvider = Provider<AsyncValue<List<TransferStatus>>>((ref) {
  final transfers = ref.watch(fileTransferProvider);
  return transfers.whenData(
    (map) => map.values.where((t) => t.state.isTerminal).toList(),
  );
});

/// Provider for getting total transfer progress
final totalTransferProgressProvider = Provider<double>((ref) {
  final transfers = ref.watch(fileTransferProvider);

  return transfers.when(
    data: (map) {
      if (map.isEmpty) return 0.0;
      final totalBytes = map.values.fold<int>(0, (sum, t) => sum + t.totalBytes);
      final transferredBytes = map.values.fold<int>(
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

class FileTransferNotifier extends AsyncNotifier<Map<String, TransferStatus>> {
  @override
  FutureOr<Map<String, TransferStatus>> build() async {
    // Initialize from storage or return empty map
    return {};
  }

  Future<void> addTransfer(TransferStatus transfer) async {
    state = await AsyncValue.guard(() async {
      final current = await future;
      AppLogger.info('Transfer added: ${transfer.fileId}');
      return {...current, transfer.fileId: transfer};
    });
  }

  Future<void> updateTransfer(
    String fileId,
    TransferStatus updatedTransfer,
  ) async {
    state = await AsyncValue.guard(() async {
      final current = await future;
      AppLogger.info('Transfer updated: $fileId');
      if (current.containsKey(fileId)) {
        return {...current, fileId: updatedTransfer};
      }
      return current;
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
      final transfer = current[fileId];
      if (transfer != null) {
        return {...current, fileId: transfer.copyWith(
          transferredBytes: transferredBytes,
          speed: speed,
          remainingSeconds: remainingSeconds,
        )};
      }
      return current;
    });
  }

  Future<void> pauseTransfer(String fileId) async {
    state = await AsyncValue.guard(() async {
      final current = await future;
      AppLogger.info('Transfer paused: $fileId');
      final transfer = current[fileId];
      if (transfer != null) {
        return {...current, fileId: transfer.copyWith(state: TransferState.paused)};
      }
      return current;
    });
  }

  Future<void> resumeTransfer(String fileId) async {
    state = await AsyncValue.guard(() async {
      final current = await future;
      AppLogger.info('Transfer resumed: $fileId');
      final transfer = current[fileId];
      if (transfer != null) {
        return {...current, fileId: transfer.copyWith(state: TransferState.inProgress)};
      }
      return current;
    });
  }

  Future<void> cancelTransfer(String fileId) async {
    state = await AsyncValue.guard(() async {
      final current = await future;
      AppLogger.info('Transfer cancelled: $fileId');
      final transfer = current[fileId];
      if (transfer != null) {
        return {...current, fileId: transfer.copyWith(state: TransferState.cancelled)};
      }
      return current;
    });
  }

  Future<void> completeTransfer(String fileId) async {
    state = await AsyncValue.guard(() async {
      final current = await future;
      AppLogger.info('Transfer completed: $fileId');
      final transfer = current[fileId];
      if (transfer != null) {
        return {...current, fileId: transfer.copyWith(
          state: TransferState.completed,
          completedAt: DateTime.now(),
        )};
      }
      return current;
    });
  }

  Future<void> failTransfer(String fileId, String error) async {
    state = await AsyncValue.guard(() async {
      final current = await future;
      AppLogger.info('Transfer failed: $fileId - $error');
      final transfer = current[fileId];
      if (transfer != null) {
        return {...current, fileId: transfer.copyWith(
          state: TransferState.failed,
          error: error,
          completedAt: DateTime.now(),
        )};
      }
      return current;
    });
  }

  Future<void> removeTransfer(String fileId) async {
    state = await AsyncValue.guard(() async {
      final current = await future;
      AppLogger.info('Transfer removed: $fileId');
      final newMap = Map<String, TransferStatus>.from(current);
      newMap.remove(fileId);
      return newMap;
    });
  }

  Future<void> clearCompletedTransfers() async {
    state = await AsyncValue.guard(() async {
      final current = await future;
      AppLogger.info('Completed transfers cleared');
      final newMap = Map<String, TransferStatus>.from(current);
      newMap.removeWhere((key, transfer) => transfer.state.isTerminal);
      return newMap;
    });
  }

  TransferStatus? getTransferById(String fileId) {
    return state.whenData((transfers) {
      return transfers[fileId];
    }).value;
  }

  int getActiveTransfersCount() {
    return state.whenData((transfers) {
          return transfers.values.where((transfer) => transfer.state.isActive).length;
        }).value ??
        0;
  }

  double getTotalTransferProgress() {
    return state.whenData((transfers) {
          if (transfers.isEmpty) return 0.0;
          final totalBytes = transfers.values.fold<int>(
            0,
            (sum, t) => sum + t.totalBytes,
          );
          final transferredBytes = transfers.values.fold<int>(
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
