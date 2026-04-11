import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flux/models/file_metadata.dart';
import 'package:flux/models/device.dart';
import 'package:flux/providers/file_transfer_provider.dart';
import 'package:flux/providers/device_provider.dart';
import 'package:flux/widgets/transfer_progress_widget.dart';
import 'package:flux/widgets/file_list_item.dart';
import 'package:flux/utils/logger.dart';

class FileTransferScreen extends ConsumerStatefulWidget {
  final Device? targetDevice;

  const FileTransferScreen({super.key, this.targetDevice});

  @override
  ConsumerState<FileTransferScreen> createState() => _FileTransferScreenState();
}

class _FileTransferScreenState extends ConsumerState<FileTransferScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final List<FileMetadata> _selectedFiles = [];
  Device? _selectedDevice;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _selectedDevice = widget.targetDevice;
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _pickFiles() async {
    try {
      final files = await openFiles();

      if (files.isNotEmpty) {
        for (final file in files) {
          final bytes = await file.readAsBytes();
          final metadata = FileMetadata(
            id: file.name,
            name: file.name,
            size: bytes.length,
            mimeType: file.mimeType ?? 'unknown',
            hash: '', // Will be calculated during transfer
            createdAt: DateTime.now(),
            modifiedAt: DateTime.now(),
            path: file.path,
          );
          setState(() => _selectedFiles.add(metadata));
        }
      }
    } catch (e) {
      AppLogger.error('Failed to pick files', e);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to pick files: $e')));
      }
    }
  }

  Future<void> _startTransfer() async {
    if (_selectedFiles.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select files to transfer')),
      );
      return;
    }

    if (_selectedDevice == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a target device')),
      );
      return;
    }

    try {
      for (final file in _selectedFiles) {
        final transfer = TransferStatus(
          fileId: file.id,
          fileName: file.name,
          state: TransferState.pending,
          totalBytes: file.size,
          transferredBytes: 0,
          startedAt: DateTime.now(),
        );
        await ref.read(fileTransferProvider.notifier).addTransfer(transfer);
      }

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Transfer started')));
        setState(() => _selectedFiles.clear());
      }
    } catch (e) {
      AppLogger.error('Failed to start transfer', e);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Transfer failed: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeTransfers = ref.watch(activeTransfersProvider);
    final connectedDevices = ref.watch(connectedDevicesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('File Transfer'),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(
              text: 'Send (${_selectedFiles.length})',
              icon: const Icon(Icons.upload),
            ),
            Tab(
              text: 'Active (${activeTransfers.length})',
              icon: const Icon(Icons.sync),
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Send Tab
          Column(
            children: [
              // Device Selection
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Target Device',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    DropdownButton<Device>(
                      isExpanded: true,
                      value: _selectedDevice,
                      hint: const Text('Select a device'),
                      items: connectedDevices
                          .map(
                            (device) => DropdownMenuItem(
                              value: device,
                              child: Text(device.name),
                            ),
                          )
                          .toList(),
                      onChanged: (device) {
                        setState(() => _selectedDevice = device);
                      },
                    ),
                  ],
                ),
              ),

              // File List
              Expanded(
                child: _selectedFiles.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.file_present,
                              size: 64,
                              color: Theme.of(context).colorScheme.outline,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No files selected',
                              style: Theme.of(context).textTheme.bodyLarge,
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _selectedFiles.length,
                        itemBuilder: (context, index) {
                          final file = _selectedFiles[index];
                          return FileListItem(
                            file: file,
                            onRemove: () {
                              setState(() => _selectedFiles.removeAt(index));
                            },
                          );
                        },
                      ),
              ),

              // Action Buttons
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _pickFiles,
                        icon: const Icon(Icons.add),
                        label: const Text('Add Files'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: _startTransfer,
                        icon: const Icon(Icons.send),
                        label: const Text('Send'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Active Transfers Tab
          activeTransfers.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.check_circle,
                        size: 64,
                        color: Theme.of(context).colorScheme.outline,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No active transfers',
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: activeTransfers.length,
                  itemBuilder: (context, index) {
                    final transfer = activeTransfers[index];
                    return TransferProgressWidget(
                      transfer: transfer,
                      onPause: () => _handlePause(transfer.fileId),
                      onResume: () => _handleResume(transfer.fileId),
                      onCancel: () => _handleCancel(transfer.fileId),
                    );
                  },
                ),
        ],
      ),
    );
  }

  Future<void> _handlePause(String fileId) async {
    try {
      await ref.read(fileTransferProvider.notifier).pauseTransfer(fileId);
    } catch (e) {
      AppLogger.error('Failed to pause transfer', e);
    }
  }

  Future<void> _handleResume(String fileId) async {
    try {
      await ref.read(fileTransferProvider.notifier).resumeTransfer(fileId);
    } catch (e) {
      AppLogger.error('Failed to resume transfer', e);
    }
  }

  Future<void> _handleCancel(String fileId) async {
    try {
      await ref.read(fileTransferProvider.notifier).cancelTransfer(fileId);
    } catch (e) {
      AppLogger.error('Failed to cancel transfer', e);
    }
  }
}
