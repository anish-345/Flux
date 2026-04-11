import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flux/models/file_metadata.dart';
import 'package:flux/utils/logger.dart';

/// Provider for managing active file transfers
final fileTransferProvider =
    StateNotifierProvider<FileTransferNotifier, List<TransferStatus>>((ref) {
      return FileTransferNotifier();
    });

/// Provider for getting transfer history
final transferHistoryProvider =
    StateNotifierProvider<TransferHistoryNotifier, List<TransferHistory>>((
      ref,
    ) {
      return TransferHistoryNotifier();
    });

/// Provider for getting active transfers only
final activeTransfersProvider = Provider<List<TransferStatus>>((ref) {
  final transfers = ref.watch(fileTransferProvider);
  return transfers.where((t) => t.state.isActive).toList();
});

/// Provider for getting completed transfers
final completedTransfersProvider = Provider<List<TransferStatus>>((ref) {
  final transfers = ref.watch(fileTransferProvider);
  return transfers.where((t) => t.state.isTerminal).toList();
});

/// Provider for getting total transfer progress
final totalTransferProgressProvider = Provider<double>((ref) {
  final transfers = ref.watch(fileTransferProvider);
  if (transfers.isEmpty) return 0.0;

  final totalBytes = transfers.fold<int>(0, (sum, t) => sum + t.totalBytes);
  final transferredBytes = transfers.fold<int>(
    0,
    (sum, t) => sum + t.transferredBytes,
  );

  if (totalBytes == 0) return 0.0;
  return transferredBytes / totalBytes;
});

class FileTransferNotifier extends StateNotifier<List<TransferStatus>> {
  FileTransferNotifier() : super([]);

  Future<void> addTransfer(TransferStatus transfer) async {
    try {
      state = [...state, transfer];
      AppLogger.info('Transfer added: ${transfer.fileId}');
    } catch (e) {
      AppLogger.error('Failed to add transfer', e);
      rethrow;
    }
  }

  Future<void> updateTransfer(
    String fileId,
    TransferStatus updatedTransfer,
  ) async {
    try {
      state = state.map((transfer) {
        if (transfer.fileId == fileId) {
          return updatedTransfer;
        }
        return transfer;
      }).toList();
      AppLogger.info('Transfer updated: $fileId');
    } catch (e) {
      AppLogger.error('Failed to update transfer', e);
      rethrow;
    }
  }

  Future<void> updateTransferProgress(
    String fileId,
    int transferredBytes,
    double speed,
    int remainingSeconds,
  ) async {
    try {
      state = state.map((transfer) {
        if (transfer.fileId == fileId) {
          return transfer.copyWith(
            transferredBytes: transferredBytes,
            speed: speed,
            remainingSeconds: remainingSeconds,
          );
        }
        return transfer;
      }).toList();
    } catch (e) {
      AppLogger.error('Failed to update transfer progress', e);
      rethrow;
    }
  }

  Future<void> pauseTransfer(String fileId) async {
    try {
      state = state.map((transfer) {
        if (transfer.fileId == fileId) {
          return transfer.copyWith(state: TransferState.paused);
        }
        return transfer;
      }).toList();
      AppLogger.info('Transfer paused: $fileId');
    } catch (e) {
      AppLogger.error('Failed to pause transfer', e);
      rethrow;
    }
  }

  Future<void> resumeTransfer(String fileId) async {
    try {
      state = state.map((transfer) {
        if (transfer.fileId == fileId) {
          return transfer.copyWith(state: TransferState.inProgress);
        }
        return transfer;
      }).toList();
      AppLogger.info('Transfer resumed: $fileId');
    } catch (e) {
      AppLogger.error('Failed to resume transfer', e);
      rethrow;
    }
  }

  Future<void> cancelTransfer(String fileId) async {
    try {
      state = state.map((transfer) {
        if (transfer.fileId == fileId) {
          return transfer.copyWith(state: TransferState.cancelled);
        }
        return transfer;
      }).toList();
      AppLogger.info('Transfer cancelled: $fileId');
    } catch (e) {
      AppLogger.error('Failed to cancel transfer', e);
      rethrow;
    }
  }

  Future<void> completeTransfer(String fileId) async {
    try {
      state = state.map((transfer) {
        if (transfer.fileId == fileId) {
          return transfer.copyWith(
            state: TransferState.completed,
            completedAt: DateTime.now(),
          );
        }
        return transfer;
      }).toList();
      AppLogger.info('Transfer completed: $fileId');
    } catch (e) {
      AppLogger.error('Failed to complete transfer', e);
      rethrow;
    }
  }

  Future<void> failTransfer(String fileId, String error) async {
    try {
      state = state.map((transfer) {
        if (transfer.fileId == fileId) {
          return transfer.copyWith(
            state: TransferState.failed,
            error: error,
            completedAt: DateTime.now(),
          );
        }
        return transfer;
      }).toList();
      AppLogger.info('Transfer failed: $fileId - $error');
    } catch (e) {
      AppLogger.error('Failed to mark transfer as failed', e);
      rethrow;
    }
  }

  Future<void> removeTransfer(String fileId) async {
    try {
      state = state.where((transfer) => transfer.fileId != fileId).toList();
      AppLogger.info('Transfer removed: $fileId');
    } catch (e) {
      AppLogger.error('Failed to remove transfer', e);
      rethrow;
    }
  }

  Future<void> clearCompletedTransfers() async {
    try {
      state = state.where((transfer) => !transfer.state.isTerminal).toList();
      AppLogger.info('Completed transfers cleared');
    } catch (e) {
      AppLogger.error('Failed to clear completed transfers', e);
      rethrow;
    }
  }

  TransferStatus? getTransferById(String fileId) {
    try {
      return state.firstWhere((transfer) => transfer.fileId == fileId);
    } catch (e) {
      return null;
    }
  }

  int getActiveTransfersCount() {
    return state.where((transfer) => transfer.state.isActive).length;
  }

  double getTotalTransferProgress() {
    if (state.isEmpty) return 0.0;
    final totalBytes = state.fold<int>(0, (sum, t) => sum + t.totalBytes);
    final transferredBytes = state.fold<int>(
      0,
      (sum, t) => sum + t.transferredBytes,
    );
    if (totalBytes == 0) return 0.0;
    return transferredBytes / totalBytes;
  }
}

class TransferHistoryNotifier extends StateNotifier<List<TransferHistory>> {
  TransferHistoryNotifier() : super([]);

  Future<void> addHistoryEntry(TransferHistory entry) async {
    try {
      state = [entry, ...state];
      AppLogger.info('History entry added: ${entry.id}');
    } catch (e) {
      AppLogger.error('Failed to add history entry', e);
      rethrow;
    }
  }

  Future<void> clearHistory() async {
    try {
      state = [];
      AppLogger.info('Transfer history cleared');
    } catch (e) {
      AppLogger.error('Failed to clear history', e);
      rethrow;
    }
  }

  Future<void> removeHistoryEntry(String entryId) async {
    try {
      state = state.where((entry) => entry.id != entryId).toList();
      AppLogger.info('History entry removed: $entryId');
    } catch (e) {
      AppLogger.error('Failed to remove history entry', e);
      rethrow;
    }
  }

  List<TransferHistory> getHistoryByDevice(String deviceId) {
    return state.where((entry) => entry.deviceId == deviceId).toList();
  }

  List<TransferHistory> getHistoryByDirection(TransferDirection direction) {
    return state.where((entry) => entry.direction == direction).toList();
  }

  List<TransferHistory> getHistoryByDateRange(
    DateTime startDate,
    DateTime endDate,
  ) {
    return state
        .where(
          (entry) =>
              entry.timestamp.isAfter(startDate) &&
              entry.timestamp.isBefore(endDate),
        )
        .toList();
  }

  int getSuccessfulTransfersCount() {
    return state.where((entry) => entry.success).length;
  }

  int getFailedTransfersCount() {
    return state.where((entry) => !entry.success).length;
  }

  int getTotalBytesTransferred() {
    return state.fold<int>(0, (sum, entry) => sum + entry.fileSize);
  }
}
