import 'package:flutter/material.dart';
import 'package:flux/models/queued_transfer.dart';
import 'package:flux/config/app_theme.dart';

/// Transfer Status List View
/// Renders a unified list of sending and receiving files
class TransferStatusList extends StatelessWidget {
  final List<QueuedTransfer> transfers;
  final Function(int index) onRemoveFile;

  const TransferStatusList({
    super.key,
    required this.transfers,
    required this.onRemoveFile,
  });

  @override
  Widget build(BuildContext context) {
    if (transfers.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.swap_horizontal_circle_outlined,
              size: 64,
              color: AppTheme.textTertiary,
            ),
            const SizedBox(height: 16),
            Text(
              'No active transfers',
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Sent and received files will appear here',
              style: TextStyle(
                color: AppTheme.textTertiary,
                fontSize: 13,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      itemCount: transfers.length,
      itemBuilder: (context, index) {
        final transfer = transfers[index];
        return _buildTransferItem(context, transfer, index);
      },
    );
  }

  Widget _buildTransferItem(BuildContext context, QueuedTransfer transfer, int index) {
    final isSending = transfer.direction == TransferDirection.send;
    final isComplete = transfer.status == TransferStatus.completed;
    final isFailed = transfer.status == TransferStatus.failed;
    final isInProgress = transfer.status == TransferStatus.inProgress;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // Icon based on type
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: (isSending ? AppTheme.primaryColor : Colors.orange).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _getFileIcon(transfer.filePath),
                    color: isSending ? AppTheme.primaryColor : Colors.orange,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                
                // Name and details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        transfer.filePath.split(RegExp(r'[/\\]')).last,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(
                            isSending ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
                            size: 12,
                            color: AppTheme.textTertiary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            isSending ? 'Sending' : 'Receiving',
                            style: TextStyle(
                              color: AppTheme.textTertiary,
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            ' • ${_formatFileSize(transfer.fileSize)}',
                            style: TextStyle(
                              color: AppTheme.textTertiary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                // Status or Remove
                if (isComplete)
                  const Icon(Icons.check_circle_rounded, color: Colors.green, size: 24)
                else if (isFailed)
                  const Icon(Icons.error_outline_rounded, color: Colors.red, size: 24)
                else
                  IconButton(
                    onPressed: () => onRemoveFile(index),
                    icon: const Icon(Icons.close_rounded, size: 20),
                    color: AppTheme.textTertiary,
                  ),
              ],
            ),
          ),
          
          // Mini progress bar for active transfers
          if (isInProgress)
            ClipRRect(
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
              child: LinearProgressIndicator(
                value: transfer.progress,
                backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.05),
                valueColor: AlwaysStoppedAnimation(
                  isSending ? AppTheme.primaryColor : Colors.orange,
                ),
                minHeight: 4,
              ),
            ),
        ],
      ),
    );
  }

  IconData _getFileIcon(String fileName) {
    final name = fileName.toLowerCase();
    if (name.endsWith('.jpg') || name.endsWith('.jpeg') || name.endsWith('.png') || name.endsWith('.gif')) {
      return Icons.image_rounded;
    } else if (name.endsWith('.mp4') || name.endsWith('.mov') || name.endsWith('.avi')) {
      return Icons.videocam_rounded;
    } else if (name.endsWith('.mp3') || name.endsWith('.wav')) {
      return Icons.audiotrack_rounded;
    } else if (name.endsWith('.pdf')) {
      return Icons.picture_as_pdf_rounded;
    } else if (name.endsWith('.apk')) {
      return Icons.android_rounded;
    } else if (name.endsWith('.zip') || name.endsWith('.rar')) {
      return Icons.folder_zip_rounded;
    }
    return Icons.insert_drive_file_rounded;
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
}
