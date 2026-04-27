import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flux/models/file_metadata.dart';
import 'package:flux/models/device.dart';
import 'package:flux/providers/file_transfer_provider.dart';
import 'package:flux/providers/device_provider.dart';
import 'package:flux/widgets/transfer_progress_widget.dart';
import 'package:flux/widgets/app_card.dart';
import 'package:flux/services/transfer_engine_service.dart';
import 'package:flux/config/app_theme.dart';
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
      final engine = ref.read(transferEngineServiceProvider);
      // Convert selected files to the format expected by sendFiles
      final filesWithPaths = _selectedFiles.map((file) {
        return MapEntry(file, file.path ?? '');
      }).toList();
      await engine.sendFiles(_selectedDevice!, filesWithPaths);

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Transfer started')));
        setState(() {
          _selectedFiles.clear();
          // Switch to active transfers tab
          _tabController.animateTo(1);
        });
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
    final activeTransfersAsync = ref.watch(activeTransfersProvider);
    final connectedDevices = ref.watch(connectedDevicesProvider);

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('File Transfer'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.primaryColor,
          labelColor: AppTheme.primaryColor,
          unselectedLabelColor: AppTheme.textTertiary,
          tabs: [
            Tab(
              text: 'Send (${_selectedFiles.length})',
              icon: const Icon(Icons.upload_rounded),
            ),
            Tab(
              text: activeTransfersAsync.when(
                data: (transfers) => 'Active (${transfers.length})',
                loading: () => 'Active (...)',
                error: (error, stackTrace) => 'Active (Error)',
              ),
              icon: const Icon(Icons.sync_rounded),
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Send Tab
          _buildSendTab(connectedDevices),

          // Active Transfers Tab
          _buildActiveTransfersTab(activeTransfersAsync),
        ],
      ),
    );
  }

  Widget _buildSendTab(List<Device> connectedDevices) {
    return Column(
      children: [
        // Device Selection
        Padding(
          padding: const EdgeInsets.all(20),
          child: AppCard(
            elevated: false,
            backgroundColor: AppTheme.surfaceVariant,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Target Device',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: AppTheme.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 12),
                Container(
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.borderColor),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<Device>(
                      isExpanded: true,
                      value: _selectedDevice,
                      hint: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          'Select a device',
                          style: TextStyle(color: AppTheme.textTertiary),
                        ),
                      ),
                      icon: const Padding(
                        padding: EdgeInsets.only(right: 16),
                        child: Icon(Icons.keyboard_arrow_down_rounded),
                      ),
                      items: connectedDevices.map((device) {
                        return DropdownMenuItem(
                          value: device,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: AppTheme.primaryColor.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(
                                    Icons.smartphone_rounded,
                                    size: 16,
                                    color: AppTheme.primaryColor,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(device.name),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                      onChanged: (device) {
                        setState(() => _selectedDevice = device);
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // File List
        Expanded(
          child: _selectedFiles.isEmpty
              ? _buildEmptyFilesState()
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: _selectedFiles.length,
                  itemBuilder: (context, index) {
                    final file = _selectedFiles[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: AppCard(
                        elevated: false,
                        backgroundColor: AppTheme.surfaceVariant,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: AppTheme.accentColor.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                Icons.file_present_rounded,
                                color: AppTheme.accentColor,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    file.name,
                                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                          fontWeight: FontWeight.w500,
                                        ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    '${(file.size / 1024).toStringAsFixed(1)} KB',
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                          color: AppTheme.textTertiary,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              onPressed: () => setState(() => _selectedFiles.removeAt(index)),
                              icon: Icon(
                                Icons.close_rounded,
                                color: AppTheme.textTertiary,
                                size: 20,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),

        // Action Buttons
        Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _pickFiles,
                  icon: const Icon(Icons.add_rounded, size: 20),
                  label: const Text('Add Files'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  onPressed: _startTransfer,
                  icon: const Icon(Icons.send_rounded, size: 20),
                  label: const Text('Send'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyFilesState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppTheme.surfaceVariant,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Icon(
              Icons.folder_open_outlined,
              size: 56,
              color: AppTheme.textTertiary,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'No files selected',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap "Add Files" to select files for transfer',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.textTertiary,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveTransfersTab(AsyncValue<List<dynamic>> activeTransfersAsync) {
    return activeTransfersAsync.when(
      loading: () => const Center(
        child: CircularProgressIndicator(color: AppTheme.primaryColor),
      ),
      error: (error, stackTrace) => Center(
        child: AppCard(
          margin: const EdgeInsets.all(24),
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.errorColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  Icons.error_outline_rounded,
                  size: 48,
                  color: AppTheme.errorColor,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Error loading transfers',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                error.toString(),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.textSecondary,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: () => ref.refresh(activeTransfersProvider),
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
      data: (activeTransfers) => activeTransfers.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppTheme.successColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Icon(
                      Icons.check_circle_outline_rounded,
                      size: 56,
                      color: AppTheme.successColor,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'No active transfers',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'All transfers completed successfully',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppTheme.textTertiary,
                        ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: activeTransfers.length,
              itemBuilder: (context, index) {
                final transfer = activeTransfers[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: TransferProgressWidget(
                    transfer: transfer,
                    onPause: () => _handlePause(transfer.fileId),
                    onResume: () => _handleResume(transfer.fileId),
                    onCancel: () => _handleCancel(transfer.fileId),
                  ),
                );
              },
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
