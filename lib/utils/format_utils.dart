/// Utility functions for formatting data
class FormatUtils {
  /// Format bytes to human-readable size
  static String formatBytes(int bytes) {
    if (bytes <= 0) return '0 B';
    const suffixes = ['B', 'KB', 'MB', 'GB', 'TB'];
    var i = (bytes.toString().length / 3).floor();
    return '${(bytes / pow(1024, i)).toStringAsFixed(2)} ${suffixes[i]}';
  }

  /// Format duration in seconds to human-readable format
  static String formatDuration(int seconds) {
    if (seconds <= 0) return '0s';
    if (seconds < 60) return '${seconds}s';
    if (seconds < 3600) {
      final minutes = seconds ~/ 60;
      final secs = seconds % 60;
      return '${minutes}m ${secs}s';
    }
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    return '${hours}h ${minutes}m';
  }

  /// Format speed in bytes per second to human-readable format
  static String formatSpeed(double bytesPerSecond) {
    if (bytesPerSecond <= 0) return '0 B/s';
    const suffixes = ['B/s', 'KB/s', 'MB/s', 'GB/s'];
    var i = (bytesPerSecond.toString().length / 3).floor();
    return '${(bytesPerSecond / pow(1024, i)).toStringAsFixed(2)} ${suffixes[i]}';
  }

  /// Calculate power for formatting
  static double pow(int base, int exponent) {
    return base * (exponent > 0 ? pow(base, exponent - 1) : 1);
  }
}
