import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flux/models/file_metadata.dart';
import 'package:flux/providers/file_transfer_provider.dart';
import 'package:intl/intl.dart';

class TransferHistoryScreen extends ConsumerStatefulWidget {
  const TransferHistoryScreen({super.key});

  @override
  ConsumerState<TransferHistoryScreen> createState() =>
      _TransferHistoryScreenState();
}

class _TransferHistoryScreenState extends ConsumerState<TransferHistoryScreen> {
  TransferDirection? _selectedDirection;
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final history = ref.watch(transferHistoryProvider);

    var filteredHistory = history;

    if (_selectedDirection != null) {
      filteredHistory = filteredHistory
          .where((entry) => entry.direction == _selectedDirection)
          .toList();
    }

    if (_searchQuery.isNotEmpty) {
      filteredHistory = filteredHistory
          .where(
            (entry) =>
                entry.fileName.toLowerCase().contains(
                  _searchQuery.toLowerCase(),
                ) ||
                entry.deviceName.toLowerCase().contains(
                  _searchQuery.toLowerCase(),
                ),
          )
          .toList();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Transfer History'),
        actions: [
          if (history.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep),
              onPressed: () => _showClearDialog(context),
              tooltip: 'Clear history',
            ),
        ],
      ),
      body: Column(
        children: [
          // Filters
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Search
                TextField(
                  decoration: InputDecoration(
                    hintText: 'Search transfers...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onChanged: (value) {
                    setState(() => _searchQuery = value);
                  },
                ),
                const SizedBox(height: 12),
                // Direction Filter
                Row(
                  children: [
                    Expanded(
                      child: FilterChip(
                        label: const Text('All'),
                        selected: _selectedDirection == null,
                        onSelected: (selected) {
                          setState(
                            () => _selectedDirection = selected
                                ? null
                                : _selectedDirection,
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: FilterChip(
                        label: const Text('📤 Sent'),
                        selected: _selectedDirection == TransferDirection.send,
                        onSelected: (selected) {
                          setState(
                            () => _selectedDirection = selected
                                ? TransferDirection.send
                                : null,
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: FilterChip(
                        label: const Text('📥 Received'),
                        selected:
                            _selectedDirection == TransferDirection.receive,
                        onSelected: (selected) {
                          setState(
                            () => _selectedDirection = selected
                                ? TransferDirection.receive
                                : null,
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // History List
          Expanded(
            child: filteredHistory.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.history,
                          size: 64,
                          color: Theme.of(context).colorScheme.outline,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No transfer history',
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: filteredHistory.length,
                    itemBuilder: (context, index) {
                      final entry = filteredHistory[index];
                      return _buildHistoryItem(context, entry);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryItem(BuildContext context, TransferHistory entry) {
    final dateFormat = DateFormat('MMM dd, yyyy HH:mm');
    final sizeInMB = (entry.fileSize / (1024 * 1024)).toStringAsFixed(2);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        leading: Icon(
          entry.direction == TransferDirection.send
              ? Icons.upload
              : Icons.download,
          color: entry.success
              ? Colors.green
              : Theme.of(context).colorScheme.error,
        ),
        title: Text(entry.fileName),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${entry.direction.displayName} to ${entry.deviceName}'),
            Text(
              '${sizeInMB} MB • ${dateFormat.format(entry.timestamp)}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        trailing: entry.success
            ? const Icon(Icons.check_circle, color: Colors.green)
            : const Icon(Icons.error, color: Colors.red),
        onTap: () => _showDetailsDialog(context, entry),
      ),
    );
  }

  void _showDetailsDialog(BuildContext context, TransferHistory entry) {
    final dateFormat = DateFormat('MMM dd, yyyy HH:mm:ss');
    final sizeInMB = (entry.fileSize / (1024 * 1024)).toStringAsFixed(2);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Transfer Details'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow('File:', entry.fileName),
            _buildDetailRow('Device:', entry.deviceName),
            _buildDetailRow('Direction:', entry.direction.displayName),
            _buildDetailRow('Size:', '$sizeInMB MB'),
            _buildDetailRow('Date:', dateFormat.format(entry.timestamp)),
            _buildDetailRow('Duration:', '${entry.durationSeconds}s'),
            _buildDetailRow('Status:', entry.success ? 'Successful' : 'Failed'),
            if (entry.error != null) _buildDetailRow('Error:', entry.error!),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          if (!entry.success)
            FilledButton(
              onPressed: () {
                Navigator.pop(context);
                // TODO: Implement retry logic
              },
              child: const Text('Retry'),
            ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(width: 8),
          Expanded(child: Text(value, overflow: TextOverflow.ellipsis)),
        ],
      ),
    );
  }

  void _showClearDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear History'),
        content: const Text(
          'Are you sure you want to clear all transfer history?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              await ref.read(transferHistoryProvider.notifier).clearHistory();
              if (mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('History cleared')),
                );
              }
            },
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }
}
