import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flux/models/file_metadata.dart';
import 'package:flux/models/device.dart';
import 'package:flux/services/transfer_engine_service.dart';
import 'package:flux/services/network_manager_service.dart';
import 'package:flux/services/hotspot_service.dart';
import 'package:flux/services/web_share_service.dart';
import 'package:flux/config/app_theme.dart';
import 'package:flux/utils/logger.dart';

/// Unified transfer screen for P2P file sharing
/// Handles both sending and receiving in one screen
/// Automatically manages hotspot and connections
class UnifiedTransferScreen extends ConsumerStatefulWidget {
  final bool initiallyHosting;
  
  const UnifiedTransferScreen({
    super.key,
    this.initiallyHosting = false,
  });

  @override
  ConsumerState<UnifiedTransferScreen> createState() => _UnifiedTransferScreenState();
}

class _UnifiedTransferScreenState extends ConsumerState<UnifiedTransferScreen> {
  final NetworkManagerService _networkManager = NetworkManagerService();
  final HotspotService _hotspotService = HotspotService();
  final WebShareService _webShareService = WebShareService();
  
  // Connection state
  bool _isConnecting = true;
  bool _isConnected = false;
  String? _connectionCode;
  String? _myIpAddress;
  int? _serverPort;
  Device? _connectedPeer;
  
  // Transfer state
  List<FileMetadata> _selectedFiles = [];
  bool _isTransferring = false;
  
  // Mode
  bool _isHost = false;
  StreamSubscription? _networkStateSubscription;

  @override
  void initState() {
    super.initState();
    _isHost = widget.initiallyHosting;
    _initializeConnection();
  }

  Future<void> _initializeConnection() async {
    setState(() => _isConnecting = true);
    
    try {
      // Generate connection code
      await _generateConnectionCode();
      
      // Ensure network connection - app will decide best method
      final networkResult = await _ensureBestNetworkConnection();
      
      if (!networkResult) {
        _showNetworkError();
        return;
      }
      
      // Start server for receiving
      final engine = ref.read(transferEngineServiceProvider);
      final port = await engine.startReceiving();
      
      setState(() {
        _serverPort = port;
        _isConnecting = false;
        _isConnected = true;
      });
      
      AppLogger.info('Unified transfer ready on port $port, code: $_connectionCode');
      
    } catch (e) {
      AppLogger.error('Failed to initialize connection', e);
      setState(() => _isConnecting = false);
      _showNetworkError();
    }
  }

  Future<bool> _ensureBestNetworkConnection() async {
    try {
      // Check current network state
      final currentState = _networkManager.currentState;
      
      // If already on WiFi, use that
      if (currentState == NetworkState.wifiConnected) {
        final ip = await _networkManager.getLocalIpAddress();
        setState(() => _myIpAddress = ip);
        AppLogger.info('Using existing WiFi connection: $ip');
        return true;
      }
      
      // If host, try to enable hotspot
      if (_isHost) {
        final hotspotEnabled = await _hotspotService.enableHotspot();
        if (hotspotEnabled) {
          // Wait a moment for hotspot to be ready
          await Future.delayed(const Duration(seconds: 2));
          final ip = await _networkManager.getLocalIpAddress();
          setState(() => _myIpAddress = ip);
          AppLogger.info('Using hotspot as host: $ip');
          return true;
        }
      }
      
      // Try to connect to peer's hotspot or existing WiFi
      final networkResult = await _networkManager.ensureNetworkConnection();
      if (networkResult['success']) {
        final ip = await _networkManager.getLocalIpAddress();
        setState(() => _myIpAddress = ip);
        AppLogger.info('Network connected: $ip');
        return true;
      }
      
      return false;
    } catch (e) {
      AppLogger.error('Network connection failed', e);
      return false;
    }
  }

  Future<void> _generateConnectionCode() async {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final code = timestamp.toString().substring(timestamp.toString().length - 6);
    setState(() => _connectionCode = code);
  }

  void _showNetworkError() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.wifi_off, color: AppTheme.errorColor),
            SizedBox(width: 12),
            Text('Connection Failed'),
          ],
        ),
        content: const Text(
          'Unable to establish network connection.\n\n'
          'Please ensure:\n'
          '• WiFi is enabled, or\n'
          '• Hotspot can be created\n\n'
          'The app will automatically manage connections.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('Go Back'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              _initializeConnection();
            },
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Future<void> _pickFiles() async {
    try {
      final files = await openFiles();
      if (files.isEmpty) return;

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
        
        setState(() {
          _selectedFiles.add(metadata);
        });
      }

      HapticFeedback.mediumImpact();
      
      // If peer connected, offer to send immediately
      if (_connectedPeer != null) {
        _showSendNowDialog();
      }
    } catch (e) {
      AppLogger.error('Failed to pick files', e);
    }
  }

  void _showSendNowDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Send to ${_connectedPeer?.name}?'),
        content: Text(
          '${_selectedFiles.length} file(s) selected\n'
          'Ready to send to connected peer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Later'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              _sendAllFiles();
            },
            child: const Text('Send Now'),
          ),
        ],
      ),
    );
  }

  Future<void> _sendAllFiles() async {
    if (_connectedPeer == null || _selectedFiles.isEmpty) return;
    
    setState(() => _isTransferring = true);
    
    try {
      final engine = ref.read(transferEngineServiceProvider);
      final filesWithPaths = _selectedFiles
          .where((f) => f.path != null)
          .map((f) => MapEntry(f, f.path!))
          .toList();

      await engine.sendFiles(
        _connectedPeer!,
        filesWithPaths,
        onProgress: (current, total, progress, speed, status) {
          // Update transfer progress
          setState(() {
            // Update active transfer progress
          });
        },
      );

      // Clear selected files after successful transfer
      setState(() {
        _selectedFiles.clear();
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Files sent to ${_connectedPeer!.name}'),
            backgroundColor: AppTheme.successColor,
          ),
        );
      }
    } catch (e) {
      AppLogger.error('Transfer failed', e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Transfer failed: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } finally {
      setState(() => _isTransferring = false);
    }
  }

  void _connectToPeer(String code) {
    // TODO: Implement peer discovery via code
    AppLogger.info('Connecting to peer with code: $code');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.backgroundColor,
        elevation: 0,
        title: Text(_isHost ? 'Hosting Transfer' : 'Joining Transfer'),
        actions: [
          if (_isConnected)
            IconButton(
              icon: const Icon(Icons.share_rounded),
              onPressed: _showWebShareDialog,
            ),
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: _showConnectionInfo,
          ),
        ],
      ),
      body: _isConnecting 
          ? _buildConnectingView()
          : _buildMainTransferView(),
    );
  }

  Widget _buildConnectingView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 80,
            height: 80,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              color: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Setting up connection...',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _isHost 
                ? 'Creating hotspot or using WiFi'
                : 'Searching for host...',
            style: TextStyle(color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildMainTransferView() {
    return Column(
      children: [
        // Connection Status Card
        Container(
          margin: const EdgeInsets.all(20),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppTheme.primaryColor.withOpacity(0.1),
                AppTheme.accentColor.withOpacity(0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppTheme.primaryColor.withOpacity(0.2),
            ),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _connectedPeer != null 
                          ? AppTheme.successColor 
                          : AppTheme.primaryColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      _connectedPeer != null 
                          ? Icons.link_rounded 
                          : Icons.qr_code_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _connectedPeer != null 
                              ? 'Connected to ${_connectedPeer!.name}'
                              : 'Waiting for peer...',
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Code: ${_connectionCode ?? '...'}',
                          style: TextStyle(
                            color: AppTheme.textSecondary,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (_connectedPeer == null)
                    TextButton(
                      onPressed: _showEnterCodeDialog,
                      child: const Text('Join'),
                    ),
                ],
              ),
              if (_connectedPeer != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.successColor.withOpacity(0.1),
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
                        'Ready to share',
                        style: TextStyle(
                          color: AppTheme.successColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),

        // QR Code Section (when not connected)
        if (_connectedPeer == null)
          Expanded(
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 20,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: QrImageView(
                    data: 'FLUX://$_connectionCode@$_myIpAddress:$_serverPort',
                    size: 200,
                    backgroundColor: Colors.white,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Scan to connect instantly',
                  style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),

        // File Selection (when connected)
        if (_connectedPeer != null) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Text(
                  'Files to Share',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                FilledButton.icon(
                  onPressed: _isTransferring ? null : _pickFiles,
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: const Text('Add Files'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: _selectedFiles.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.folder_open_outlined,
                          size: 64,
                          color: AppTheme.textTertiary,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No files selected',
                          style: TextStyle(color: AppTheme.textSecondary),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Add files to start sharing',
                          style: TextStyle(
                            color: AppTheme.textTertiary,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: _selectedFiles.length,
                    itemBuilder: (context, index) {
                      final file = _selectedFiles[index];
                      return _buildFileItem(file, index);
                    },
                  ),
          ),
          if (_selectedFiles.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 20,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: SafeArea(
                child: FilledButton(
                  onPressed: _isTransferring ? null : _sendAllFiles,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(double.infinity, 56),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: _isTransferring
                      ? const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(width: 12),
                            Text('Sending...'),
                          ],
                        )
                      : Text('Send ${_selectedFiles.length} Files'),
                ),
              ),
            ),
        ],
      ],
    );
  }

  Widget _buildFileItem(FileMetadata file, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              _getFileIcon(file.name),
              color: AppTheme.primaryColor,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  file.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                Text(
                  _formatFileSize(file.size),
                  style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () {
              setState(() {
                _selectedFiles.removeAt(index);
              });
            },
            icon: const Icon(Icons.close_rounded),
            color: AppTheme.textTertiary,
          ),
        ],
      ),
    );
  }

  void _showEnterCodeDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Enter Connection Code'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: '6-digit code',
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.number,
          maxLength: 6,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (controller.text.length == 6) {
                Navigator.pop(context);
                _connectToPeer(controller.text);
              }
            },
            child: const Text('Connect'),
          ),
        ],
      ),
    );
  }

  void _showConnectionInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Connection Info'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoRow('Status', _isConnected ? 'Active' : 'Inactive'),
            _buildInfoRow('Mode', _isHost ? 'Host' : 'Client'),
            _buildInfoRow('IP Address', _myIpAddress ?? 'Unknown'),
            _buildInfoRow('Port', _serverPort?.toString() ?? 'N/A'),
            _buildInfoRow('Code', _connectionCode ?? 'N/A'),
            if (_connectedPeer != null) ...[
              const Divider(height: 24),
              _buildInfoRow('Peer', _connectedPeer!.name),
              _buildInfoRow('Peer IP', _connectedPeer!.ipAddress),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(color: AppTheme.textSecondary),
          ),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  void _showWebShareDialog() {
    // Start web share server
    _webShareService.startServer(
      files: _selectedFiles.map((f) => MapEntry(f, f.path ?? '')).toList(),
    );
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Web Share'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Share via web browser\nany WiFi network',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.surfaceVariant,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Text(
                    'http://$_myIpAddress:${_webShareService.serverPort}',
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Works on any device with browser',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.textTertiary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              _webShareService.stopServer();
              Navigator.pop(context);
            },
            child: const Text('Close'),
          ),
          FilledButton(
            onPressed: () {
              // Copy URL to clipboard
              Clipboard.setData(ClipboardData(
                text: 'http://$_myIpAddress:${_webShareService.serverPort}',
              ));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('URL copied to clipboard')),
              );
            },
            child: const Text('Copy URL'),
          ),
        ],
      ),
    );
  }

  IconData _getFileIcon(String fileName) {
    final ext = fileName.split('.').last.toLowerCase();
    switch (ext) {
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
        return Icons.image_rounded;
      case 'mp4':
      case 'mov':
      case 'avi':
        return Icons.video_file_rounded;
      case 'mp3':
      case 'wav':
      case 'flac':
        return Icons.audio_file_rounded;
      case 'pdf':
        return Icons.picture_as_pdf_rounded;
      case 'doc':
      case 'docx':
        return Icons.description_rounded;
      default:
        return Icons.insert_drive_file_rounded;
    }
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  @override
  void dispose() {
    _networkStateSubscription?.cancel();
    _webShareService.stopServer();
    // Note: Hotspot management is handled by NetworkManagerService
    super.dispose();
  }
}
