import 'dart:async';

/// Monitor app performance metrics
class PerformanceMonitor {
  static const Duration _sampleInterval = Duration(seconds: 1);
  static const int _maxSamples = 60; // Keep 1 minute of data

  final List<_PerformanceSample> _samples = [];
  Timer? _sampleTimer;

  int _frameCount = 0;
  int _lastFrameCount = 0;

  /// Start monitoring
  void start() {
    _sampleTimer = Timer.periodic(_sampleInterval, (_) {
      _recordSample();
    });
  }

  /// Stop monitoring
  void stop() {
    _sampleTimer?.cancel();
  }

  /// Record frame
  void recordFrame() {
    _frameCount++;
  }

  /// Record sample
  void _recordSample() {
    final fps = _frameCount - _lastFrameCount;
    _lastFrameCount = _frameCount;

    _samples.add(_PerformanceSample(fps: fps, timestamp: DateTime.now()));

    // Keep only recent samples
    if (_samples.length > _maxSamples) {
      _samples.removeAt(0);
    }
  }

  /// Get average FPS
  double get averageFps {
    if (_samples.isEmpty) return 0;
    final total = _samples.fold<int>(0, (sum, s) => sum + s.fps);
    return total / _samples.length;
  }

  /// Get minimum FPS
  int get minFps {
    if (_samples.isEmpty) return 0;
    return _samples.map((s) => s.fps).reduce((a, b) => a < b ? a : b);
  }

  /// Get maximum FPS
  int get maxFps {
    if (_samples.isEmpty) return 0;
    return _samples.map((s) => s.fps).reduce((a, b) => a > b ? a : b);
  }

  /// Get performance report
  PerformanceReport getReport() {
    return PerformanceReport(
      averageFps: averageFps,
      minFps: minFps,
      maxFps: maxFps,
      sampleCount: _samples.length,
    );
  }
}

class _PerformanceSample {
  final int fps;
  final DateTime timestamp;

  _PerformanceSample({required this.fps, required this.timestamp});
}

class PerformanceReport {
  final double averageFps;
  final int minFps;
  final int maxFps;
  final int sampleCount;

  PerformanceReport({
    required this.averageFps,
    required this.minFps,
    required this.maxFps,
    required this.sampleCount,
  });

  /// Check if performance is good
  bool get isGood => averageFps >= 50;

  /// Check if performance is acceptable
  bool get isAcceptable => averageFps >= 30;

  /// Check if performance is poor
  bool get isPoor => averageFps < 30;

  @override
  String toString() {
    return 'PerformanceReport(avg: ${averageFps.toStringAsFixed(1)} fps, '
        'min: $minFps fps, max: $maxFps fps)';
  }
}
