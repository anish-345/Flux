import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flux/models/file_metadata.dart';
import 'package:flux/services/web_share_service.dart';
import 'package:flux/services/ftp_server_service.dart';
import 'package:flux/services/network_manager_service.dart';
import 'package:flux/config/app_theme.dart';
import 'package:flux/widgets/app_card.dart';
import 'package:flux/utils/logger.dart';

class WebSharingScreen extends ConsumerStatefulWidget {
  const WebSharingScreen({super.key});

  @override
  ConsumerState<WebSharingScreen> createState() => _WebSharingScreenState();
}

class _WebSharingScreenState extends ConsumerState<WebSharingScreen> {
  final WebShareService _webShareService = WebShareService();
  final FtpServerService _ftpService = FtpServerService();
  final NetworkManagerService _networkManager = NetworkManagerService();
  
  bool _isStarting = true;
  bool _isRunning = false;
  String? _serverUrl;
  int? _serverPort;
  int? _ftpPort;
  String? _error;
  
  final List<MapEntry<FileMetadata, String>> _sharedFiles = [];

  @override
  void initState() {
    super.initState();
    _initializeNetworkAndStartServer();
  }

  @override
  void dispose() {
    _webShareService.stopServer();
    _ftpService.stopServer();
    super.dispose();
  }

  Future<void> _initializeNetworkAndStartServer() async {
    try {
      // Check network connection
      final networkResult = await _networkManager.ensureNetworkConnection();
      
      if (!networkResult['success']) {
        setState(() {
          _error = networkResult['error'] ?? 'No network connection available. Please connect to WiFi or enable hotspot.';
          _isStarting = false;
        });
        return;
      }

      // Start HTTP server for web UI
      final httpResult = await _webShareService.startServer(files: _sharedFiles);
      
      // Start FTP server for file transfers (works across networks)
      final ftpResult = await _ftpService.startServer(files: _sharedFiles);
      
      if (mounted) {
        setState(() {
          _serverUrl = httpResult['address'] as String?;
          _serverPort = httpResult['port'] as int?;
          _ftpPort = ftpResult['port'] as int?;
          _isRunning = true;
          _isStarting = false;
        });
        
        AppLogger.info('HTTP server: $_serverUrl, FTP server: port $_ftpPort');
      }
    } catch (e) {
      AppLogger.error('Failed to start servers', e);
      if (mounted) {
        setState(() {
          _error = 'Failed to start servers: $e';
          _isStarting = false;
        });
      }
    }
  }

  Future<void> _pickAndShareFiles() async {
    try {
      final files = await openFiles();
      
      if (files.isEmpty) return;

      final newFiles = <MapEntry<FileMetadata, String>>[];
      
      for (final file in files) {
        final bytes = await file.readAsBytes();
        final metadata = FileMetadata(
          id: DateTime.now().millisecondsSinceEpoch.toString() + file.name,
          name: file.name,
          size: bytes.length,
          mimeType: file.mimeType ?? 'application/octet-stream',
          hash: '',
          path: file.path,
          createdAt: DateTime.now(),
          modifiedAt: DateTime.now(),
        );
        newFiles.add(MapEntry(metadata, file.path));
      }

      setState(() {
        _sharedFiles.addAll(newFiles);
      });

      // Add files to existing servers without changing ports
      if (_isRunning) {
        _webShareService.addFiles(newFiles);
        _ftpService.addFiles(newFiles);
        // Ports remain the same - only add files to existing servers
      }

      HapticFeedback.mediumImpact();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${newFiles.length} file(s) added for sharing'),
            backgroundColor: AppTheme.successColor,
          ),
        );
      }
    } catch (e) {
      AppLogger.error('Failed to pick files', e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to add files: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  void _removeFile(String fileId) {
    setState(() {
      _sharedFiles.removeWhere((f) => f.key.id == fileId);
    });
    
    _webShareService.removeFile(fileId);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('File removed from sharing')),
      );
    }
  }

  Future<void> _restartServer() async {
    setState(() {
      _isStarting = true;
      _error = null;
    });
    await _webShareService.stopServer();
    await _ftpService.stopServer();
    await _initializeNetworkAndStartServer();
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = Platform.isWindows || Platform.isLinux || Platform.isMacOS;
    
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Web Share'),
        actions: [
          if (_isRunning)
            IconButton(
              icon: const Icon(Icons.refresh_rounded),
              onPressed: _restartServer,
              tooltip: 'Restart server',
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(isDesktop ? 32 : 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            _buildHeader(),
            const SizedBox(height: 24),
            
            if (_isStarting) ...[
              _buildLoadingState(),
            ] else if (_error != null) ...[
              _buildErrorState(),
            ] else ...[
              // QR Code Card
              _buildQRCodeCard(),
              const SizedBox(height: 24),
              
              // Add Files Button
              _buildAddFilesButton(),
              const SizedBox(height: 24),
              
              // Shared Files List
              if (_sharedFiles.isNotEmpty) ...[
                SectionHeader(
                  title: 'Shared Files (${_sharedFiles.length})',
                  actionLabel: 'Clear All',
                  onAction: () {
                    setState(() => _sharedFiles.clear());
                    _webShareService.clearFiles();
                  },
                ),
                const SizedBox(height: 12),
                _buildSharedFilesList(),
                const SizedBox(height: 24),
              ],
              
              // Instructions
              _buildInstructions(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Share via Web',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          'Let others download files through their browser',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.textSecondary,
              ),
        ),
        if (_isRunning) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppTheme.successColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: AppTheme.successColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'HTTP: $_serverPort | FTP: $_ftpPort',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.successColor,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Works across any network - even different WiFi/hotspot',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.textTertiary,
                ),
          ),
        ],
      ],
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        children: [
          const SizedBox(height: 40),
          const CircularProgressIndicator(
            color: AppTheme.primaryColor,
          ),
          const SizedBox(height: 20),
          Text(
            'Starting web server...',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppTheme.textSecondary,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Allocating dynamic port',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.textTertiary,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddFilesButton() {
    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        onPressed: _pickAndShareFiles,
        icon: const Icon(Icons.add_rounded),
        label: Text(_sharedFiles.isEmpty ? 'Add Files to Share' : 'Add More Files'),
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }

  Widget _buildSharedFilesList() {
    return Column(
      children: _sharedFiles.map((entry) {
        final file = entry.key;
        return AppCard(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          elevated: false,
          backgroundColor: AppTheme.surfaceVariant,
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.accentColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.file_present_rounded,
                  color: AppTheme.accentColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
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
                      maxLines: 1,
                    ),
                    Text(
                      '${(file.size / 1024 / 1024).toStringAsFixed(2)} MB',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppTheme.textTertiary,
                          ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => _removeFile(file.id),
                icon: Icon(
                  Icons.close_rounded,
                  color: AppTheme.textTertiary,
                  size: 20,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildErrorState() {
    return AppCard(
      padding: const EdgeInsets.all(32),
      child: Column(
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
          const SizedBox(height: 24),
          Text(
            'Connection Error',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            _error!,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.textSecondary,
                ),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: _restartServer,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Try Again'),
          ),
        ],
      ),
    );
  }

  Widget _buildQRCodeCard() {
    return AppCard(
      padding: const EdgeInsets.all(32),
      elevated: true,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppTheme.borderColor),
            ),
            child: QrImageView(
              data: _serverUrl!,
              version: QrVersions.auto,
              size: 200.0,
              backgroundColor: Colors.white,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Scan to Connect',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              _serverUrl!,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppTheme.primaryColor,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInstructions() {
    return AppCard(
      elevated: false,
      backgroundColor: AppTheme.surfaceVariant,
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'How to Use',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 20),
          _buildInfoStep(
            icon: Icons.wifi_rounded,
            text: 'Ensure both devices are on the same WiFi network or hotspot.',
          ),
          const SizedBox(height: 16),
          _buildInfoStep(
            icon: Icons.qr_code_scanner_rounded,
            text: 'Scan the QR code with the other device\'s camera or scanner.',
          ),
          const SizedBox(height: 16),
          _buildInfoStep(
            icon: Icons.file_present_rounded,
            text: 'Files will appear in the browser for instant download.',
          ),
        ],
      ),
    );
  }

  Widget _buildInfoStep({required IconData icon, required String text}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppTheme.surfaceColor,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            color: AppTheme.accentColor,
            size: 22,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            text,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  height: 1.5,
                  color: AppTheme.textSecondary,
                ),
          ),
        ),
      ],
    );
  }
}
