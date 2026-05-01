import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/transfer_queue_service.dart';
import '../models/queued_transfer.dart';

/// Provider for transfer queue service
final transferQueueServiceProvider = Provider((ref) {
  return TransferQueueService();
});

/// Provider for queue items
final transferQueueProvider =
    StateNotifierProvider<TransferQueueNotifier, List<QueuedTransfer>>((ref) {
      final service = ref.watch(transferQueueServiceProvider);
      return TransferQueueNotifier(service);
    });

/// Provider for pending transfers
final pendingTransfersProvider = Provider((ref) {
  final queue = ref.watch(transferQueueProvider);
  return queue.where((t) => t.isPending).toList();
});

/// Provider for in-progress transfers
final inProgressTransfersProvider = Provider((ref) {
  final queue = ref.watch(transferQueueProvider);
  return queue.where((t) => t.isInProgress).toList();
});

/// Provider for completed transfers
final completedTransfersProvider = Provider((ref) {
  final queue = ref.watch(transferQueueProvider);
  return queue.where((t) => t.isComplete).toList();
});

/// Provider for failed transfers
final failedTransfersProvider = Provider((ref) {
  final queue = ref.watch(transferQueueProvider);
  return queue.where((t) => t.isFailed).toList();
});

/// Provider for queue statistics
final queueStatsProvider = Provider((ref) {
  final service = ref.watch(transferQueueServiceProvider);
  return service.getStats();
});

/// State notifier for queue
class TransferQueueNotifier extends StateNotifier<List<QueuedTransfer>> {
  final TransferQueueService _service;

  TransferQueueNotifier(this._service) : super([]) {
    _initialize();
  }

  Future<void> _initialize() async {
    await _service.initialize();
    state = _service.queue;
    _service.addListener(_onQueueChanged);
  }

  void _onQueueChanged() {
    state = _service.queue;
  }

  Future<bool> addTransfer(QueuedTransfer transfer) async {
    return await _service.addTransfer(transfer);
  }

  Future<bool> removeTransfer(String transferId) async {
    return await _service.removeTransfer(transferId);
  }

  Future<bool> updateTransferStatus(
    String transferId,
    TransferStatus status, {
    int? transferredBytes,
    String? errorMessage,
  }) async {
    return await _service.updateTransferStatus(
      transferId,
      status,
      transferredBytes: transferredBytes,
      errorMessage: errorMessage,
    );
  }

  Future<bool> retryTransfer(String transferId) async {
    return await _service.retryTransfer(transferId);
  }

  Future<bool> pauseTransfer(String transferId) async {
    return await _service.pauseTransfer(transferId);
  }

  Future<bool> resumeTransfer(String transferId) async {
    return await _service.resumeTransfer(transferId);
  }

  Future<bool> cancelTransfer(String transferId) async {
    return await _service.cancelTransfer(transferId);
  }

  Future<void> clearCompleted() async {
    await _service.clearCompleted();
  }

  Future<void> clearFailed() async {
    await _service.clearFailed();
  }

  Future<void> clearAll() async {
    await _service.clearAll();
  }

  @override
  void dispose() {
    _service.removeListener(_onQueueChanged);
    super.dispose();
  }
}
