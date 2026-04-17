import 'package:flutter/material.dart';
import 'package:flux/models/file_metadata.dart';
import 'package:flux/models/transfer_progress.dart';

/// Enhanced progress indicator with accurate tracking and detailed information
class EnhancedProgressIndicator extends StatelessWidget {
  final TransferStatus transfer;
  final TransferProgress? progressDetails;
  final VoidCallback onPause;
  final VoidCallback onResume;
  final VoidCallback onCancel;
  final bool showDetailedStats;

  const EnhancedProgressIndicator({
    super.key,
    required this.transfer,
    this.progressDetails,
    required this.onPause,
    required this.onResume,
    required this.onCancel,
    this.showDetailedStats = true,
  });

  @override
  Widget build(BuildContext context) {
    final progress = transfer.totalBytes > 0
        ? transfer.transferredBytes / transfer.totalBytes
        : 0.0;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: File Name and Status
            _buildHeader(context, progress),
            const SizedBox(height: 12),

            // Main Progress Bar with animation
            _buildProgressBar(context, progress),
            const SizedBox(height: 12),

            // Progress Percentage and Size Info
            _buildProgressInfo(context, progress),
            const SizedBox(height: 8),

            // Speed and Time Information
            _buildSpeedAndTimeInfo(context),
            const SizedBox(height: 12),

            // Detailed Statistics (if enabled)
            if (showDetailedStats && progressDetails != null)
              _buildDetailedStats(context),

            // Status Indicators
            if (transfer.state == TransferState.inProgress)
              _buildStatusIndicators(context),

            // Action Buttons
            const SizedBox(height: 12),
            _buildActionButtons(context),

            // Error Message
            if (transfer.error != null) _buildErrorMessage(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, double progress) {
    return Row(
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
              Row(
                children: [
                  Text(
                    transfer.state.displayName,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: _getStatusColor(transfer.state),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (transfer.state == TransferState.inProgress)
                    Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: Text(
                        '${(progress * 100).toStringAsFixed(1)}%',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.blue,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
        _buildStatusIcon(transfer.state),
      ],
    );
  }

  Widget _buildProgressBar(BuildContext context, double progress) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Main progress bar with gradient
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Container(
            height: 12,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Stack(
              children: [
                // Background
                Container(
                  height: 12,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                // Progress fill with gradient
                FractionallySizedBox(
                  widthFactor: progress.clamp(0.0, 1.0),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: _getProgressGradient(transfer.state),
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 4),
        // Accuracy indicator (if available)
        if (progressDetails != null && !progressDetails!.isAccurate)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Row(
              children: [
                Icon(Icons.info_outline, size: 14, color: Colors.orange),
                const SizedBox(width: 4),
                Text(
                  'Accuracy: ${progressDetails!.accuracyPercentage}%',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.orange,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildProgressInfo(BuildContext context, double progress) {
    final totalSizeMB = (transfer.totalBytes / (1024 * 1024)).toStringAsFixed(
      2,
    );
    final transferredMB = (transfer.transferredBytes / (1024 * 1024))
        .toStringAsFixed(2);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          '$transferredMB / $totalSizeMB MB',
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w500),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: _getStatusColor(transfer.state).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            '${(progress * 100).toStringAsFixed(1)}%',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: _getStatusColor(transfer.state),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSpeedAndTimeInfo(BuildContext context) {
    final speedMBps = (transfer.speed / (1024 * 1024)).toStringAsFixed(2);
    final remainingTime = _formatDuration(transfer.remainingSeconds);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Speed',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                  fontSize: 11,
                ),
              ),
              Text(
                '$speedMBps MB/s',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Time Remaining',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                  fontSize: 11,
                ),
              ),
              Text(
                remainingTime,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
        if (progressDetails != null)
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Elapsed',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                    fontSize: 11,
                  ),
                ),
                Text(
                  progressDetails!.formattedElapsedTime,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildDetailedStats(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Transfer Details',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 8),
            _buildDetailRow(
              context,
              'Chunks',
              '${progressDetails!.chunksTransferred} / ${progressDetails!.totalChunks}',
            ),
            _buildDetailRow(
              context,
              'Average Speed',
              progressDetails!.formattedAverageSpeed,
            ),
            _buildDetailRow(
              context,
              'Remaining',
              progressDetails!.formattedRemainingTime,
            ),
            if (progressDetails!.lastError != null)
              _buildDetailRow(
                context,
                'Last Error',
                progressDetails!.lastError!,
                isError: true,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(
    BuildContext context,
    String label,
    String value, {
    bool isError = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: isError ? Colors.red : Colors.grey[800],
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildStatusIndicators(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          // Connection status
          _buildStatusBadge(
            context,
            'Connected',
            Colors.green,
            Icons.cloud_done,
          ),
          const SizedBox(width: 8),
          // Speed status
          if (transfer.speed > 0)
            _buildStatusBadge(context, 'Active', Colors.blue, Icons.speed),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(
    BuildContext context,
    String label,
    Color color,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Row(
      children: [
        if (transfer.state == TransferState.inProgress)
          Expanded(
            child: OutlinedButton.icon(
              onPressed: onPause,
              icon: const Icon(Icons.pause, size: 18),
              label: const Text('Pause'),
            ),
          )
        else if (transfer.state == TransferState.paused)
          Expanded(
            child: OutlinedButton.icon(
              onPressed: onResume,
              icon: const Icon(Icons.play_arrow, size: 18),
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
              icon: const Icon(Icons.close, size: 18),
              label: const Text('Cancel'),
            ),
          ),
      ],
    );
  }

  Widget _buildErrorMessage(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.red.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                transfer.error!,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.red,
                  fontWeight: FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
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
        return const Icon(Icons.check_circle, color: Colors.green, size: 24);
      case TransferState.failed:
        return const Icon(Icons.error, color: Colors.red, size: 24);
      case TransferState.paused:
        return const Icon(Icons.pause_circle, color: Colors.orange, size: 24);
      case TransferState.cancelled:
        return const Icon(Icons.cancel, color: Colors.grey, size: 24);
      default:
        return const Icon(Icons.schedule, color: Colors.blue, size: 24);
    }
  }

  List<Color> _getProgressGradient(TransferState state) {
    switch (state) {
      case TransferState.inProgress:
        return [Colors.blue, Colors.cyan];
      case TransferState.completed:
        return [Colors.green, Colors.teal];
      case TransferState.failed:
        return [Colors.red, Colors.orange];
      case TransferState.paused:
        return [Colors.orange, Colors.amber];
      case TransferState.cancelled:
        return [Colors.grey, Colors.blueGrey];
      default:
        return [Colors.blue, Colors.indigo];
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
