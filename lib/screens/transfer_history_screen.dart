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

class _TransferHistoryScreenState
    extends ConsumerState<TransferHistoryScreen> {
  TransferDirection? _selectedDirection;
  String _searchQuery = '';

  Widget _buildAppBarAction(AsyncValue<List<TransferHistory>> historyAsync) {
    return historyAsync.when(
      data: (history) => history.isNotEmpty
          ? IconButton(
              icon: const Icon(Icons.delete_sweep_outlined),
              onPressed: () => _showClearDialog(context),
              tooltip: 'Clear history',
            )
          : const SizedBox.shrink(),
      loading: () => const SizedBox.shrink(),
      error: (error, stack) => const SizedBox.shrink(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final historyAsync = ref.watch(transferHistoryProvider);
    final canPop = Navigator.of(context).canPop();

    final body = historyAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline,
                size: 64, color: Theme.of(context).colorScheme.error),
            const SizedBox(height: 16),
            Text(
              'Error loading history:\n$error',
              style: Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => ref.invalidate(transferHistoryProvider),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
      data: (history) => _buildHistoryContent(context, history),
    );

    // When pushed as a route → full Scaffold
    if (canPop) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Transfer History'),
          elevation: 0,
          actions: [_buildAppBarAction(historyAsync)],
        ),
        body: body,
      );
    }

    // Embedded in IndexedStack
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 4, 0),
          child: Row(
            children: [
              Text(
                'Transfer History',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const Spacer(),
              _buildAppBarAction(historyAsync),
            ],
          ),
        ),
        Expanded(child: body),
      ],
    );
  }

  Widget _buildHistoryContent(
    BuildContext context,
    List<TransferHistory> history,
  ) {
    var filtered = history;

    if (_selectedDirection != null) {
      filtered = filtered
          .where((e) => e.direction == _selectedDirection)
          .toList();
    }

    if (_searchQuery.isNotEmpty) {
      filtered = filtered
          .where(
            (e) =>
                e.fileName
                    .toLowerCase()
                    .contains(_searchQuery.toLowerCase()) ||
                e.deviceName
                    .toLowerCase()
                    .contains(_searchQuery.toLowerCase()),
          )
          .toList();
    }

    return Column(
      children: [
        // ── Filters ──
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              TextField(
                decoration: InputDecoration(
                  hintText: 'Search transfers…',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () => setState(() => _searchQuery = ''),
                        )
                      : null,
                ),
                onChanged: (v) => setState(() => _searchQuery = v),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: FilterChip(
                      label: const Text('All'),
                      selected: _selectedDirection == null,
                      onSelected: (_) =>
                          setState(() => _selectedDirection = null),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: FilterChip(
                      label: const Text('📤 Sent'),
                      selected:
                          _selectedDirection == TransferDirection.send,
                      onSelected: (selected) => setState(
                        () => _selectedDirection =
                            selected ? TransferDirection.send : null,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: FilterChip(
                      label: const Text('📥 Received'),
                      selected:
                          _selectedDirection == TransferDirection.receive,
                      onSelected: (selected) => setState(
                        () => _selectedDirection =
                            selected ? TransferDirection.receive : null,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // ── List ──
        Expanded(
          child: filtered.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.history,
                        size: 72,
                        color: Theme.of(context).colorScheme.outline,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        history.isEmpty
                            ? 'No transfer history yet'
                            : 'No results for current filter',
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      if (history.isEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          'Your file transfer history will appear here.',
                          style: Theme.of(context).textTheme.bodySmall,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) =>
                      _buildHistoryItem(context, filtered[index]),
                ),
        ),
      ],
    );
  }

  Widget _buildHistoryItem(BuildContext context, TransferHistory entry) {
    final dateFormat = DateFormat('MMM dd, yyyy  HH:mm');
    final sizeInMB = (entry.fileSize / (1024 * 1024)).toStringAsFixed(2);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: entry.success
              ? Colors.green.withValues(alpha: 0.15)
              : Colors.red.withValues(alpha: 0.15),
          child: Icon(
            entry.direction == TransferDirection.send
                ? Icons.upload_rounded
                : Icons.download_rounded,
            color: entry.success ? Colors.green : Colors.red,
          ),
        ),
        title: Text(entry.fileName,
            maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${entry.direction.displayName} • ${entry.deviceName}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            Text(
              '$sizeInMB MB  •  ${dateFormat.format(entry.timestamp)}',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: Theme.of(context).colorScheme.outline),
            ),
          ],
        ),
        trailing: Icon(
          entry.success ? Icons.check_circle : Icons.error,
          color: entry.success ? Colors.green : Colors.red,
        ),
        onTap: () => _showDetailsDialog(context, entry),
      ),
    );
  }

  void _showDetailsDialog(BuildContext context, TransferHistory entry) {
    final dateFormat = DateFormat('MMM dd, yyyy  HH:mm:ss');
    final sizeInMB = (entry.fileSize / (1024 * 1024)).toStringAsFixed(2);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Transfer Details'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _detailRow('File:', entry.fileName),
            _detailRow('Device:', entry.deviceName),
            _detailRow('Direction:', entry.direction.displayName),
            _detailRow('Size:', '$sizeInMB MB'),
            _detailRow('Date:', dateFormat.format(entry.timestamp)),
            _detailRow('Duration:', '${entry.durationSeconds}s'),
            _detailRow(
                'Status:', entry.success ? '✅ Successful' : '❌ Failed'),
            if (entry.error != null) _detailRow('Error:', entry.error!),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
          if (!entry.success)
            FilledButton(
              onPressed: () {
                Navigator.pop(ctx);
                // TODO: Implement retry logic
              },
              child: const Text('Retry'),
            ),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(width: 8),
          Expanded(
              child: Text(value, overflow: TextOverflow.ellipsis)),
        ],
      ),
    );
  }

  void _showClearDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear History'),
        content: const Text(
          'Are you sure you want to clear all transfer history?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              // Use ref.read so we don't rebuild while awaiting
              await ref
                  .read(transferHistoryProvider.notifier)
                  .clearHistory();
              if (mounted && ctx.mounted) {
                Navigator.pop(ctx);
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
