import 'dart:async';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flux/models/file_metadata.dart';
import 'package:flux/models/device.dart';
import 'package:flux/providers/file_transfer_provider.dart';
import 'package:flux/providers/device_provider.dart';
import 'package:flux/services/network_transfer_service.dart';
import 'package:flux/services/progress_tracking_service.dart';
import 'package:flux/services/network_manager_service.dart';
import 'package:flux/utils/logger.dart';

/// Provider for the transfer engine service
final transferEngineServiceProvider = Provider<TransferEngineService>((ref) {
  return TransferEngineService(ref);
});

/// Service that handles actual file transfers over network
class TransferEngineService {
  final Ref _ref;
  final NetworkTransferService _networkService = NetworkTransferService();
  final ProgressTrackingService _progressService = ProgressTrackingService();
  final NetworkManagerService _networkManager = NetworkManagerService();

  TransferEngineService(this._ref);

  /// Start server to receive files
  Future<int> startReceiving() async {
    try {
      // Ensure network is available
      final networkResult = await _networkManager.ensureNetworkConnection();
      if (!networkResult['success']) {
        throw Exception('No network connection available');
      }

      // Start transfer server with dynamic port
      final port = await _networkService.startServer();
      
      AppLogger.info('Ready to receive files on port $port');
      return port;
    } catch (e) {
      AppLogger.error('Failed to start receiving', e);
      rethrow;
    }
  }

  /// Stop receiving server
  Future<void> stopReceiving() async {
    await _networkService.stopServer();
  }

  /// Send files to a device
  Future<void> sendFiles(
    Device targetDevice,
    List<MapEntry<FileMetadata, String>> files, {
    Function(int currentFile, int totalFiles, double fileProgress, double speed, String status)? onProgress,
  }) async {
    try {
      // Ensure network is available
      final networkResult = await _networkManager.ensureNetworkConnection();
      if (!networkResult['success']) {
        throw Exception('No network connection available');
      }

      final notifier = _ref.read(fileTransferProvider.notifier);
      final totalBytes = files.fold<int>(0, (sum, f) => sum + f.key.size);
      int totalSentBytes = 0;

      for (int i = 0; i < files.length; i++) {
        final file = files[i].key;
        final filePath = files[i].value;

        // Add to active transfers
        final initialStatus = TransferStatus(
          fileId: file.id,
          fileName: file.name,
          state: TransferState.inProgress,
          totalBytes: file.size,
          transferredBytes: 0,
          startedAt: DateTime.now(),
        );
        await notifier.addTransfer(initialStatus);

        // Start progress tracking
        _progressService.startTracking(file.id, file.size);
        
        onProgress?.call(i + 1, files.length, 0.0, 0.0, 'Connecting to ${targetDevice.name}...');

        try {
          // Send the file using network transfer
          await _networkService.sendFile(
            targetDevice.ipAddress,
            targetDevice.port,
            file,
            filePath,
            onProgress: (progress, speed) {
              final fileSentBytes = (progress * file.size).toInt();
              totalSentBytes += fileSentBytes;
              final totalProgress = totalSentBytes / totalBytes;

              // Update progress tracking
              _progressService.updateProgress(file.id, fileSentBytes);
              
              // Update UI through provider
              notifier.updateTransferProgress(
                file.id,
                fileSentBytes,
                speed,
                speed > 0 ? ((file.size - fileSentBytes) / speed).toInt() : 0,
              );

              onProgress?.call(
                i + 1,
                files.length,
                progress,
                speed,
                'Transferring ${file.name}...',
              );
            },
          );

          // Mark as completed
          await notifier.completeTransfer(file.id);
          _progressService.completeTracking(file.id);

          // Add to history
          final historyNotifier = _ref.read(transferHistoryProvider.notifier);
          await historyNotifier.addHistoryEntry(TransferHistory(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            deviceId: targetDevice.id,
            deviceName: targetDevice.name,
            fileName: file.name,
            fileSize: file.size,
            direction: TransferDirection.send,
            timestamp: DateTime.now(),
            success: true,
            durationSeconds: DateTime.now().difference(initialStatus.startedAt).inSeconds,
          ));

          AppLogger.info('File sent successfully: ${file.name}');

        } catch (e) {
          AppLogger.error('Failed to send file: ${file.name}', e);
          await notifier.failTransfer(file.id, e.toString());
          _progressService.cancelTracking(file.id);
          
          // Add failed history entry
          final historyNotifier = _ref.read(transferHistoryProvider.notifier);
          await historyNotifier.addHistoryEntry(TransferHistory(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            deviceId: targetDevice.id,
            deviceName: targetDevice.name,
            fileName: file.name,
            fileSize: file.size,
            direction: TransferDirection.send,
            timestamp: DateTime.now(),
            success: false,
            error: e.toString(),
            durationSeconds: DateTime.now().difference(initialStatus.startedAt).inSeconds,
          ));
          
          rethrow;
        }
      }

      onProgress?.call(files.length, files.length, 1.0, 0.0, 'All transfers complete!');

    } catch (e) {
      AppLogger.error('File transfer operation failed', e);
      rethrow;
    }
  }

  /// Send a single file (convenience method)
  Future<void> sendFile(
    Device targetDevice,
    FileMetadata file,
    String filePath, {
    Function(double progress, double speed)? onProgress,
  }) async {
    await sendFiles(
      targetDevice,
      [MapEntry(file, filePath)],
      onProgress: (current, total, progress, speed, status) {
        onProgress?.call(progress, speed);
      },
    );
  }

  /// Pause a transfer
  Future<void> pauseTransfer(String fileId) async {
    final notifier = _ref.read(fileTransferProvider.notifier);
    await notifier.pauseTransfer(fileId);
    AppLogger.info('Transfer paused: $fileId');
  }

  /// Resume a transfer
  Future<void> resumeTransfer(String fileId) async {
    final notifier = _ref.read(fileTransferProvider.notifier);
    await notifier.resumeTransfer(fileId);
    AppLogger.info('Transfer resumed: $fileId');
  }

  /// Cancel a transfer
  Future<void> cancelTransfer(String fileId) async {
    final notifier = _ref.read(fileTransferProvider.notifier);
    await notifier.cancelTransfer(fileId);
    _progressService.cancelTracking(fileId);
    AppLogger.info('Transfer cancelled: $fileId');
  }

  /// Get current transfer speed for a file
  double? getTransferSpeed(String fileId) {
    final progress = _progressService.getProgress(fileId);
    return progress?.speed;
  }

  /// Get estimated time remaining for a file
  int? getTimeRemaining(String fileId) {
    final progress = _progressService.getProgress(fileId);
    return progress?.remainingSeconds;
  }

  /// Check if server is running
  bool get isReceiving => _networkService.isServerRunning;

  /// Get current server port
  int? get serverPort => _networkService.serverPort;
}
