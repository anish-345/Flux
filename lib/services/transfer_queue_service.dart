import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/queued_transfer.dart';

/// Service for managing transfer queue
class TransferQueueService extends ChangeNotifier {
  static const String _queueKey = 'transfer_queue';
  static const int _maxQueueSize = 100;

  late SharedPreferences _prefs;
  final List<QueuedTransfer> _queue = [];

  bool _isInitialized = false;

  /// Get queue items
  List<QueuedTransfer> get queue => List.unmodifiable(_queue);

  /// Get pending transfers
  List<QueuedTransfer> get pendingTransfers =>
      _queue.where((t) => t.isPending).toList();

  /// Get in-progress transfers
  List<QueuedTransfer> get inProgressTransfers =>
      _queue.where((t) => t.isInProgress).toList();

  /// Get completed transfers
  List<QueuedTransfer> get completedTransfers =>
      _queue.where((t) => t.isComplete).toList();

  /// Get failed transfers
  List<QueuedTransfer> get failedTransfers =>
      _queue.where((t) => t.isFailed).toList();

  /// Get queue size
  int get queueSize => _queue.length;

  /// Check if queue is empty
  bool get isEmpty => _queue.isEmpty;

  /// Check if queue is full
  bool get isFull => _queue.length >= _maxQueueSize;

  /// Initialize service
  Future<void> initialize() async {
    if (_isInitialized) return;

    _prefs = await SharedPreferences.getInstance();
    await _loadQueue();
    _isInitialized = true;
  }

  /// Add transfer to queue
  Future<bool> addTransfer(QueuedTransfer transfer) async {
    if (isFull) {
      return false; // Queue is full
    }

    // Check if transfer already exists
    if (_queue.any((t) => t.id == transfer.id)) {
      return false; // Transfer already in queue
    }

    _queue.add(transfer);
    await _saveQueue();
    notifyListeners();

    return true;
  }

  /// Remove transfer from queue
  Future<bool> removeTransfer(String transferId) async {
    final index = _queue.indexWhere((t) => t.id == transferId);
    if (index == -1) {
      return false; // Transfer not found
    }

    _queue.removeAt(index);
    await _saveQueue();
    notifyListeners();

    return true;
  }

  /// Update transfer status
  Future<bool> updateTransferStatus(
    String transferId,
    TransferStatus status, {
    int? transferredBytes,
    String? errorMessage,
  }) async {
    final index = _queue.indexWhere((t) => t.id == transferId);
    if (index == -1) {
      return false; // Transfer not found
    }

    final transfer = _queue[index];
    _queue[index] = transfer.copyWith(
      status: status,
      transferredBytes: transferredBytes ?? transfer.transferredBytes,
      errorMessage: errorMessage ?? transfer.errorMessage,
    );

    await _saveQueue();
    notifyListeners();

    return true;
  }

  /// Retry failed transfer
  Future<bool> retryTransfer(String transferId) async {
    final index = _queue.indexWhere((t) => t.id == transferId);
    if (index == -1) {
      return false; // Transfer not found
    }

    final transfer = _queue[index];
    if (!transfer.canRetry) {
      return false; // Cannot retry
    }

    _queue[index] = transfer.copyWith(
      status: TransferStatus.pending,
      retryCount: transfer.retryCount + 1,
      lastRetryAt: DateTime.now(),
      errorMessage: null,
    );

    await _saveQueue();
    notifyListeners();

    return true;
  }

  /// Pause transfer
  Future<bool> pauseTransfer(String transferId) async {
    final index = _queue.indexWhere((t) => t.id == transferId);
    if (index == -1) {
      return false; // Transfer not found
    }

    final transfer = _queue[index];
    _queue[index] = transfer.copyWith(status: TransferStatus.paused);

    await _saveQueue();
    notifyListeners();

    return true;
  }

  /// Resume transfer
  Future<bool> resumeTransfer(String transferId) async {
    final index = _queue.indexWhere((t) => t.id == transferId);
    if (index == -1) {
      return false; // Transfer not found
    }

    final transfer = _queue[index];
    _queue[index] = transfer.copyWith(status: TransferStatus.pending);

    await _saveQueue();
    notifyListeners();

    return true;
  }

  /// Cancel transfer
  Future<bool> cancelTransfer(String transferId) async {
    final index = _queue.indexWhere((t) => t.id == transferId);
    if (index == -1) {
      return false; // Transfer not found
    }

    final transfer = _queue[index];
    _queue[index] = transfer.copyWith(status: TransferStatus.cancelled);

    await _saveQueue();
    notifyListeners();

    return true;
  }

  /// Clear completed transfers
  Future<void> clearCompleted() async {
    _queue.removeWhere((t) => t.isComplete);
    await _saveQueue();
    notifyListeners();
  }

  /// Clear failed transfers
  Future<void> clearFailed() async {
    _queue.removeWhere((t) => t.isFailed);
    await _saveQueue();
    notifyListeners();
  }

  /// Clear all transfers
  Future<void> clearAll() async {
    _queue.clear();
    await _saveQueue();
    notifyListeners();
  }

  /// Get transfer by ID
  QueuedTransfer? getTransfer(String transferId) {
    try {
      return _queue.firstWhere((t) => t.id == transferId);
    } catch (e) {
      return null;
    }
  }

  /// Get transfers for device
  List<QueuedTransfer> getTransfersForDevice(String deviceId) {
    return _queue.where((t) => t.deviceId == deviceId).toList();
  }

  /// Load queue from storage
  Future<void> _loadQueue() async {
    try {
      final queueJson = _prefs.getString(_queueKey);
      if (queueJson == null) {
        _queue.clear();
        return;
      }

      final List<dynamic> decoded = jsonDecode(queueJson);
      _queue.clear();
      _queue.addAll(
        decoded.map(
          (item) => QueuedTransfer.fromJson(item as Map<String, dynamic>),
        ),
      );
    } catch (e) {
      debugPrint('Error loading queue: $e');
      _queue.clear();
    }
  }

  /// Save queue to storage
  Future<void> _saveQueue() async {
    try {
      final queueJson = jsonEncode(_queue.map((t) => t.toJson()).toList());
      await _prefs.setString(_queueKey, queueJson);
    } catch (e) {
      debugPrint('Error saving queue: $e');
    }
  }

  /// Get queue statistics
  Map<String, dynamic> getStats() {
    return {
      'totalItems': _queue.length,
      'pending': pendingTransfers.length,
      'inProgress': inProgressTransfers.length,
      'completed': completedTransfers.length,
      'failed': failedTransfers.length,
      'totalSize': _queue.fold<int>(0, (sum, t) => sum + t.fileSize),
      'transferredSize': _queue.fold<int>(
        0,
        (sum, t) => sum + (t.transferredBytes ?? 0),
      ),
    };
  }
}
