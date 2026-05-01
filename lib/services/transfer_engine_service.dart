import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flux/models/file_metadata.dart';
import 'package:flux/models/device.dart';
import 'package:flux/services/network_transfer_service.dart';
import 'package:flux/services/progress_tracking_service.dart';
import 'package:flux/services/network_manager_service.dart';
import 'package:flux/providers/transfer_history_provider.dart';
import 'package:flux/utils/logger.dart';

/// Provider for the transfer engine service
final transferEngineServiceProvider = Provider<TransferEngineService>((ref) {
  return TransferEngineService(ref);
});

/// Service that handles actual file transfers over network
class TransferEngineService {
  final Ref _ref;
  late final NetworkTransferService _networkService;
  final ProgressTrackingService _progressService = ProgressTrackingService();
  final NetworkManagerService _networkManager = NetworkManagerService();

  TransferEngineService(this._ref) {
    _networkService = NetworkTransferService(_ref);
  }

  /// Expose NetworkTransferService for connection notifications
  NetworkTransferService get networkService => _networkService;

  /// Start server to receive files
  Future<int> startReceiving() async {
    try {
      AppLogger.info('🔧 Starting transfer engine server...');
      
      // Ensure network is available
      final networkResult = await _networkManager.ensureNetworkConnection();
      AppLogger.info('🌐 Network check result: ${networkResult['success']}');
      
      if (!networkResult['success']) {
        throw Exception('No network connection available');
      }

      // Start transfer server with dynamic port
      AppLogger.info('🚀 Starting NetworkTransferService server...');
      final port = await _networkService.startServer();
      
      AppLogger.info('✅ Transfer engine server ready to receive files on port $port');
      return port;
    } catch (e) {
      AppLogger.error('❌ Failed to start receiving server', e);
      rethrow;
    }
  }

  /// Stop receiving server
  Future<void> stopReceiving() async {
    await _networkService.stopServer();
  }

  /// Send files to a device
  /// Uses "best effort" mode - continues on individual file failures
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

      AppLogger.info('Starting transfer of ${files.length} files to ${targetDevice.name}');

      int currentFile = 1;
      int successCount = 0;
      int failureCount = 0;

      for (final entry in files) {
        final file = entry.key;
        final filePath = entry.value;

        // Create transfer history record
        final transferId = DateTime.now().millisecondsSinceEpoch.toString();
        final transfer = TransferHistory(
          id: transferId,
          deviceId: targetDevice.id,
          deviceName: targetDevice.name,
          fileName: file.name,
          fileSize: file.size,
          direction: TransferDirection.send,
          timestamp: DateTime.now(),
          success: false,
        );
        _ref.read(transferHistoryProvider.notifier).addTransfer(transfer);

        AppLogger.info('Sending file $currentFile/$files.length: $file.name');

        try {
          await _networkService.sendFile(
            targetDevice.ipAddress,
            targetDevice.port,
            file,
            filePath,
            onProgress: (progress, speed) {
              onProgress?.call(currentFile, files.length, progress, speed, 'Sending ${file.name}');
            },
          );

          // Update history as completed
          final completedTransfer = TransferHistory(
            id: transferId,
            deviceId: targetDevice.id,
            deviceName: targetDevice.name,
            fileName: file.name,
            fileSize: file.size,
            direction: TransferDirection.send,
            timestamp: DateTime.now(),
            success: true,
          );
          _ref.read(transferHistoryProvider.notifier).addTransfer(completedTransfer);

          successCount++;
          AppLogger.info('File sent successfully: ${file.name}');
        } catch (e) {
          // Update history as failed but continue to next file
          final failedTransfer = TransferHistory(
            id: transferId,
            deviceId: targetDevice.id,
            deviceName: targetDevice.name,
            fileName: file.name,
            fileSize: file.size,
            direction: TransferDirection.send,
            timestamp: DateTime.now(),
            success: false,
            error: e.toString(),
          );
          _ref.read(transferHistoryProvider.notifier).addTransfer(failedTransfer);
          failureCount++;
          AppLogger.error('Failed to send file: ${file.name} (continuing with next file)', e);
          // Continue to next file instead of rethrowing
        }

        currentFile++;
      }

      AppLogger.info('Batch transfer complete: $successCount succeeded, $failureCount failed');
      
      // Only throw if all files failed
      if (failureCount == files.length && files.isNotEmpty) {
        throw Exception('All files failed to transfer');
      }
    } catch (e) {
      AppLogger.error('File transfer failed', e);
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

  /// Cancel a transfer
  Future<void> cancelTransfer(String fileId) async {
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
