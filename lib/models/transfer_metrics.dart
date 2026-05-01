/// Metrics for tracking transfer performance
class TransferMetrics {
  final int totalBytes;
  final int transferredBytes;
  final DateTime startTime;
  DateTime? endTime;

  // Performance metrics
  int _chunkCount = 0;
  int _failedChunks = 0;
  int _retriedChunks = 0;

  // Speed tracking
  final List<_SpeedSample> _speedSamples = [];
  static const int _maxSpeedSamples = 60; // Keep last 60 samples

  TransferMetrics({
    required this.totalBytes,
    required this.transferredBytes,
    required this.startTime,
  });

  /// Get current transfer progress (0.0 to 1.0)
  double get progress => totalBytes > 0 ? transferredBytes / totalBytes : 0.0;

  /// Get percentage complete
  int get percentComplete => (progress * 100).toInt();

  /// Get elapsed time
  Duration get elapsedTime {
    final end = endTime ?? DateTime.now();
    return end.difference(startTime);
  }

  /// Get current transfer speed in bytes per second
  double get currentSpeed {
    if (_speedSamples.isEmpty) return 0;

    // Average speed from last 5 samples (last ~5 seconds)
    final recentSamples = _speedSamples.length > 5
        ? _speedSamples.sublist(_speedSamples.length - 5)
        : _speedSamples;

    final totalSpeed = recentSamples.fold<double>(
      0,
      (sum, sample) => sum + sample.bytesPerSecond,
    );

    return totalSpeed / recentSamples.length;
  }

  /// Get average transfer speed in bytes per second
  double get averageSpeed {
    final elapsed = elapsedTime.inMilliseconds;
    if (elapsed == 0) return 0;
    return (transferredBytes * 1000) / elapsed;
  }

  /// Get estimated time remaining
  Duration get estimatedTimeRemaining {
    final speed = currentSpeed;
    if (speed <= 0) return Duration.zero;

    final remainingBytes = totalBytes - transferredBytes;
    final remainingSeconds = remainingBytes / speed;

    return Duration(seconds: remainingSeconds.toInt());
  }

  /// Get human-readable speed string
  String get speedString {
    final speed = currentSpeed;
    if (speed < 1024) {
      return '${speed.toStringAsFixed(0)} B/s';
    } else if (speed < 1024 * 1024) {
      return '${(speed / 1024).toStringAsFixed(1)} KB/s';
    } else {
      return '${(speed / (1024 * 1024)).toStringAsFixed(1)} MB/s';
    }
  }

  /// Get human-readable ETA string
  String get etaString {
    final eta = estimatedTimeRemaining;
    if (eta.inSeconds < 60) {
      return '${eta.inSeconds}s';
    } else if (eta.inMinutes < 60) {
      return '${eta.inMinutes}m ${eta.inSeconds % 60}s';
    } else {
      return '${eta.inHours}h ${eta.inMinutes % 60}m';
    }
  }

  /// Record a speed sample
  void recordSpeedSample(int bytes, Duration duration) {
    if (duration.inMilliseconds == 0) return;

    final bytesPerSecond = (bytes * 1000) / duration.inMilliseconds;
    _speedSamples.add(_SpeedSample(bytesPerSecond, DateTime.now()));

    // Keep only recent samples
    if (_speedSamples.length > _maxSpeedSamples) {
      _speedSamples.removeAt(0);
    }
  }

  /// Record chunk transfer
  void recordChunkTransfer() {
    _chunkCount++;
  }

  /// Record failed chunk
  void recordFailedChunk() {
    _failedChunks++;
  }

  /// Record retried chunk
  void recordRetriedChunk() {
    _retriedChunks++;
  }

  /// Mark transfer as complete
  void markComplete() {
    endTime = DateTime.now();
  }

  /// Get transfer statistics
  Map<String, dynamic> getStats() {
    return {
      'totalBytes': totalBytes,
      'transferredBytes': transferredBytes,
      'progress': progress,
      'percentComplete': percentComplete,
      'elapsedTime': elapsedTime.inSeconds,
      'currentSpeed': currentSpeed,
      'averageSpeed': averageSpeed,
      'estimatedTimeRemaining': estimatedTimeRemaining.inSeconds,
      'chunkCount': _chunkCount,
      'failedChunks': _failedChunks,
      'retriedChunks': _retriedChunks,
      'successRate': _chunkCount > 0
          ? ((_chunkCount - _failedChunks) / _chunkCount * 100).toStringAsFixed(
              1,
            )
          : '100.0',
    };
  }
}

class _SpeedSample {
  final double bytesPerSecond;
  final DateTime timestamp;

  _SpeedSample(this.bytesPerSecond, this.timestamp);
}
