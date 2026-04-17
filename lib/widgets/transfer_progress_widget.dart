import 'package:flutter/material.dart';
import 'package:flux/models/file_metadata.dart';

class TransferProgressWidget extends StatelessWidget {
  final TransferStatus transfer;
  final VoidCallback onPause;
  final VoidCallback onResume;
  final VoidCallback onCancel;

  const TransferProgressWidget({
    super.key,
    required this.transfer,
    required this.onPause,
    required this.onResume,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final progress = transfer.totalBytes > 0
        ? transfer.transferredBytes / transfer.totalBytes
        : 0.0;
    final speedMBps = (transfer.speed / (1024 * 1024)).toStringAsFixed(2);
    final totalSizeMB = (transfer.totalBytes / (1024 * 1024)).toStringAsFixed(
      2,
    );
    final transferredMB = (transfer.transferredBytes / (1024 * 1024))
        .toStringAsFixed(2);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // File Name and Status
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        transfer.fileName,
                        style: Theme.of(context).textTheme.titleMedium,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        transfer.state.displayName,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: _getStatusColor(transfer.state),
                        ),
                      ),
                    ],
                  ),
                ),
                _buildStatusIcon(transfer.state),
              ],
            ),

            const SizedBox(height: 12),

            // Progress Bar
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(value: progress, minHeight: 8),
            ),

            const SizedBox(height: 12),

            // Progress Details
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '$transferredMB / $totalSizeMB MB',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                Text(
                  '${(progress * 100).toStringAsFixed(1)}%',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // Speed and Time Remaining
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Speed: $speedMBps MB/s',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                Text(
                  'Time: ${_formatDuration(transfer.remainingSeconds)}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Action Buttons
            Row(
              children: [
                if (transfer.state == TransferState.inProgress)
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onPause,
                      icon: const Icon(Icons.pause),
                      label: const Text('Pause'),
                    ),
                  )
                else if (transfer.state == TransferState.paused)
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onResume,
                      icon: const Icon(Icons.play_arrow),
                      label: const Text('Resume'),
                    ),
                  ),
                if (transfer.state == TransferState.inProgress ||
                    transfer.state == TransferState.paused)
                  const SizedBox(width: 8),
                if (transfer.state == TransferState.inProgress ||
                    transfer.state == TransferState.paused)
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onCancel,
                      icon: const Icon(Icons.close),
                      label: const Text('Cancel'),
                    ),
                  ),
              ],
            ),

            // Error Message
            if (transfer.error != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error, color: Colors.red, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          transfer.error!,
                          style: Theme.of(
                            context,
                          ).textTheme.bodySmall?.copyWith(color: Colors.red),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusIcon(TransferState state) {
    switch (state) {
      case TransferState.inProgress:
        return const SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(strokeWidth: 2),
        );
      case TransferState.completed:
        return const Icon(Icons.check_circle, color: Colors.green);
      case TransferState.failed:
        return const Icon(Icons.error, color: Colors.red);
      case TransferState.paused:
        return const Icon(Icons.pause_circle, color: Colors.orange);
      case TransferState.cancelled:
        return const Icon(Icons.cancel, color: Colors.grey);
      default:
        return const Icon(Icons.schedule, color: Colors.blue);
    }
  }

  Color _getStatusColor(TransferState state) {
    switch (state) {
      case TransferState.inProgress:
        return Colors.blue;
      case TransferState.completed:
        return Colors.green;
      case TransferState.failed:
        return Colors.red;
      case TransferState.paused:
        return Colors.orange;
      case TransferState.cancelled:
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  String _formatDuration(int seconds) {
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
}

