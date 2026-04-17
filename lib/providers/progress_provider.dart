import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flux/models/transfer_progress.dart';
import 'package:flux/services/progress_tracking_service.dart';

/// Provider for the progress tracking service
final progressTrackingServiceProvider = Provider<ProgressTrackingService>((
  ref,
) {
  return ProgressTrackingService();
});

/// Provider for getting progress stream for a specific transfer
final transferProgressProvider =
    StreamProvider.family<TransferProgress, String>((ref, fileId) {
      final service = ref.watch(progressTrackingServiceProvider);
      return service.getProgressStream(fileId);
    });

/// Provider for getting current progress for a specific transfer
final currentTransferProgressProvider =
    FutureProvider.family<TransferProgress?, String>((ref, fileId) async {
      final service = ref.watch(progressTrackingServiceProvider);
      return service.getProgress(fileId);
    });

/// Provider for getting all active transfers
final activeTransfersListProvider = Provider<List<String>>((ref) {
  final service = ref.watch(progressTrackingServiceProvider);
  return service.getActiveTransfers();
});

/// Provider for getting overall transfer statistics
final transferStatisticsProvider = Provider<Map<String, dynamic>>((ref) {
  final service = ref.watch(progressTrackingServiceProvider);
  return service.getStatistics();
});

/// Provider for getting overall progress percentage
final overallProgressProvider = Provider<double>((ref) {
  final stats = ref.watch(transferStatisticsProvider);
  return stats['overallProgress'] as double? ?? 0.0;
});

/// Provider for getting average transfer speed
final averageSpeedProvider = Provider<double>((ref) {
  final stats = ref.watch(transferStatisticsProvider);
  return stats['averageSpeed'] as double? ?? 0.0;
});

/// Provider for getting number of active transfers
final activeTransfersCountProvider = Provider<int>((ref) {
  final stats = ref.watch(transferStatisticsProvider);
  return stats['activeTransfers'] as int? ?? 0;
});
