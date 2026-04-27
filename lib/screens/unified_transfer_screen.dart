import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flux/models/file_metadata.dart';
import 'package:flux/models/device.dart';
import 'package:flux/services/transfer_engine_service.dart';
import 'package:flux/services/network_manager_service.dart';
import 'package:flux/services/hotspot_service.dart';
import 'package:flux/services/web_share_service.dart';
import 'package:flux/services/peer_discovery_service.dart';
import 'package:flux/services/bluetooth_service.dart';
import 'package:flux/providers/settings_provider.dart';
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
  late final PeerDiscoveryService _peerDiscovery;
  
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
  double _transferProgress = 0.0;
  double _transferSpeed = 0.0;
  String _transferStatus = '';
  
  // Mode
  bool _isHost = false;
  StreamSubscription? _networkStateSubscription;
  StreamSubscription? _peerDiscoveredSubscription;

  @override
  void initState() {
    super.initState();
    _isHost = widget.initiallyHosting;
    _peerDiscovery = ref.read(peerDiscoveryServiceProvider);
    
    // Listen for peer discoveries
    _peerDiscoveredSubscription = _peerDiscovery.onPeerDiscovered.listen((peer) {
      setState(() {
        _connectedPeer = peer;
        _isConnected = true;
      });
      HapticFeedback.mediumImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Connected to ${peer.name}'),
          backgroundColor: AppTheme.successColor,
        ),
      );
    });
    
    _initializeConnection();
  }

  Future<void> _initializeConnection() async {
    setState(() => _isConnecting = true);
    
    try {
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
      });
      
      // Generate connection info for sharing (includes SSID and session key)
      final deviceName = ref.read(settingsProvider).deviceName;
      await _peerDiscovery.generateConnectionInfo(deviceName, port);
      
      // Start Bluetooth discovery for auto-discovery
      _startAutoDiscovery();
      
      final connectionInfo = _peerDiscovery.myConnectionInfo;
      setState(() {
        _connectionCode = connectionInfo?.code;
        _myIpAddress = connectionInfo?.ipAddress;
        _isConnecting = false;
      });
      
      AppLogger.info('Unified transfer ready on port $port, code: $_connectionCode');
      
    } catch (e) {
      AppLogger.error('Failed to initialize connection', e);
      setState(() => _isConnecting = false);
      _showNetworkError();
    }
  }

  void _startAutoDiscovery() {
    // Discover peers every 10 seconds
    Timer.periodic(const Duration(seconds: 10), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      _peerDiscovery.discoverPeers();
    });
    
    // Initial discovery
    _peerDiscovery.discoverPeers();
    
    // Start Bluetooth discovery if available (Android only)
    if (Platform.isAndroid) {
      _startBluetoothDiscovery();
    }
  }

  Future<void> _startBluetoothDiscovery() async {
    try {
      final bluetoothService = BluetoothService();
      final isAvailable = await bluetoothService.isBluetoothAvailable();
      final isOn = await bluetoothService.isBluetoothOn();
      
      if (isAvailable && isOn) {
        await bluetoothService.startScan(timeout: const Duration(seconds: 10));
        AppLogger.info('Bluetooth discovery started');
      }
    } catch (e) {
      AppLogger.warning('Bluetooth discovery not available', e);
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
          setState(() {
            _transferProgress = progress;
            _transferSpeed = speed;
            _transferStatus = 'Sending file $current of $total';
          });
        },
      );

      // Clear selected files after successful transfer
      setState(() {
        _selectedFiles.clear();
        _transferProgress = 0.0;
        _transferSpeed = 0.0;
        _transferStatus = '';
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

  Future<void> _connectToPeer(String code) async {
    if (!_peerDiscovery.isValidCode(code)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invalid code. Please enter a 6-digit code.'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      return;
    }

    setState(() => _isConnecting = true);

    try {
      // For now, simulate connection with code
      // In real implementation, this would:
      // 1. Parse QR code data containing IP, port, device name
      // 2. Connect to peer via TCP
      // 3. Verify connection
      
      await Future.delayed(const Duration(seconds: 1));
      
      // Create a mock peer for testing
      final mockPeer = Device(
        id: code,
        name: 'Peer Device',
        ipAddress: '192.168.1.100',
        port: 54534,
        type: DeviceType.mobile,
        connectionType: ConnectionType.wifi,
        discoveredAt: DateTime.now(),
      );
      
      setState(() {
        _connectedPeer = mockPeer;
        _isConnected = true;
        _isConnecting = false;
      });
      
      HapticFeedback.mediumImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Connected to ${mockPeer.name}'),
          backgroundColor: AppTheme.successColor,
        ),
      );
      
      AppLogger.info('Connected to peer with code: $code');
    } catch (e) {
      AppLogger.error('Failed to connect to peer', e);
      setState(() => _isConnecting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Connection failed: $e'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
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
                  child: _peerDiscovery.myConnectionInfo != null
                      ? QrImageView(
                          data: _peerDiscovery.myConnectionInfo!.toQrString(),
                          size: 200,
                          backgroundColor: Colors.white,
                        )
                      : const SizedBox(
                          width: 200,
                          height: 200,
                          child: Center(child: CircularProgressIndicator()),
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
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    OutlinedButton.icon(
                      onPressed: _showEnterCodeDialog,
                      icon: const Icon(Icons.keyboard),
                      label: const Text('Enter Code'),
                    ),
                    const SizedBox(width: 16),
                    if (Platform.isAndroid)
                      OutlinedButton.icon(
                        onPressed: _showQrScanner,
                        icon: const Icon(Icons.qr_code_scanner),
                        label: const Text('Scan QR'),
                      ),
                  ],
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
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_isTransferring) ...[
                      // Progress bar
                      Column(
                        children: [
                          LinearProgressIndicator(
                            value: _transferProgress,
                            backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                            valueColor: AlwaysStoppedAnimation(AppTheme.primaryColor),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _transferStatus,
                                style: TextStyle(
                                  color: AppTheme.textSecondary,
                                  fontSize: 12,
                                ),
                              ),
                              Text(
                                '${(_transferProgress * 100).toInt()}%',
                                style: TextStyle(
                                  color: AppTheme.textSecondary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _formatSpeed(_transferSpeed),
                            style: TextStyle(
                              color: AppTheme.textTertiary,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                    ],
                    FilledButton(
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
                  ],
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

  void _showEnterCodeDialog() {
    final controller = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Enter Connection Code'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              maxLength: 6,
              decoration: InputDecoration(
                labelText: '6-digit code',
                hintText: '123456',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                counterText: '',
              ),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 24,
                letterSpacing: 8,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Enter the code shown on your peer\'s device',
              style: TextStyle(
                fontSize: 12,
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final code = controller.text.trim();
              if (code.isNotEmpty) {
                Navigator.pop(context);
                _connectToPeer(code);
              }
            },
            child: const Text('Connect'),
          ),
        ],
      ),
    );
  }

  void _showQrScanner() {
    if (!Platform.isAndroid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('QR scanner not available on desktop - use code entry'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => _QrScannerScreen(
          onScanComplete: (qrData) {
            Navigator.pop(context);
            _handleQrScan(qrData);
          },
        ),
      ),
    );
  }

  Future<void> _handleQrScan(String qrData) async {
    try {
      final connectionInfo = _peerDiscovery.parseConnectionInfo(qrData);
      
      if (connectionInfo == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Invalid or expired QR code'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
        return;
      }

      // Connect to peer using the connection info
      final device = await _peerDiscovery.connectToPeer(connectionInfo);
      
      if (device != null) {
        setState(() {
          _connectedPeer = device;
          _isConnected = true;
        });
        
        HapticFeedback.mediumImpact();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Connected to ${device.name}'),
            backgroundColor: AppTheme.successColor,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to connect to peer'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } catch (e) {
      AppLogger.error('Failed to handle QR scan', e);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
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

  String _formatSpeed(double bytesPerSecond) {
    if (bytesPerSecond < 1024) return '${bytesPerSecond.toStringAsFixed(1)} B/s';
    if (bytesPerSecond < 1024 * 1024) return '${(bytesPerSecond / 1024).toStringAsFixed(1)} KB/s';
    if (bytesPerSecond < 1024 * 1024 * 1024) return '${(bytesPerSecond / (1024 * 1024)).toStringAsFixed(1)} MB/s';
    return '${(bytesPerSecond / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB/s';
  }

  @override
  void dispose() {
    _networkStateSubscription?.cancel();
    _peerDiscoveredSubscription?.cancel();
    _webShareService.stopServer();
    
    // Note: Hotspot management is handled by NetworkManagerService
    super.dispose();
  }
}

/// QR Scanner Screen for scanning connection codes
class _QrScannerScreen extends StatefulWidget {
  final Function(String) onScanComplete;

  const _QrScannerScreen({required this.onScanComplete});

  @override
  State<_QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<_QrScannerScreen> {
  final MobileScannerController _controller = MobileScannerController();
  bool _isScanned = false;

  @override
  void initState() {
    super.initState();
    _controller.start();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_isScanned) return;

    final barcode = capture.barcodes.first;
    if (barcode.rawValue != null) {
      setState(() => _isScanned = true);
      widget.onScanComplete(barcode.rawValue!);
      HapticFeedback.lightImpact();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Scan QR Code',
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
          ),
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.7),
                    Colors.transparent,
                    Colors.transparent,
                    Colors.black.withOpacity(0.7),
                  ],
                ),
              ),
            ),
          ),
          Center(
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                border: Border.all(
                  color: AppTheme.primaryColor,
                  width: 3,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 250,
                    height: 2,
                    color: AppTheme.primaryColor,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Scan Flux QR Code',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    width: 250,
                    height: 2,
                    color: AppTheme.primaryColor,
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: 50,
            left: 0,
            right: 0,
            child: Center(
              child: Text(
                'Point camera at the QR code',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
