# Feature 3: Offline Mode with Transfer Queue

**Estimated Time:** 10 hours  
**Priority:** 🔴 Important Feature (implement third)  
**Status:** Ready for Implementation

---

## 📋 Overview

This feature allows users to queue file transfers when offline and automatically sync them when the device comes back online. It provides a seamless experience even with intermittent connectivity.

### User Experience

**Before (Current):**
```
User: "I want to send this file"
App: "No connection available"
User: "I'll try again later"
(User has to manually retry)
```

**After (Offline Mode):**
```
User: "I want to send this file"
App: "Queued for transfer (will send when online)"
(App automatically sends when connection returns)
```

---

## 🎯 Implementation Goals

1. ✅ Queue transfers when offline
2. ✅ Persist queue to local storage
3. ✅ Auto-sync when online
4. ✅ Show queue status in UI
5. ✅ Allow queue management (pause, resume, cancel)
6. ✅ Handle queue conflicts

---

## 📁 Files to Create

### 1. `lib/models/queued_transfer.dart` (NEW)

```dart
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
  })  : id = id ?? const Uuid().v4(),
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
enum TransferDirection {
  send,
  receive,
}

/// Transfer status
enum TransferStatus {
  pending,
  inProgress,
  completed,
  failed,
  cancelled,
  paused,
}
```

### 2. `lib/services/transfer_queue_service.dart` (NEW)

```dart
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
        decoded.map((item) => QueuedTransfer.fromJson(item as Map<String, dynamic>)),
      );
    } catch (e) {
      debugPrint('Error loading queue: $e');
      _queue.clear();
    }
  }
  
  /// Save queue to storage
  Future<void> _saveQueue() async {
    try {
      final queueJson = jsonEncode(
        _queue.map((t) => t.toJson()).toList(),
      );
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
```

### 3. `lib/providers/transfer_queue_provider.dart` (NEW)

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/transfer_queue_service.dart';
import '../models/queued_transfer.dart';

/// Provider for transfer queue service
final transferQueueServiceProvider = Provider((ref) {
  return TransferQueueService();
});

/// Provider for queue items
final transferQueueProvider = StateNotifierProvider<
    TransferQueueNotifier,
    List<QueuedTransfer>>((ref) {
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
```

### 4. `lib/screens/transfer_queue_screen.dart` (NEW)

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/queued_transfer.dart';
import '../providers/transfer_queue_provider.dart';
import '../utils/error_mapper.dart';

/// Screen for managing transfer queue
class TransferQueueScreen extends ConsumerWidget {
  const TransferQueueScreen({Key? key}) : super(key: key);
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final queue = ref.watch(transferQueueProvider);
    final stats = ref.watch(queueStatsProvider);
    
    if (queue.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Transfer Queue')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.inbox,
                size: 64,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 16),
              Text(
                'No transfers queued',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                'Transfers will appear here when offline',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      );
    }
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Transfer Queue'),
        subtitle: Text('${queue.length} transfers'),
        actions: [
          if (queue.isNotEmpty)
            PopupMenuButton(
              itemBuilder: (context) => [
                PopupMenuItem(
                  child: const Text('Clear Completed'),
                  onTap: () => ref.read(transferQueueProvider.notifier).clearCompleted(),
                ),
                PopupMenuItem(
                  child: const Text('Clear Failed'),
                  onTap: () => ref.read(transferQueueProvider.notifier).clearFailed(),
                ),
                PopupMenuItem(
                  child: const Text('Clear All'),
                  onTap: () => ref.read(transferQueueProvider.notifier).clearAll(),
                ),
              ],
            ),
        ],
      ),
      body: ListView.builder(
        itemCount: queue.length,
        itemBuilder: (context, index) {
          final transfer = queue[index];
          return _TransferQueueItem(transfer: transfer);
        },
      ),
    );
  }
}

/// Individual queue item widget
class _TransferQueueItem extends ConsumerWidget {
  final QueuedTransfer transfer;
  
  const _TransferQueueItem({required this.transfer});
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Icon(
                  transfer.direction == TransferDirection.send
                      ? Icons.upload
                      : Icons.download,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        transfer.deviceName,
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      Text(
                        transfer.filePath.split('/').last,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                _StatusBadge(status: transfer.status),
              ],
            ),
            const SizedBox(height: 12),
            
            // Progress bar
            if (transfer.isInProgress) ...[
              LinearProgressIndicator(value: transfer.progress),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${transfer.percentComplete}%',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  Text(
                    '${transfer.transferredBytes ?? 0} / ${transfer.fileSize} bytes',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
            
            // Error message
            if (transfer.isFailed && transfer.errorMessage != null) ...[
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  transfer.errorMessage!,
                  style: TextStyle(
                    color: Colors.red[700],
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
            
            // Actions
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (transfer.isPending || transfer.isPaused)
                  TextButton(
                    onPressed: () => ref
                        .read(transferQueueProvider.notifier)
                        .resumeTransfer(transfer.id),
                    child: const Text('Resume'),
                  ),
                if (transfer.isInProgress)
                  TextButton(
                    onPressed: () => ref
                        .read(transferQueueProvider.notifier)
                        .pauseTransfer(transfer.id),
                    child: const Text('Pause'),
                  ),
                if (transfer.isFailed && transfer.canRetry)
                  TextButton(
                    onPressed: () => ref
                        .read(transferQueueProvider.notifier)
                        .retryTransfer(transfer.id),
                    child: const Text('Retry'),
                  ),
                TextButton(
                  onPressed: () => ref
                      .read(transferQueueProvider.notifier)
                      .removeTransfer(transfer.id),
                  child: const Text('Remove'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Status badge widget
class _StatusBadge extends StatelessWidget {
  final TransferStatus status;
  
  const _StatusBadge({required this.status});
  
  @override
  Widget build(BuildContext context) {
    final (color, label) = switch (status) {
      TransferStatus.pending => (Colors.blue, 'Pending'),
      TransferStatus.inProgress => (Colors.orange, 'In Progress'),
      TransferStatus.completed => (Colors.green, 'Completed'),
      TransferStatus.failed => (Colors.red, 'Failed'),
      TransferStatus.cancelled => (Colors.grey, 'Cancelled'),
      TransferStatus.paused => (Colors.amber, 'Paused'),
    };
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
```

---

## 🔧 Integration Steps

### Step 1: Add Connectivity Monitoring

```dart
// In main.dart or a connectivity service

import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectivityService {
  final Connectivity _connectivity = Connectivity();
  
  Stream<bool> get isOnlineStream {
    return _connectivity.onConnectivityChanged.map((result) {
      return result != ConnectivityResult.none;
    });
  }
  
  Future<bool> get isOnline async {
    final result = await _connectivity.checkConnectivity();
    return result != ConnectivityResult.none;
  }
}
```

### Step 2: Auto-Sync When Online

```dart
// In a service or provider

class QueueSyncService {
  final TransferQueueService _queueService;
  final ConnectivityService _connectivityService;
  
  void startAutoSync() {
    _connectivityService.isOnlineStream.listen((isOnline) {
      if (isOnline) {
        _syncQueue();
      }
    });
  }
  
  Future<void> _syncQueue() async {
    final pending = _queueService.pendingTransfers;
    for (final transfer in pending) {
      await _processTransfer(transfer);
    }
  }
  
  Future<void> _processTransfer(QueuedTransfer transfer) async {
    // Update status to in-progress
    await _queueService.updateTransferStatus(
      transfer.id,
      TransferStatus.inProgress,
    );
    
    try {
      // Perform actual transfer
      // ...
      
      // Mark as completed
      await _queueService.updateTransferStatus(
        transfer.id,
        TransferStatus.completed,
      );
    } catch (e) {
      // Mark as failed
      await _queueService.updateTransferStatus(
        transfer.id,
        TransferStatus.failed,
        errorMessage: e.toString(),
      );
    }
  }
}
```

### Step 3: Update pubspec.yaml

```yaml
dependencies:
  connectivity_plus: ^5.0.0
  shared_preferences: ^2.2.0
```

---

## 📊 Queue Management Features

| Feature | Status |
|---------|--------|
| Queue persistence | ✅ |
| Auto-sync | ✅ |
| Pause/Resume | ✅ |
| Retry failed | ✅ |
| Clear completed | ✅ |
| Queue statistics | ✅ |
| Max queue size | ✅ |

---

## 🧪 Testing Scenarios

### Test 1: Queue While Offline
```
1. Disable WiFi
2. Try to send file
3. Verify transfer is queued
4. Verify queue persists after restart
```

### Test 2: Auto-Sync
```
1. Queue transfer while offline
2. Enable WiFi
3. Verify transfer starts automatically
4. Verify transfer completes
```

### Test 3: Retry Failed
```
1. Queue transfer
2. Simulate network failure
3. Verify transfer fails
4. Click Retry
5. Verify transfer retries
```

---

## 💡 Key Benefits

✅ **Seamless Offline** - Queue transfers when offline  
✅ **Auto-Sync** - Automatically sync when online  
✅ **Persistent** - Queue survives app restart  
✅ **Manageable** - Pause, resume, retry, cancel  
✅ **Transparent** - Works in background  

---

**Next:** After implementing this feature, move to Feature 4 (Security Features)
