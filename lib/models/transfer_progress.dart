import 'package:freezed_annotation/freezed_annotation.dart';

part 'transfer_progress.freezed.dart';
part 'transfer_progress.g.dart';

/// Detailed progress information for a transfer
@freezed
class TransferProgress with _$TransferProgress {
  const factory TransferProgress({
    required String fileId,
    required int totalBytes,
    required int transferredBytes,
    required DateTime startedAt,
    required double speed, // bytes per second
    required int remainingSeconds,
    @Default(0) int chunksTransferred,
    @Default(0) int totalChunks,
    @Default(0.0) double accuracy, // 0.0 to 1.0 - confidence in progress
    String? lastError,
  }) = _TransferProgress;

  factory TransferProgress.fromJson(Map<String, dynamic> json) =>
      _$TransferProgressFromJson(json);
}

/// Extension methods for TransferProgress
extension TransferProgressExtension on TransferProgress {
  /// Calculate progress percentage (0.0 to 1.0)
  double get progressPercentage {
    if (totalBytes <= 0) return 0.0;
    return (transferredBytes / totalBytes).clamp(0.0, 1.0);
  }

  /// Calculate progress percentage as integer (0 to 100)
  int get progressPercentageInt {
    return (progressPercentage * 100).toInt();
  }

  /// Calculate elapsed time
  Duration get elapsedTime {
    return DateTime.now().difference(startedAt);
  }

  /// Calculate remaining time
  Duration get remainingTime {
    return Duration(seconds: remainingSeconds);
  }

  /// Calculate average speed
  double get averageSpeed {
    final elapsedSeconds = elapsedTime.inSeconds;
    if (elapsedSeconds <= 0) return 0.0;
    return transferredBytes / elapsedSeconds;
  }

  /// Get remaining bytes
  int get remainingBytes {
    return (totalBytes - transferredBytes).clamp(0, totalBytes);
  }

  /// Check if transfer is stalled (no progress for 30 seconds)
  bool get isStalled {
    if (speed <= 0) return true;
    return remainingSeconds > 300; // More than 5 minutes remaining
  }

  /// Get formatted progress string
  String get formattedProgress {
    final transferred = _formatBytes(transferredBytes);
    final total = _formatBytes(totalBytes);
    return '$transferred / $total';
  }

  /// Get formatted speed string
  String get formattedSpeed {
    return '${_formatBytes(speed.toInt())}/s';
  }

  /// Get formatted remaining time string
  String get formattedRemainingTime {
    if (remainingSeconds <= 0) return '0s';
    if (remainingSeconds < 60) return '${remainingSeconds}s';
    if (remainingSeconds < 3600) {
      final minutes = remainingSeconds ~/ 60;
      final seconds = remainingSeconds % 60;
      return '${minutes}m ${seconds}s';
    }
    final hours = remainingSeconds ~/ 3600;
    final minutes = (remainingSeconds % 3600) ~/ 60;
    return '${hours}h ${minutes}m';
  }

  /// Get formatted elapsed time string
  String get formattedElapsedTime {
    final seconds = elapsedTime.inSeconds;
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

  /// Get formatted average speed string
  String get formattedAverageSpeed {
    return '${_formatBytes(averageSpeed.toInt())}/s';
  }

  /// Helper method to format bytes
  static String _formatBytes(int bytes) {
    if (bytes <= 0) return '0 B';
    const suffixes = ['B', 'KB', 'MB', 'GB'];
    var index = 0;
    var size = bytes.toDouble();
    while (size >= 1024 && index < suffixes.length - 1) {
      size /= 1024;
      index++;
    }
    return '${size.toStringAsFixed(2)} ${suffixes[index]}';
  }

  /// Get accuracy percentage (0 to 100)
  int get accuracyPercentage {
    return (accuracy * 100).toInt();
  }

  /// Check if progress is accurate
  bool get isAccurate {
    return accuracy >= 0.95; // 95% or higher
  }

  /// Get progress status description
  String get statusDescription {
    if (progressPercentage >= 1.0) {
      return 'Completed';
    }
    if (isStalled) {
      return 'Stalled - Check connection';
    }
    if (speed <= 0) {
      return 'Waiting...';
    }
    return 'Transferring...';
  }
}
