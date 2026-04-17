import 'dart:async';
import 'package:flux/models/transfer_progress.dart';
import 'package:flux/utils/logger.dart';

/// Service for tracking and calculating accurate transfer progress
class ProgressTrackingService {
  static final ProgressTrackingService _instance =
      ProgressTrackingService._internal();

  factory ProgressTrackingService() => _instance;
  ProgressTrackingService._internal();

  final Map<String, _TransferTracker> _trackers = {};
  final Map<String, StreamController<TransferProgress>> _progressStreams = {};

  /// Start tracking a transfer
  void startTracking(String fileId, int totalBytes) {
    _trackers[fileId] = _TransferTracker(
      fileId: fileId,
      totalBytes: totalBytes,
      startedAt: DateTime.now(),
    );

    _progressStreams[fileId] = StreamController<TransferProgress>.broadcast();
    AppLogger.info('Started tracking transfer: $fileId');
  }

  /// Update transfer progress
  void updateProgress(
    String fileId,
    int transferredBytes, {
    int? chunksTransferred,
    int? totalChunks,
  }) {
    final tracker = _trackers[fileId];
    if (tracker == null) {
      AppLogger.warning('Tracker not found for: $fileId');
      return;
    }

    tracker.updateProgress(
      transferredBytes,
      chunksTransferred: chunksTransferred,
      totalChunks: totalChunks,
    );

    final progress = _calculateProgress(tracker);
    _progressStreams[fileId]?.add(progress);
  }

  /// Get current progress for a transfer
  TransferProgress? getProgress(String fileId) {
    final tracker = _trackers[fileId];
    if (tracker == null) return null;
    return _calculateProgress(tracker);
  }

  /// Get progress stream for a transfer
  Stream<TransferProgress> getProgressStream(String fileId) {
    return _progressStreams[fileId]?.stream ?? Stream.empty();
  }

  /// Complete tracking for a transfer
  void completeTracking(String fileId) {
    _trackers.remove(fileId);
    _progressStreams[fileId]?.close();
    _progressStreams.remove(fileId);
    AppLogger.info('Completed tracking transfer: $fileId');
  }

  /// Cancel tracking for a transfer
  void cancelTracking(String fileId) {
    _trackers.remove(fileId);
    _progressStreams[fileId]?.close();
    _progressStreams.remove(fileId);
    AppLogger.info('Cancelled tracking transfer: $fileId');
  }

  /// Calculate accurate progress metrics
  TransferProgress _calculateProgress(_TransferTracker tracker) {
    final now = DateTime.now();
    final elapsedSeconds = now.difference(tracker.startedAt).inSeconds;

    // Calculate speed (bytes per second)
    double speed = 0.0;
    if (elapsedSeconds > 0) {
      speed = tracker.transferredBytes / elapsedSeconds;
    }

    // Calculate remaining time
    int remainingSeconds = 0;
    if (speed > 0) {
      final remainingBytes = tracker.totalBytes - tracker.transferredBytes;
      remainingSeconds = (remainingBytes / speed).toInt();
    }

    // Calculate accuracy based on consistency of speed measurements
    double accuracy = _calculateAccuracy(tracker);

    // Calculate chunk progress
    int chunksTransferred = tracker.chunksTransferred ?? 0;
    int totalChunks = tracker.totalChunks ?? 0;

    return TransferProgress(
      fileId: tracker.fileId,
      totalBytes: tracker.totalBytes,
      transferredBytes: tracker.transferredBytes,
      startedAt: tracker.startedAt,
      speed: speed,
      remainingSeconds: remainingSeconds,
      chunksTransferred: chunksTransferred,
      totalChunks: totalChunks,
      accuracy: accuracy,
      lastError: tracker.lastError,
    );
  }

  /// Calculate accuracy of progress estimation
  double _calculateAccuracy(_TransferTracker tracker) {
    if (tracker.speedHistory.isEmpty) return 0.5;

    // Calculate standard deviation of speed measurements
    final avgSpeed =
        tracker.speedHistory.reduce((a, b) => a + b) /
        tracker.speedHistory.length;

    if (avgSpeed == 0) return 0.5;

    final variance =
        tracker.speedHistory
            .map((speed) => (speed - avgSpeed) * (speed - avgSpeed))
            .reduce((a, b) => a + b) /
        tracker.speedHistory.length;

    final stdDev = variance.sqrt();
    final coefficientOfVariation = stdDev / avgSpeed;

    // Convert CV to accuracy (0.0 to 1.0)
    // Lower CV = higher accuracy
    final accuracy = (1.0 - coefficientOfVariation.clamp(0.0, 1.0));
    return accuracy.clamp(0.0, 1.0);
  }

  /// Get all active transfers
  List<String> getActiveTransfers() {
    return _trackers.keys.toList();
  }

  /// Get statistics for all transfers
  Map<String, dynamic> getStatistics() {
    final totalBytes = _trackers.values.fold<int>(
      0,
      (sum, tracker) => sum + tracker.totalBytes,
    );
    final transferredBytes = _trackers.values.fold<int>(
      0,
      (sum, tracker) => sum + tracker.transferredBytes,
    );
    final avgSpeed = _trackers.values.isEmpty
        ? 0.0
        : _trackers.values
                  .map((t) => _calculateProgress(t).speed)
                  .fold<double>(0.0, (a, b) => a + b) /
              _trackers.values.length;

    return {
      'activeTransfers': _trackers.length,
      'totalBytes': totalBytes,
      'transferredBytes': transferredBytes,
      'averageSpeed': avgSpeed,
      'overallProgress': totalBytes > 0 ? transferredBytes / totalBytes : 0.0,
    };
  }

  /// Clear all tracking data
  void clearAll() {
    for (final stream in _progressStreams.values) {
      stream.close();
    }
    _trackers.clear();
    _progressStreams.clear();
    AppLogger.info('Cleared all progress tracking data');
  }
}

/// Internal class for tracking individual transfer progress
class _TransferTracker {
  final String fileId;
  final int totalBytes;
  final DateTime startedAt;
  int transferredBytes = 0;
  int? chunksTransferred;
  int? totalChunks;
  String? lastError;
  final List<double> speedHistory = [];
  DateTime lastUpdate = DateTime.now();

  _TransferTracker({
    required this.fileId,
    required this.totalBytes,
    required this.startedAt,
  });

  void updateProgress(
    int newTransferredBytes, {
    int? chunksTransferred,
    int? totalChunks,
  }) {
    final now = DateTime.now();
    final timeDiff = now.difference(lastUpdate).inMilliseconds;

    // Calculate instantaneous speed
    if (timeDiff > 0) {
      final bytesDiff = newTransferredBytes - transferredBytes;
      final instantSpeed = (bytesDiff / timeDiff) * 1000; // bytes per second
      speedHistory.add(instantSpeed);

      // Keep only last 60 speed measurements for accuracy calculation
      if (speedHistory.length > 60) {
        speedHistory.removeAt(0);
      }
    }

    transferredBytes = newTransferredBytes;
    this.chunksTransferred = chunksTransferred;
    this.totalChunks = totalChunks;
    lastUpdate = now;
  }

  void recordError(String error) {
    lastError = error;
  }
}

/// Extension for calculating square root (for standard deviation)
extension on double {
  double sqrt() {
    return this < 0 ? 0 : _sqrt(this);
  }

  static double _sqrt(double x) {
    if (x == 0) return 0;
    var guess = x;
    var nextGuess = (guess + x / guess) / 2;
    while ((guess - nextGuess).abs() > 0.0001) {
      guess = nextGuess;
      nextGuess = (guess + x / guess) / 2;
    }
    return nextGuess;
  }
}
