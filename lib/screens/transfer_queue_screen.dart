import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/queued_transfer.dart';
import '../providers/transfer_queue_provider.dart';

/// Screen for managing transfer queue
class TransferQueueScreen extends ConsumerWidget {
  const TransferQueueScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final queueState = ref.watch(transferQueueProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Transfer Queue'),
        elevation: 0,
        actions: [
          if (queueState.isNotEmpty)
            PopupMenuButton<String>(
              onSelected: (value) async {
                if (value == 'clear') {
                  _showClearConfirmation(context, ref);
                }
              },
              itemBuilder: (BuildContext context) => [
                const PopupMenuItem(
                  value: 'clear',
                  child: Text('Clear Completed'),
                ),
              ],
            ),
        ],
      ),
      body: queueState.isEmpty
          ? _buildEmptyState()
          : _buildQueueList(context, ref, queueState),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.cloud_queue, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No transfers in queue',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Transfers will appear here when offline',
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildQueueList(
    BuildContext context,
    WidgetRef ref,
    List<QueuedTransfer> queue,
  ) {
    // Group by status
    final pending = queue
        .where((t) => t.status == TransferStatus.pending)
        .toList();
    final inProgress = queue
        .where((t) => t.status == TransferStatus.inProgress)
        .toList();
    final paused = queue
        .where((t) => t.status == TransferStatus.paused)
        .toList();
    final completed = queue
        .where((t) => t.status == TransferStatus.completed)
        .toList();
    final failed = queue
        .where((t) => t.status == TransferStatus.failed)
        .toList();

    return ListView(
      children: [
        if (inProgress.isNotEmpty) ...[
          _buildSectionHeader('In Progress', inProgress.length),
          ..._buildTransferItems(context, ref, inProgress),
        ],
        if (pending.isNotEmpty) ...[
          _buildSectionHeader('Pending', pending.length),
          ..._buildTransferItems(context, ref, pending),
        ],
        if (paused.isNotEmpty) ...[
          _buildSectionHeader('Paused', paused.length),
          ..._buildTransferItems(context, ref, paused),
        ],
        if (failed.isNotEmpty) ...[
          _buildSectionHeader('Failed', failed.length),
          ..._buildTransferItems(context, ref, failed),
        ],
        if (completed.isNotEmpty) ...[
          _buildSectionHeader('Completed', completed.length),
          ..._buildTransferItems(context, ref, completed),
        ],
      ],
    );
  }

  Widget _buildSectionHeader(String title, int count) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              count.toString(),
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildTransferItems(
    BuildContext context,
    WidgetRef ref,
    List<QueuedTransfer> transfers,
  ) {
    return transfers
        .map((transfer) => _buildTransferItem(context, ref, transfer))
        .toList();
  }

  Widget _buildTransferItem(
    BuildContext context,
    WidgetRef ref,
    QueuedTransfer transfer,
  ) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: ListTile(
        leading: _buildStatusIcon(transfer.status),
        title: Text(transfer.filePath.split('/').last),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              '${transfer.direction.name.toUpperCase()} • ${_formatBytes(transfer.fileSize)}',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
            if (transfer.status == TransferStatus.inProgress) ...[
              const SizedBox(height: 4),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: transfer.progress,
                  minHeight: 4,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '${transfer.percentComplete}%',
                style: TextStyle(fontSize: 11, color: Colors.grey[500]),
              ),
            ],
          ],
        ),
        trailing: _buildActionButtons(context, ref, transfer),
        isThreeLine: true,
      ),
    );
  }

  Widget _buildStatusIcon(TransferStatus status) {
    switch (status) {
      case TransferStatus.pending:
        return Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.blue[100],
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.schedule, color: Colors.blue[700], size: 20),
        );
      case TransferStatus.inProgress:
        return Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.orange[100],
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.cloud_upload, color: Colors.orange[700], size: 20),
        );
      case TransferStatus.paused:
        return Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.yellow[100],
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.pause, color: Colors.yellow[700], size: 20),
        );
      case TransferStatus.completed:
        return Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.green[100],
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.check_circle, color: Colors.green[700], size: 20),
        );
      case TransferStatus.failed:
        return Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.red[100],
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.error, color: Colors.red[700], size: 20),
        );
      case TransferStatus.cancelled:
        return Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.grey[300],
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.cancel, color: Colors.grey[700], size: 20),
        );
    }
  }

  Widget _buildActionButtons(
    BuildContext context,
    WidgetRef ref,
    QueuedTransfer transfer,
  ) {
    return PopupMenuButton<String>(
      onSelected: (value) async {
        try {
          if (value == 'pause') {
            await ref
                .read(transferQueueProvider.notifier)
                .pauseTransfer(transfer.id);
          } else if (value == 'resume') {
            await ref
                .read(transferQueueProvider.notifier)
                .resumeTransfer(transfer.id);
          } else if (value == 'retry') {
            await ref
                .read(transferQueueProvider.notifier)
                .retryTransfer(transfer.id);
          } else if (value == 'remove') {
            await ref
                .read(transferQueueProvider.notifier)
                .removeTransfer(transfer.id);
          }
        } catch (e) {
          if (context.mounted) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text('Error: $e')));
          }
        }
      },
      itemBuilder: (BuildContext context) {
        final items = <PopupMenuEntry<String>>[];

        if (transfer.status == TransferStatus.inProgress) {
          items.add(const PopupMenuItem(value: 'pause', child: Text('Pause')));
        } else if (transfer.status == TransferStatus.paused) {
          items.add(
            const PopupMenuItem(value: 'resume', child: Text('Resume')),
          );
        } else if (transfer.status == TransferStatus.failed) {
          items.add(const PopupMenuItem(value: 'retry', child: Text('Retry')));
        }

        if (transfer.status != TransferStatus.inProgress) {
          if (items.isNotEmpty) {
            items.add(const PopupMenuDivider());
          }
          items.add(
            const PopupMenuItem(value: 'remove', child: Text('Remove')),
          );
        }

        return items;
      },
    );
  }

  void _showClearConfirmation(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Completed Transfers?'),
        content: const Text(
          'This will remove all completed transfers from the queue.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              await ref.read(transferQueueProvider.notifier).clearCompleted();
              if (context.mounted) {
                Navigator.pop(context);
              }
            },
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    }
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
}
