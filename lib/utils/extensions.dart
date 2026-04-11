import 'package:intl/intl.dart';

/// String extensions
extension StringExtensions on String {
  /// Format bytes to human-readable format
  static String formatBytes(int bytes) {
    if (bytes <= 0) return '0 B';
    const suffixes = ['B', 'KB', 'MB', 'GB', 'TB'];
    var i = (bytes.toString().length / 3).floor();
    return '${(bytes / pow(1024, i)).toStringAsFixed(2)} ${suffixes[i]}';
  }

  /// Format duration to human-readable format
  static String formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '$hours:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  /// Format speed (bytes per second)
  static String formatSpeed(double bytesPerSecond) {
    return '${formatBytes(bytesPerSecond.toInt())}/s';
  }

  /// Get file extension
  String get fileExtension {
    if (!contains('.')) return '';
    return split('.').last.toLowerCase();
  }

  /// Get file name without extension
  String get fileNameWithoutExtension {
    if (!contains('.')) return this;
    return substring(0, lastIndexOf('.'));
  }
}

/// DateTime extensions
extension DateTimeExtensions on DateTime {
  /// Format as relative time (e.g., "2 hours ago")
  String toRelativeTime() {
    final now = DateTime.now();
    final difference = now.difference(this);

    if (difference.inSeconds < 60) {
      return 'just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''} ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
    } else {
      return DateFormat('MMM d, yyyy').format(this);
    }
  }

  /// Format as time only
  String toTimeString() {
    return DateFormat('HH:mm').format(this);
  }

  /// Format as date only
  String toDateString() {
    return DateFormat('MMM d, yyyy').format(this);
  }

  /// Format as date and time
  String toDateTimeString() {
    return DateFormat('MMM d, yyyy HH:mm').format(this);
  }
}

/// Int extensions
extension IntExtensions on int {
  /// Convert to percentage string
  String toPercentageString() {
    return '$this%';
  }

  /// Check if number is positive
  bool get isPositive => this > 0;

  /// Check if number is negative
  bool get isNegative => this < 0;

  /// Check if number is zero
  bool get isZero => this == 0;
}

/// Double extensions
extension DoubleExtensions on double {
  /// Round to specific decimal places
  double roundToDecimals(int decimals) {
    final factor = pow(10, decimals);
    return (this * factor).round() / factor;
  }

  /// Convert to percentage string
  String toPercentageString({int decimals = 1}) {
    return '${roundToDecimals(decimals)}%';
  }
}

/// List extensions
extension ListExtensions<T> on List<T> {
  /// Get first element or null
  T? get firstOrNull => isEmpty ? null : first;

  /// Get last element or null
  T? get lastOrNull => isEmpty ? null : last;

  /// Check if list is not empty
  bool get isNotEmpty => length > 0;
}

/// Helper function for pow
double pow(double base, int exponent) {
  double result = 1;
  for (int i = 0; i < exponent; i++) {
    result *= base;
  }
  return result;
}
