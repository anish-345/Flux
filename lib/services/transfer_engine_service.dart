import 'dart:async';
import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flux/models/file_metadata.dart';
import 'package:flux/providers/file_transfer_provider.dart';
import 'package:flux/services/progress_tracking_service.dart';
import 'package:flux/utils/logger.dart';

/// Provider for the transfer engine service
final transferEngineServiceProvider = Provider<TransferEngineService>((ref) {
  return TransferEngineService(ref);
});

/// Service that drives the file transfer process (currently mocked)
class TransferEngineService {
  final Ref _ref;
  final Random _random = Random();
  final ProgressTrackingService _progressService = ProgressTrackingService();

  TransferEngineService(this._ref);

  /// Start a simulated transfer for a list of files
  Future<void> startTransfer(String deviceId, List<FileMetadata> files) async {
    for (final file in files) {
      _simulateTransfer(deviceId, file);
    }
  }

  Future<void> _simulateTransfer(String deviceId, FileMetadata file) async {
    AppLogger.info('Starting simulated transfer: ${file.name} to $deviceId');

    // 1. Mark as pending in provider
    final notifier = _ref.read(fileTransferProvider.notifier);
    final initialStatus = TransferStatus(
      fileId: file.id,
      fileName: file.name,
      state: TransferState.inProgress,
      totalBytes: file.size,
      transferredBytes: 0,
      startedAt: DateTime.now(),
    );

    await notifier.addTransfer(initialStatus);
    _progressService.startTracking(file.id, file.size);

    // 2. Simulate chunks
    int totalBytes = file.size;
    int transferred = 0;
    const int chunkSize = 1024 * 512; // 512KB chunks

    final timer = Timer.periodic(const Duration(milliseconds: 200), (timer) async {
      // Check if still in progress
      final currentStatus = notifier.getTransferById(file.id);
      if (currentStatus == null || currentStatus.state != TransferState.inProgress) {
        timer.cancel();
        _progressService.cancelTracking(file.id);
        return;
      }

      // Random jitter in transfer speed
      int currentChunk = (chunkSize * (0.8 + _random.nextDouble() * 0.4)).toInt();
      transferred += currentChunk;

      if (transferred >= totalBytes) {
        transferred = totalBytes;
        timer.cancel();

        // Update to completed
        await notifier.completeTransfer(file.id);
        _progressService.completeTracking(file.id);

        // Add to history
        final historyNotifier = _ref.read(transferHistoryProvider.notifier);
        await historyNotifier.addHistoryEntry(TransferHistory(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          deviceId: deviceId,
          deviceName: 'Remote Device', // Should be dynamic
          fileName: file.name,
          fileSize: file.size,
          direction: TransferDirection.send,
          timestamp: DateTime.now(),
          success: true,
          durationSeconds: DateTime.now().difference(initialStatus.startedAt).inSeconds,
        ));

        AppLogger.info('Simulated transfer complete: ${file.name}');
      } else {
        // Update progress
        _progressService.updateProgress(file.id, transferred);
        final stats = _progressService.getProgress(file.id);

        if (stats != null) {
          await notifier.updateTransferProgress(
            file.id,
            transferred,
            stats.speed,
            stats.remainingSeconds,
          );
        }
      }
    });
  }
}
