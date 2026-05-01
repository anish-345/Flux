import 'dart:async';
import 'dart:math';
import '../models/transfer_metrics.dart';

/// Service for optimizing file transfers
class TransferOptimizerService {
  // Chunk size configuration
  static const int minChunkSize = 64 * 1024; // 64 KB
  static const int maxChunkSize = 2 * 1024 * 1024; // 2 MB
  static const int defaultChunkSize = 256 * 1024; // 256 KB

  // Parallel transfer configuration
  static const int minParallelChunks = 2;
  static const int maxParallelChunks = 8;
  static const int defaultParallelChunks = 4;

  // Network quality thresholds (bytes per second)
  static const int excellentNetworkSpeed = 5 * 1024 * 1024; // 5 MB/s
  static const int goodNetworkSpeed = 1 * 1024 * 1024; // 1 MB/s
  static const int fairNetworkSpeed = 256 * 1024; // 256 KB/s

  // Adaptive sizing configuration
  static const Duration adaptiveCheckInterval = Duration(seconds: 2);
  static const double speedIncreaseThreshold = 1.2; // 20% faster
  static const double speedDecreaseThreshold = 0.8; // 20% slower

  late TransferMetrics _metrics;
  late int _currentChunkSize;
  late int _currentParallelChunks;

  Timer? _adaptiveTimer;
  bool _isTransferring = false;

  TransferOptimizerService() {
    _currentChunkSize = defaultChunkSize;
    _currentParallelChunks = defaultParallelChunks;
  }

  /// Initialize transfer optimization
  void initializeTransfer(int totalBytes) {
    _metrics = TransferMetrics(
      totalBytes: totalBytes,
      transferredBytes: 0,
      startTime: DateTime.now(),
    );
    _isTransferring = true;
    _startAdaptiveOptimization();
  }

  /// Get current chunk size
  int get chunkSize => _currentChunkSize;

  /// Get current number of parallel chunks
  int get parallelChunks => _currentParallelChunks;

  /// Get transfer metrics
  TransferMetrics get metrics => _metrics;

  /// Update transferred bytes
  void updateTransferredBytes(int bytes, Duration duration) {
    _metrics = TransferMetrics(
      totalBytes: _metrics.totalBytes,
      transferredBytes: bytes,
      startTime: _metrics.startTime,
    );
    _metrics.recordSpeedSample(bytes, duration);
  }

  /// Record chunk transfer
  void recordChunkTransfer() {
    _metrics.recordChunkTransfer();
  }

  /// Record failed chunk
  void recordFailedChunk() {
    _metrics.recordFailedChunk();
  }

  /// Record retried chunk
  void recordRetriedChunk() {
    _metrics.recordRetriedChunk();
  }

  /// Finalize transfer
  void finalizeTransfer() {
    _metrics.markComplete();
    _isTransferring = false;
    _adaptiveTimer?.cancel();
  }

  /// Start adaptive optimization
  void _startAdaptiveOptimization() {
    _adaptiveTimer = Timer.periodic(adaptiveCheckInterval, (_) {
      if (!_isTransferring) return;

      _optimizeChunkSize();
      _optimizeParallelChunks();
    });
  }

  /// Optimize chunk size based on network speed
  void _optimizeChunkSize() {
    final currentSpeed = _metrics.currentSpeed;

    if (currentSpeed == 0) return;

    // Determine optimal chunk size based on network speed
    int optimalSize;

    if (currentSpeed >= excellentNetworkSpeed) {
      // Excellent network: use larger chunks
      optimalSize = maxChunkSize;
    } else if (currentSpeed >= goodNetworkSpeed) {
      // Good network: use medium-large chunks
      optimalSize = 1024 * 1024; // 1 MB
    } else if (currentSpeed >= fairNetworkSpeed) {
      // Fair network: use medium chunks
      optimalSize = 512 * 1024; // 512 KB
    } else {
      // Poor network: use smaller chunks
      optimalSize = minChunkSize;
    }

    // Apply hysteresis to avoid constant changes
    final speedRatio = optimalSize / _currentChunkSize;

    if (speedRatio >= speedIncreaseThreshold) {
      _currentChunkSize = min(optimalSize, maxChunkSize);
    } else if (speedRatio <= speedDecreaseThreshold) {
      _currentChunkSize = max(optimalSize, minChunkSize);
    }
  }

  /// Optimize number of parallel chunks
  void _optimizeParallelChunks() {
    final currentSpeed = _metrics.currentSpeed;

    if (currentSpeed == 0) return;

    // Determine optimal parallel chunks based on network speed
    int optimalParallel;

    if (currentSpeed >= excellentNetworkSpeed) {
      // Excellent network: use maximum parallelism
      optimalParallel = maxParallelChunks;
    } else if (currentSpeed >= goodNetworkSpeed) {
      // Good network: use high parallelism
      optimalParallel = 6;
    } else if (currentSpeed >= fairNetworkSpeed) {
      // Fair network: use medium parallelism
      optimalParallel = 4;
    } else {
      // Poor network: use low parallelism
      optimalParallel = minParallelChunks;
    }

    // Apply hysteresis
    if ((optimalParallel - _currentParallelChunks).abs() >= 2) {
      _currentParallelChunks = optimalParallel;
    }
  }

  /// Get network quality assessment
  NetworkQuality assessNetworkQuality() {
    final speed = _metrics.currentSpeed;

    if (speed >= excellentNetworkSpeed) {
      return NetworkQuality.excellent;
    } else if (speed >= goodNetworkSpeed) {
      return NetworkQuality.good;
    } else if (speed >= fairNetworkSpeed) {
      return NetworkQuality.fair;
    } else {
      return NetworkQuality.poor;
    }
  }

  /// Get recommended retry delay based on network quality
  Duration getRetryDelay(int attemptNumber) {
    final quality = assessNetworkQuality();

    // Base delay: 1 second * attempt number
    int baseDelaySeconds = attemptNumber;

    // Adjust based on network quality
    final multiplier = switch (quality) {
      NetworkQuality.excellent => 1,
      NetworkQuality.good => 2,
      NetworkQuality.fair => 3,
      NetworkQuality.poor => 5,
    };

    return Duration(seconds: baseDelaySeconds * multiplier);
  }

  /// Dispose resources
  void dispose() {
    _adaptiveTimer?.cancel();
    _isTransferring = false;
  }
}

/// Network quality assessment
enum NetworkQuality { excellent, good, fair, poor }
