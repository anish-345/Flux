import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flux/models/file_metadata.dart';
import 'package:flux/models/device.dart';
import 'package:flux/services/peer_discovery_service.dart';
import 'package:flux/services/transfer_engine_service.dart';
import 'package:flux/services/network_manager_service.dart';
import 'package:flux/services/bluetooth_service.dart';
import 'package:flux/services/wifi_credential_service.dart';
import 'package:flux/providers/connection_state_provider.dart';
import 'package:flux/config/app_theme.dart';
import 'package:flux/utils/logger.dart';
import 'package:flux/widgets/qr_scanner_view.dart';

/// Unified Send/Receive screen with device discovery
/// Shows QR code for sending and QR scanner for receiving
class SendReceiveScreen extends ConsumerStatefulWidget {
  final bool isSending;

  const SendReceiveScreen({super.key, required this.isSending});

  @override
  ConsumerState<SendReceiveScreen> createState() => _SendReceiveScreenState();
}

class _SendReceiveScreenState extends ConsumerState<SendReceiveScreen> {
  final NetworkManagerService _networkManager = NetworkManagerService();
  final BluetoothService _bluetoothService = BluetoothService();
  final PeerDiscoveryService _peerDiscovery = PeerDiscoveryService();
  final WifiCredentialService _wifiCredService = WifiCredentialService();

  // State
  final List<FileMetadata> _selectedFiles = [];
  final List<Device> _discoveredDevices = [];
  bool _isScanning = false;
  bool _isConnecting = false;
  Device? _selectedDevice;
  String? _connectionCode;
  WifiCredentials? _wifiCredentials; // for desktop WiFi QR

  // For receiving
  bool _isReceiving = false;
  int? _receivePort;
  
  
  @override
  void initState() {
    super.initState();
    
    // CRITICAL: Set up connection state listener before initializing
    // This ensures we don't miss connection notifications
    ref.listen(connectionStateProvider, (previous, next) {
      AppLogger.info('📡 Send/Receive screen: Connection state changed');
      
      if (next.isConnected && previous?.isConnected != true) {
        // Peer just connected
        AppLogger.info('🎉 Send/Receive screen: Peer connected - ${next.connectedPeer?.name}');
        HapticFeedback.mediumImpact();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${next.connectedPeer?.name} connected'),
              backgroundColor: AppTheme.successColor,
            ),
          );
        }
      } else if (!next.isConnected && previous?.isConnected == true) {
        // Peer just disconnected
        AppLogger.info('💔 Send/Receive screen: Peer disconnected');
        HapticFeedback.mediumImpact();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Peer disconnected'),
              backgroundColor: AppTheme.errorColor,
            ),
          );
        }
      }
    });
    
    _initialize();
  }

  Future<void> _initialize() async {
    await _generateConnectionCode();
    // On desktop, pre-load WiFi credentials for the QR code
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      final creds = await _wifiCredService.getCurrentNetworkCredentials(
        fluxPort: 8080,
      );
      if (mounted) setState(() => _wifiCredentials = creds);
    }
    if (widget.isSending) {
      await _startDiscovery();
    } else {
      await _startReceiving();
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _generateConnectionCode() async {
    try {
      // Generate proper connection info with IP, port, and credentials
      final deviceName = Platform.isWindows 
          ? 'Windows Device' 
          : Platform.isMacOS 
              ? 'Mac Device' 
              : Platform.isLinux 
                  ? 'Linux Device' 
                  : 'Mobile Device';
      
      final port = _receivePort ?? 8080;
      final connectionInfo = await _peerDiscovery.generateConnectionInfo(
        deviceName,
        port,
        forceHotspot: widget.isSending, // Force hotspot when sending
      );
      
      setState(() {
        _connectionCode = connectionInfo.toQrString();
      });
      
      AppLogger.info('Generated connection QR for: ${connectionInfo.deviceName}');
    } catch (e) {
      AppLogger.error('Failed to generate connection info', e);
      // Fallback to simple code
      final deviceId = DateTime.now().millisecondsSinceEpoch.toString();
      setState(() {
        _connectionCode = deviceId.substring(deviceId.length - 6);
      });
    }
  }

  Future<void> _startDiscovery() async {
    setState(() => _isScanning = true);

    try {
      // Check network first
      final networkResult = await _networkManager.ensureNetworkConnection();
      if (!networkResult['success']) {
        _showConnectionRequiredDialog();
        setState(() => _isScanning = false);
        return;
      }

      // Start Bluetooth discovery if available
      try {
        await _bluetoothService.startDiscovery();
        // Note: Discovery results handled via provider/state
      } catch (e) {
        AppLogger.warning('Bluetooth discovery not available', e);
      }

      // Also start network-based discovery
      await _startNetworkDiscovery();
    } catch (e) {
      AppLogger.error('Discovery failed', e);
    } finally {
      setState(() => _isScanning = false);
    }
  }

  Future<void> _startNetworkDiscovery() async {
    // Real mDNS discovery via Rust backend — finds all Flux instances on the LAN
    try {
      final peers = await _peerDiscovery.discoverPeersViaMdns(
        timeout: const Duration(seconds: 5),
      );
      if (mounted && peers.isNotEmpty) {
        setState(() {
          for (final peer in peers) {
            if (!_discoveredDevices.any((d) => d.id == peer.id)) {
              _discoveredDevices.add(peer);
            }
          }
        });
        AppLogger.info('mDNS found ${peers.length} Flux peer(s)');
      }
    } catch (e) {
      AppLogger.warning('mDNS network discovery failed: $e');
    }
  }

  Future<void> _startReceiving() async {
    setState(() => _isReceiving = true);

    try {
      // Ensure network is available
      final networkResult = await _networkManager.ensureNetworkConnection();
      if (!networkResult['success']) {
        _showConnectionRequiredDialog();
        setState(() => _isReceiving = false);
        return;
      }

      // Start TCP server to receive files
      final transferEngine = ref.read(transferEngineServiceProvider);
      final port = await transferEngine.startReceiving();
      setState(() => _receivePort = port);

      AppLogger.info('Ready to receive files on port $port');
    } catch (e) {
      AppLogger.error('Failed to start receiving', e);
      setState(() => _isReceiving = false);
    }
  }

  void _showConnectionRequiredDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Connection Required'),
        content: const Text(
          'Please enable WiFi or Bluetooth to transfer files. '
          'You can also use hotspot mode.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              _openConnectionSettings();
            },
            child: const Text('Connect'),
          ),
        ],
      ),
    );
  }

  void _openConnectionSettings() {
    // Open system WiFi/Bluetooth settings
    if (Platform.isAndroid) {
      // For Android, we'd use a platform channel
      // For now, show instructions
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Enable Connection'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildConnectionOption(
                icon: Icons.wifi_rounded,
                title: 'WiFi',
                subtitle: 'Connect to the same WiFi network',
                onTap: () => Navigator.pop(context),
              ),
              const SizedBox(height: 12),
              _buildConnectionOption(
                icon: Icons.bluetooth_rounded,
                title: 'Bluetooth',
                subtitle: 'Enable Bluetooth for nearby devices',
                onTap: () => Navigator.pop(context),
              ),
              const SizedBox(height: 12),
              _buildConnectionOption(
                icon: Icons.wifi_tethering_rounded,
                title: 'Hotspot',
                subtitle: 'Create a hotspot for direct connection',
                onTap: () => Navigator.pop(context),
              ),
            ],
          ),
        ),
      );
    }
  }

  Widget _buildConnectionOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppTheme.surfaceVariant,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: AppTheme.primaryColor),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppTheme.textTertiary),
          ],
        ),
      ),
    );
  }

  Future<void> _pickFiles() async {
    try {
      final files = await openFiles();
      if (files.isEmpty) return;

      final newFiles = <FileMetadata>[];
      for (final file in files) {
        final bytes = await file.readAsBytes();
        newFiles.add(
          FileMetadata(
            id: DateTime.now().millisecondsSinceEpoch.toString() + file.name,
            name: file.name,
            size: bytes.length,
            mimeType: file.mimeType ?? 'application/octet-stream',
            hash: '',
            path: file.path,
            createdAt: DateTime.now(),
            modifiedAt: DateTime.now(),
          ),
        );
      }

      setState(() {
        _selectedFiles.addAll(newFiles);
      });

      HapticFeedback.mediumImpact();
    } catch (e) {
      AppLogger.error('Failed to pick files', e);
    }
  }

  Future<void> _sendToDevice(Device device) async {
    if (_selectedFiles.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select files first')),
      );
      return;
    }

    setState(() {
      _isConnecting = true;
      _selectedDevice = device;
    });

    try {
      final filesWithPaths = _selectedFiles
          .where((f) => f.path != null)
          .map((f) => MapEntry(f, f.path!))
          .toList();

      final transferEngine = ref.read(transferEngineServiceProvider);
      await transferEngine.sendFiles(
        device,
        filesWithPaths,
        onProgress: (current, total, progress, speed, status) {
          // Update progress UI
        },
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Sent ${_selectedFiles.length} file(s) to ${device.name}',
            ),
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
      setState(() => _isConnecting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.backgroundColor,
        elevation: 0,
        title: Text(widget.isSending ? 'Send Files' : 'Receive Files'),
        actions: [
          if (widget.isSending && _selectedFiles.isNotEmpty)
            TextButton(
              onPressed: _pickFiles,
              child: Text('+${_selectedFiles.length} files'),
            ),
        ],
      ),
      body: widget.isSending ? _buildSendView() : _buildReceiveView(),
    );
  }

  Widget _buildSendView() {
    return Column(
      children: [
        // QR Code Section
        Container(
          margin: const EdgeInsets.all(20),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              Text(
                'Scan to Connect',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Text(
                'Have the receiver scan this code',
                style: TextStyle(color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.borderColor),
                ),
                child: QrImageView(
                  data: _connectionCode ?? 'FLUX-CONNECT',
                  size: 200,
                  backgroundColor: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceVariant,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _connectionCode != null 
                      ? 'Ready to connect'
                      : 'Generating...',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
        ),

        // Files Section
        if (_selectedFiles.isEmpty)
          Expanded(
            child: Center(
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
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: _pickFiles,
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('Select Files'),
                  ),
                ],
              ),
            ),
          )
        else
          Expanded(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      Text(
                        'Selected Files (${_selectedFiles.length})',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                      const Spacer(),
                      TextButton.icon(
                        onPressed: _pickFiles,
                        icon: const Icon(Icons.add_rounded, size: 18),
                        label: const Text('Add More'),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: _selectedFiles.length,
                    itemBuilder: (context, index) {
                      final file = _selectedFiles[index];
                      return _buildFileItem(file);
                    },
                  ),
                ),
              ],
            ),
          ),

        // Device Discovery Section
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
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 20,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Nearby Devices',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Spacer(),
                    if (_isScanning)
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                if (_discoveredDevices.isEmpty)
                  Center(
                    child: Column(
                      children: [
                        Icon(
                          Icons.radar_outlined,
                          size: 48,
                          color: AppTheme.textTertiary,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _isScanning
                              ? 'Scanning for devices...'
                              : 'No devices found',
                          style: TextStyle(color: AppTheme.textSecondary),
                        ),
                        if (!_isScanning)
                          TextButton(
                            onPressed: _startDiscovery,
                            child: const Text('Scan Again'),
                          ),
                      ],
                    ),
                  )
                else
                  SizedBox(
                    height: 100,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _discoveredDevices.length,
                      itemBuilder: (context, index) {
                        final device = _discoveredDevices[index];
                        return _buildDeviceChip(device);
                      },
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildReceiveView() {
    return Column(
      children: [
        // QR Scanner Section - Platform specific
        Container(
          margin: const EdgeInsets.all(20),
          height: 300,
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Platform.isAndroid || Platform.isIOS
                ? _buildMobileScanner()
                : _buildDesktopScannerPlaceholder(),
          ),
        ),

        // Status Section
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 20),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: _isReceiving
                          ? AppTheme.successColor
                          : AppTheme.errorColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    _isReceiving ? 'Ready to receive' : 'Not receiving',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
              if (_isReceiving && _receivePort != null) ...[
                const SizedBox(height: 12),
                Text(
                  'Waiting on port $_receivePort',
                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 14),
                ),
              ],
            ],
          ),
        ),

        const Spacer(),

        // Instructions
        Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Icon(
                Icons.qr_code_scanner_rounded,
                size: 48,
                color: AppTheme.textTertiary,
              ),
              const SizedBox(height: 16),
              Text(
                'Scan sender\'s QR code to connect',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 16),
              ),
              const SizedBox(height: 8),
              Text(
                'Or use the connection code',
                style: TextStyle(color: AppTheme.textTertiary, fontSize: 14),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _onQrCodeScanned(String code) {
    AppLogger.info('QR Code scanned: $code');

    // Check if this is a WiFi credential QR (from a desktop device)
    final wifiCreds = WifiCredentials.fromQrString(code);
    if (wifiCreds != null) {
      _handleWifiCredentialQr(wifiCreds);
      return;
    }

    // Otherwise treat as a Flux connection info QR
    final connectionInfo = _peerDiscovery.parseConnectionInfo(code);
    if (connectionInfo != null) {
      _connectToPeer(connectionInfo);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invalid QR code — not a Flux connection'),
        ),
      );
    }
  }

  /// Handle a WiFi credential QR scanned from a desktop device.
  /// On Android: auto-joins the network, then discovers Flux via mDNS.
  /// On other platforms: shows the credentials for manual entry.
  Future<void> _handleWifiCredentialQr(WifiCredentials creds) async {
    if (Platform.isAndroid && creds.password != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Joining "${creds.ssid}"…')));
      final joined = await _wifiCredService.connectToNetwork(creds);
      if (!mounted) return;
      if (joined) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Joined "${creds.ssid}" — scanning for Flux…'),
          ),
        );
        // Give DHCP a moment then discover via mDNS
        await Future.delayed(const Duration(seconds: 2));
        if (!mounted) return;
        await _startNetworkDiscovery();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Could not join "${creds.ssid}" automatically. '
              'Please connect manually in WiFi settings.',
            ),
          ),
        );
      }
    } else {
      // Show credentials for manual connection
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('WiFi Credentials'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Connect to this network to reach the Flux device:'),
              const SizedBox(height: 12),
              _credRow('Network', creds.ssid),
              if (creds.password != null) _credRow('Password', creds.password!),
              if (creds.ipAddress != null)
                _credRow(
                  'Flux address',
                  '${creds.ipAddress}:${creds.fluxPort ?? 8080}',
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Close'),
            ),
            if (creds.password != null)
              FilledButton.icon(
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: creds.password!));
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Password copied')),
                  );
                },
                icon: const Icon(Icons.copy_rounded, size: 16),
                label: const Text('Copy Password'),
              ),
          ],
        ),
      );
    }
  }

  Widget _credRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text('$label: ', style: const TextStyle(fontWeight: FontWeight.w600)),
          Expanded(child: Text(value, overflow: TextOverflow.ellipsis)),
        ],
      ),
    );
  }

  Future<void> _connectToPeer(ConnectionInfo connectionInfo) async {
    try {
      AppLogger.info('Connecting to peer from QR: ${connectionInfo.deviceName}');
      
      setState(() => _isConnecting = true);
      
      // Use PeerDiscoveryService to establish actual connection
      final device = await _peerDiscovery.connectToPeer(
        connectionInfo,
        bluetoothService: _bluetoothService,
      );
      
      if (device != null) {
        AppLogger.info('Successfully connected to peer: ${device.name}');
        
        // Add to discovered devices list
        if (!_discoveredDevices.any((d) => d.id == device.id)) {
          setState(() {
            _discoveredDevices.add(device);
          });
        }
        
        // Show success message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Connected to ${device.name}'),
              backgroundColor: AppTheme.successColor,
            ),
          );
        }
      } else {
        throw Exception('Failed to establish connection to peer');
      }
    } catch (e) {
      AppLogger.error('Failed to connect to peer from QR', e);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to connect: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isConnecting = false);
      }
    }
  }

  Widget _buildFileItem(FileMetadata file) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              _getFileIcon(file.name),
              color: AppTheme.primaryColor,
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
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                Text(
                  _formatFileSize(file.size),
                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () {
              setState(() {
                _selectedFiles.remove(file);
              });
            },
            icon: const Icon(Icons.close_rounded),
            color: AppTheme.textTertiary,
          ),
        ],
      ),
    );
  }

  Widget _buildDeviceChip(Device device) {
    final isSelected = _selectedDevice?.id == device.id;

    return GestureDetector(
      onTap: () => _sendToDevice(device),
      child: Container(
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primaryColor.withValues(alpha: 0.1)
              : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppTheme.primaryColor : AppTheme.borderColor,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppTheme.primaryColor, AppTheme.accentColor],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.smartphone_rounded, color: Colors.white),
            ),
            const SizedBox(height: 8),
            Text(
              device.name,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
            if (_isConnecting && isSelected)
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppTheme.primaryColor,
                ),
              ),
          ],
        ),
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
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  /// Mobile scanner for Android/iOS
  Widget _buildMobileScanner() {
    return QrScannerView(
      peerDiscovery: _peerDiscovery,
      onCodeScanned: _onQrCodeScanned,
      onCancel: () => Navigator.pop(context),
    );
  }

  /// Desktop connection screen — shows the current WiFi credentials as a QR
  /// code so a mobile device can scan and join the same network automatically.
  Widget _buildDesktopScannerPlaceholder() {
    final creds = _wifiCredentials;
    return Container(
      color: Colors.black,
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (creds != null) ...[
                const Text(
                  'Scan to Join This Network',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Point your phone camera at this QR code.\n'
                  'It will join "${creds.ssid}" and connect to Flux automatically.',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.65),
                    fontSize: 13,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: QrImageView(
                    data: creds.toQrString(),
                    version: QrVersions.auto,
                    size: 200,
                    backgroundColor: Colors.white,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.wifi_rounded,
                        color: Colors.white,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        creds.ssid,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (creds.password != null) ...[
                        const SizedBox(width: 12),
                        GestureDetector(
                          onTap: () {
                            Clipboard.setData(
                              ClipboardData(text: creds.password!),
                            );
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Password copied')),
                            );
                          },
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.lock_outline_rounded,
                                color: Colors.white.withValues(alpha: 0.7),
                                size: 14,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                creds.password!,
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.7),
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Icon(
                                Icons.copy_rounded,
                                color: Colors.white.withValues(alpha: 0.5),
                                size: 12,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                const Divider(color: Colors.white24),
                const SizedBox(height: 16),
              ] else ...[
                Icon(
                  Icons.wifi_off_rounded,
                  size: 48,
                  color: Colors.white.withValues(alpha: 0.5),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Not connected to WiFi',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
                const SizedBox(height: 8),
                Text(
                  'Connect to a WiFi network to share credentials via QR code.',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.5),
                    fontSize: 13,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
              ],
              _buildDesktopOption(
                icon: Icons.search_rounded,
                title: 'Scan Network for Flux Devices',
                subtitle: 'Find phones already on this WiFi',
                onTap: () async {
                  final peers = await _peerDiscovery.discoverPeersViaMdns(
                    timeout: const Duration(seconds: 5),
                  );
                  if (!mounted) return;
                  if (peers.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('No Flux devices found on this network'),
                      ),
                    );
                  } else {
                    setState(() {
                      for (final p in peers) {
                        if (!_discoveredDevices.any((d) => d.id == p.id)) {
                          _discoveredDevices.add(p);
                        }
                      }
                    });
                    Navigator.of(context).pop();
                  }
                },
              ),
              const SizedBox(height: 10),
              _buildDesktopOption(
                icon: Icons.keyboard_rounded,
                title: 'Enter Connection Code',
                subtitle: 'Type the 6-digit code from the mobile device',
                onTap: _showEnterCodeDialog,
              ),
              const SizedBox(height: 10),
              _buildDesktopOption(
                icon: Icons.content_paste_rounded,
                title: 'Paste Connection Data',
                subtitle: 'Paste the JSON copied from the sender\'s QR code',
                onTap: _showPasteConnectionDialog,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDesktopOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Row(
            children: [
              Icon(icon, color: Colors.white, size: 28),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.6),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: Colors.white.withValues(alpha: 0.5),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Show dialog to paste full connection JSON from sender
  void _showPasteConnectionDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Paste Connection Data'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'On the sender\'s device, tap the QR code to copy the connection data, then paste it here.',
              style: TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                hintText: 'Paste connection data here…',
                border: OutlineInputBorder(),
              ),
              maxLines: 4,
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final text = controller.text.trim();
              if (text.isNotEmpty) {
                Navigator.pop(ctx);
                _onQrCodeScanned(text);
              }
            },
            child: const Text('Connect'),
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
            hintText: 'e.g., 123456',
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
              if (controller.text.isNotEmpty) {
                _onQrCodeScanned(controller.text);
              }
              Navigator.pop(context);
            },
            child: const Text('Connect'),
          ),
        ],
      ),
    );
  }
}
