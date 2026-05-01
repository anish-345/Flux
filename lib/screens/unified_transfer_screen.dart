import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'package:app_settings/app_settings.dart' as app_settings;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flux/models/file_metadata.dart' hide TransferStatus, TransferDirection, TransferHistory;
import 'package:flux/models/device.dart';
import 'package:flux/services/peer_discovery_service.dart';
import 'package:flux/services/transfer_engine_service.dart';
import 'package:flux/services/bluetooth_service.dart';
import 'package:flux/services/web_share_service.dart';
import 'package:flux/providers/network_state_notifier.dart' hide NetworkState;
import 'package:flux/providers/connection_state_provider.dart';
import 'package:flux/providers/settings_provider.dart';
import 'package:flux/services/progress_tracking_service.dart';
import 'package:flux/models/queued_transfer.dart';
import 'package:flux/config/app_theme.dart';
import 'package:flux/utils/logger.dart';
import 'package:flux/widgets/transfer_status_list.dart';
import 'package:flux/widgets/qr_scanner_view.dart';
import 'package:wifi_iot/wifi_iot.dart';

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
  final WebShareService _webShareService = WebShareService();
  late final PeerDiscoveryService _peerDiscovery;
  
  // Connection state (now managed by ConnectionStateProvider)
  String? _connectionCode;
  int? _serverPort;
  
  // Transfer state
  final List<QueuedTransfer> _transferQueue = [];
  bool _isTransferring = false;
  double _transferProgress = 0.0;
  double _transferSpeed = 0.0;
  String _transferStatus = '';
  
  // Loading state
  bool _isInitializing = false;
  String _initializationStatus = '';
  
  // Mode
  StreamSubscription? _peerDiscoveredSubscription;
  StreamSubscription? _connectionNotificationSubscription;
  StreamSubscription? _peerDisconnectedSubscription;

  @override
  void initState() {
    super.initState();
    _peerDiscovery = ref.read(peerDiscoveryServiceProvider);
    
    // NOTE: Don't listen to onPeerDiscovered as it conflicts with connection notifications
    // Connection state is now managed by NetworkTransferService notifications only
    
    // Listen for connection notifications from NetworkTransferService
    final engine = ref.read(transferEngineServiceProvider);
    final connectionNotifier = ref.read(connectionStateProvider.notifier);
    AppLogger.info('🎧 Setting up connection notification listener');
    _connectionNotificationSubscription = engine.networkService.onConnection.listen((notification) {
      AppLogger.info('📨 Received connection notification: ${jsonEncode(notification)}');
      
      if (notification['type'] == 'peer_connected') {
        AppLogger.info('🎯 Host received peer connection from ${notification['deviceName']}');
        
        // Create a device object from the notification
        final device = Device(
          id: notification['deviceCode'],
          name: notification['deviceName'],
          ipAddress: notification['clientAddress']?.split(':')[0] ?? '0.0.0.0',
          port: _serverPort ?? 8080,
          type: DeviceType.mobile,
          connectionType: ConnectionType.wifi,
          discoveredAt: DateTime.now(),
          isConnected: true,
        );
        
        // Update connection state using the provider
        connectionNotifier.onPeerConnected(device);
        
        AppLogger.info('✅ Connection state updated via provider, showing snackbar');
        HapticFeedback.mediumImpact();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${device.name} connected'),
              backgroundColor: AppTheme.successColor,
            ),
          );
        }
      } else if (notification['type'] == 'transfer_started') {
        final file = FileMetadata.fromJson(notification['file']);
        AppLogger.info('📥 Transfer started for file: ${file.name}');
        
        if (mounted) {
          setState(() {
            final transfer = QueuedTransfer(
              id: file.id,
              filePath: file.name,
              deviceId: notification['clientAddress'] ?? 'unknown',
              deviceName: 'Remote Peer',
              fileSize: file.size,
              direction: TransferDirection.receive,
              status: TransferStatus.inProgress,
            );
            _transferQueue.add(transfer);
            _isTransferring = true;
            _transferStatus = 'Receiving ${file.name}...';
          });
          
          _trackTransferProgress(file.id);
        }
      } else if (notification['type'] == 'transfer_completed') {
        final fileId = notification['fileId'];
        AppLogger.info('✅ Transfer completed for file: $fileId');
        
        if (mounted) {
          setState(() {
            final index = _transferQueue.indexWhere((t) => t.id == fileId);
            if (index != -1) {
              _transferQueue[index] = _transferQueue[index].copyWith(
                status: TransferStatus.completed,
                transferredBytes: _transferQueue[index].fileSize,
              );
            }
            _isTransferring = _transferQueue.any((t) => t.status == TransferStatus.inProgress);
            _transferStatus = 'Transfer complete';
          });
        }
      } else {
        AppLogger.info('🔍 Received other notification type: ${notification['type']}');
      }
    });
    
    // Listen for peer disconnections
    _peerDisconnectedSubscription = _peerDiscovery.onPeerDisconnected.listen((peer) {
      AppLogger.info('💔 Peer disconnected: ${peer.name}');
      
      final connectionState = ref.read(connectionStateProvider);
      if (connectionState.connectedPeer?.id == peer.id) {
        ref.read(connectionStateProvider.notifier).onPeerDisconnected();
        
        HapticFeedback.mediumImpact();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${peer.name} disconnected'),
              backgroundColor: AppTheme.errorColor,
            ),
          );
        }
      }
    });
    
    // CRITICAL: Initialize connection AFTER setting up listener to prevent race conditions
    unawaited(_initializeConnection());
  }

  void _trackTransferProgress(String fileId) {
    final progressService = ProgressTrackingService();
    progressService.getProgressStream(fileId).listen((progress) {
      if (mounted) {
        setState(() {
          final index = _transferQueue.indexWhere((t) => t.id == fileId);
          if (index != -1) {
            _transferQueue[index] = _transferQueue[index].copyWith(
              transferredBytes: progress.transferredBytes,
              status: TransferStatus.inProgress,
            );
          }
          
          // Also update global progress bar for visual feedback
          _transferProgress = progress.transferredBytes / progress.totalBytes;
          _transferSpeed = progress.speed;
        });
      }
    });
  }

  Future<void> _initializeConnection() async {
    try {
      setState(() {
        _isInitializing = true;
        _initializationStatus = 'Setting up network connection...';
      });
      
      // Ensure network connection using NetworkStateNotifier
      final networkNotifier = ref.read(networkStateProvider.notifier);
      setState(() {
        _initializationStatus = 'Establishing network connection...';
      });
      var networkResult = await networkNotifier.ensureBestNetworkConnection(
        preferHotspot: widget.initiallyHosting,
      );
      
      if (!networkResult) {
        // Try to auto-enable WiFi before showing error dialog
        if (Platform.isAndroid) {
          try {
            setState(() {
              _initializationStatus = 'Attempting to enable WiFi...';
            });
            AppLogger.info('🔧 Attempting to auto-enable WiFi on Android...');
            // Try to enable WiFi programmatically (Android API < 29)
            final isEnabled = await WiFiForIoTPlugin.isEnabled();
            
            if (!isEnabled) {
              setState(() {
                _initializationStatus = 'Enabling WiFi automatically...';
              });
              try {
                await WiFiForIoTPlugin.setEnabled(true);
                AppLogger.info('✅ WiFi enabled programmatically, retrying connection...');
                setState(() {
                  _initializationStatus = 'WiFi enabled, waiting for connection...';
                });
                // Wait a moment for WiFi to initialize
                await Future.delayed(const Duration(seconds: 2));
                // Retry network connection
                networkResult = await networkNotifier.ensureBestNetworkConnection(
                  preferHotspot: widget.initiallyHosting,
                );
              } catch (e) {
                AppLogger.warning('Failed to enable WiFi programmatically: $e');
              }
            }
          } catch (e) {
            AppLogger.warning('WiFi auto-enable failed: $e');
          }
        }
        
        // If still failed, show error dialog with actionable buttons
        if (!networkResult) {
          _showNetworkError();
          return;
        }
      }
      
      setState(() {
        _initializationStatus = 'Starting file transfer server...';
      });
      // Start server for receiving
      final engine = ref.read(transferEngineServiceProvider);
      final port = await engine.startReceiving();
      
      AppLogger.info('🚀 Server started on port $port');
      setState(() {
        _serverPort = port;
      });
      
      setState(() {
        _initializationStatus = 'Generating connection information...';
      });
      // Generate connection info for sharing (includes SSID and session key)
      final deviceName = ref.read(settingsProvider).deviceName;
      AppLogger.info('📱 Generating connection info for device: $deviceName on port $port');
      await _peerDiscovery.generateConnectionInfo(deviceName, port);
      
      final connectionInfo = _peerDiscovery.myConnectionInfo;
      AppLogger.info('🔗 Final connection info: ${connectionInfo?.toQrString()}');
      
      // Start Bluetooth discovery for auto-discovery
      _startAutoDiscovery();
      
      setState(() {
        _connectionCode = connectionInfo?.code;
        _serverPort = port;
        _isInitializing = false;
        _initializationStatus = '';
      });
      
      AppLogger.info('✅ Connection setup complete');
    } catch (e) {
      setState(() {
        _isInitializing = false;
        _initializationStatus = '';
      });
      AppLogger.error('Failed to initialize connection', e);
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
          // Android: try silent WiFi enable first, then open settings
          if (Platform.isAndroid)
            TextButton.icon(
              onPressed: () async {
                Navigator.pop(context);
                try {
                  // API < 29: enable silently; API 29+ opens system panel
                  await WiFiForIoTPlugin.setEnabled(
                    true,
                    shouldOpenSettings: true,
                  );
                  // Give the radio a moment to come up, then retry
                  await Future.delayed(const Duration(seconds: 2));
                  await _initializeConnection();
                } catch (e) {
                  AppLogger.error('Failed to enable WiFi', e);
                  // Fall back to opening system WiFi settings
                  await app_settings.AppSettings.openAppSettings(
                    type: app_settings.AppSettingsType.wifi,
                  );
                }
              },
              icon: const Icon(Icons.wifi),
              label: const Text('Turn On WiFi'),
            ),
          // iOS / desktop: just open the system WiFi settings page
          if (!Platform.isAndroid)
            TextButton.icon(
              onPressed: () async {
                Navigator.pop(context);
                try {
                  await app_settings.AppSettings.openAppSettings(
                    type: app_settings.AppSettingsType.wifi,
                  );
                  // After user returns from settings, retry
                  await Future.delayed(const Duration(seconds: 1));
                  await _initializeConnection();
                } catch (e) {
                  AppLogger.error('Failed to open WiFi settings', e);
                }
              },
              icon: const Icon(Icons.settings_rounded),
              label: const Text('WiFi Settings'),
            ),
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
      final connectionState = ref.read(connectionStateProvider);
      final files = await openFiles();
      if (files.isEmpty) return;

      for (final file in files) {
        final length = await file.length();
        final transfer = QueuedTransfer(
          filePath: file.path,
          deviceId: connectionState.connectedPeer?.id ?? 'pending',
          deviceName: connectionState.connectedPeer?.name ?? 'Peer',
          fileSize: length,
          direction: TransferDirection.send,
          status: TransferStatus.pending,
        );
        
        setState(() {
          _transferQueue.add(transfer);
        });
      }

      HapticFeedback.mediumImpact();
      
      // If peer connected, offer to send immediately
      if (connectionState.connectedPeer != null) {
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
        title: Text('Send to ${ref.read(connectionStateProvider).connectedPeer?.name ?? 'peer'}?'),
        content: Text(
          '${_transferQueue.where((t) => t.isPending).length} file(s) selected\n'
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
    final connectionState = ref.read(connectionStateProvider);
    final pendingTransfers = _transferQueue.where((t) => t.isPending).toList();
    if (connectionState.connectedPeer == null || pendingTransfers.isEmpty) return;
    
    setState(() => _isTransferring = true);
    
    try {
      final engine = ref.read(transferEngineServiceProvider);
      
      // Convert QueuedTransfer to FileMetadata for the engine
      final filesWithPaths = pendingTransfers.map((t) {
        final metadata = FileMetadata(
          id: t.id,
          name: t.filePath.split(RegExp(r'[/\\]')).last,
          size: t.fileSize,
          mimeType: 'application/octet-stream',
          hash: '',
          path: t.filePath,
          createdAt: DateTime.now(),
          modifiedAt: DateTime.now(),
        );
        return MapEntry(metadata, t.filePath);
      }).toList();

      await engine.sendFiles(
        connectionState.connectedPeer!,
        filesWithPaths,
        onProgress: (current, total, progress, speed, status) {
          if (mounted) {
            setState(() {
              _transferProgress = progress;
              _transferSpeed = speed;
              _transferStatus = status;
              
              // Update individual item progress
              // sendFiles processes them sequentially, so we find the 'current' one
              if (current <= pendingTransfers.length) {
                final activeTransfer = pendingTransfers[current - 1];
                final index = _transferQueue.indexWhere((t) => t.id == activeTransfer.id);
                if (index != -1) {
                  // We don't have exact per-file bytes here from the engine's batch callback
                  // but we can mark it as inProgress
                  _transferQueue[index] = _transferQueue[index].copyWith(
                    status: TransferStatus.inProgress,
                  );
                }
              }
            });
          }
        },
      );

      // Mark all as completed
      setState(() {
        for (var i = 0; i < _transferQueue.length; i++) {
          if (_transferQueue[i].direction == TransferDirection.send && 
              _transferQueue[i].status == TransferStatus.inProgress) {
            _transferQueue[i] = _transferQueue[i].copyWith(
              status: TransferStatus.completed,
              transferredBytes: _transferQueue[i].fileSize,
            );
          }
        }
        _isTransferring = false;
        _transferProgress = 0.0;
        _transferSpeed = 0.0;
        _transferStatus = '';
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Files sent to ${connectionState.connectedPeer!.name}'),
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

    try {
      // Parse connection info from QR code or manual code entry
      // For manual code entry, we'll need to discover peers first
      final discoveredPeers = await _peerDiscovery.discoverPeers();
      
      if (discoveredPeers.isEmpty) {
        throw Exception('No peers found. Please ensure the other device is nearby and Bluetooth is enabled.');
      }

      // Find peer matching the code (or use first discovered peer)
      Device? targetPeer;
      for (final peer in discoveredPeers) {
        if (peer.id.contains(code)) {
          targetPeer = peer;
          break;
        }
      }
      
      // If no exact match, use the first peer (for QR scanning scenario)
      targetPeer ??= discoveredPeers.first;

      // Use actual PeerDiscoveryService to connect with Bluetooth network detection
      final connectionInfo = ConnectionInfo(
        code: code,
        ipAddress: targetPeer.ipAddress,
        port: targetPeer.port,
        deviceName: targetPeer.name,
        ssid: '',
        timestamp: DateTime.now(),
      );

      final bluetoothService = BluetoothService();
      final connectedDevice = await _peerDiscovery.connectToPeer(
        connectionInfo,
        bluetoothService: bluetoothService,
      );

      if (connectedDevice == null) {
        throw Exception('Failed to connect to peer');
      }
      
      ref.read(connectionStateProvider.notifier).onPeerConnected(connectedDevice);
      
      HapticFeedback.mediumImpact();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Connected to ${connectedDevice.name}'),
            backgroundColor: AppTheme.successColor,
          ),
        );
      }
      
      AppLogger.info('Connected to peer with code: $code');
    } catch (e) {
      AppLogger.error('Failed to connect to peer', e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Connection failed: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final networkState = ref.watch(networkStateProvider);
    final isConnecting = networkState.state.name == 'connecting';
    final isConnected = networkState.isConnected;
    final ipAddress = networkState.ipAddress;
    
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.backgroundColor,
        elevation: 0,
        title: Text(widget.initiallyHosting ? 'Hosting Transfer' : 'Joining Transfer'),
        actions: [
          if (isConnected)
            IconButton(
              icon: const Icon(Icons.share_rounded),
              onPressed: _showWebShareDialog,
            ),
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () => _showConnectionInfo(ipAddress),
          ),
        ],
      ),
      body: Stack(
        children: [
          isConnecting 
              ? _buildConnectingView()
              : _buildMainTransferView(ipAddress),
          if (_isInitializing)
            Container(
              color: Colors.black.withValues(alpha: 0.7),
              child: Center(
                child: Card(
                  margin: const EdgeInsets.all(20),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const CircularProgressIndicator(),
                        const SizedBox(height: 16),
                        Text(
                          'Initializing...',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _initializationStatus,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppTheme.textSecondary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
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
            widget.initiallyHosting 
                ? 'Creating hotspot or using WiFi'
                : 'Searching for host...',
            style: TextStyle(color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildMainTransferView(String? ipAddress) {
    return Column(
      children: [
        // Connection Status Card
        Container(
          margin: const EdgeInsets.all(20),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppTheme.primaryColor.withValues(alpha: 0.1),
                AppTheme.accentColor.withValues(alpha: 0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppTheme.primaryColor.withValues(alpha: 0.2),
            ),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: ref.watch(connectionStateProvider).connectedPeer != null 
                          ? AppTheme.successColor 
                          : AppTheme.primaryColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      ref.watch(connectionStateProvider).connectedPeer != null 
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
                          ref.watch(connectionStateProvider).connectedPeer != null 
                              ? 'Connected to ${ref.watch(connectionStateProvider).connectedPeer!.name}'
                              : 'Waiting for peer...',
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'IP: ${ref.watch(connectionStateProvider).connectedPeer?.ipAddress ?? ipAddress ?? '...'}',
                          style: TextStyle(
                            color: AppTheme.textSecondary,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (ref.watch(connectionStateProvider).connectedPeer == null)
                    TextButton(
                      onPressed: _showEnterCodeDialog,
                      child: const Text('Join'),
                    ),
                ],
              ),
              if (ref.watch(connectionStateProvider).connectedPeer != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.successColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
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
        if (ref.watch(connectionStateProvider).connectedPeer == null)
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
                        color: Colors.black.withValues(alpha: 0.05),
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
        if (ref.watch(connectionStateProvider).connectedPeer != null) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Text(
                  'Transfer Queue',
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
            child: TransferStatusList(
              transfers: _transferQueue,
              onRemoveFile: (index) {
                setState(() {
                  _transferQueue.removeAt(index);
                });
              },
            ),
          ),
          if (_transferQueue.isNotEmpty)
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
                            backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.1),
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
                                Text('Processing...'),
                              ],
                            )
                          : Text('Send ${_transferQueue.where((t) => t.isPending).length} Files'),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ],
    );
  }


  void _showConnectionInfo(String? ipAddress) {
    final networkState = ref.read(networkStateProvider);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Connection Info'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoRow('Status', networkState.isConnected ? 'Active' : 'Inactive'),
            _buildInfoRow('Mode', widget.initiallyHosting ? 'Host' : 'Client'),
            _buildInfoRow('IP Address', ipAddress ?? 'Unknown'),
            _buildInfoRow('Port', _serverPort?.toString() ?? 'N/A'),
            _buildInfoRow('Code', _connectionCode ?? 'N/A'),
            if (ref.watch(connectionStateProvider).connectedPeer != null) ...[
              const Divider(height: 24),
              _buildInfoRow('Peer', ref.watch(connectionStateProvider).connectedPeer!.name),
              _buildInfoRow('Peer IP', ref.watch(connectionStateProvider).connectedPeer!.ipAddress),
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
    final shareFiles = _transferQueue.where((t) => t.isPending).map((t) {
      final metadata = FileMetadata(
        id: t.id,
        name: t.filePath.split(RegExp(r'[/\\]')).last,
        size: t.fileSize,
        mimeType: 'application/octet-stream',
        hash: '',
        path: t.filePath,
        createdAt: DateTime.now(),
        modifiedAt: DateTime.now(),
      );
      return MapEntry(metadata, t.filePath);
    }).toList();
    
    _webShareService.startServer(
      files: shareFiles,
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
              child: Builder(
                builder: (context) {
                  final networkState = ref.read(networkStateProvider);
                  final ipAddress = networkState.ipAddress ?? '...';
                  return Column(
                    children: [
                      Text(
                        'http://$ipAddress:${_webShareService.serverPort}',
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
                  );
                },
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
              final networkState = ref.read(networkStateProvider);
              final ipAddress = networkState.ipAddress ?? '...';
              Clipboard.setData(ClipboardData(
                text: 'http://$ipAddress:${_webShareService.serverPort}',
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
        builder: (context) => QrScannerView(
          peerDiscovery: _peerDiscovery,
          onCodeScanned: (qrData) {
            Navigator.pop(context);
            _handleQrScan(qrData);
          },
        ),
      ),
    );
  }

  Future<void> _handleQrScan(String qrData) async {
    try {
      // Parse from encrypted QR string format
      final connectionInfo = ConnectionInfo.fromQrString(qrData);
      
      if (connectionInfo == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Invalid or expired QR code'),
              backgroundColor: AppTheme.errorColor,
            ),
          );
        }
        return;
      }

      // Connect to peer using the connection info
      final bluetoothService = BluetoothService();
      final device = await _peerDiscovery.connectToPeer(
        connectionInfo,
        bluetoothService: bluetoothService,
      );
      
      if (device != null) {
        ref.read(connectionStateProvider.notifier).onPeerConnected(device);
        
        HapticFeedback.mediumImpact();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Connected to ${device.name}'),
              backgroundColor: AppTheme.successColor,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to connect to peer'),
              backgroundColor: AppTheme.errorColor,
            ),
          );
        }
      }
    } catch (e) {
      AppLogger.error('Failed to handle QR scan', e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  String _formatSpeed(double bytesPerSecond) {
    if (bytesPerSecond < 1024) return '${bytesPerSecond.toStringAsFixed(1)} B/s';
    if (bytesPerSecond < 1024 * 1024) return '${(bytesPerSecond / 1024).toStringAsFixed(1)} KB/s';
    if (bytesPerSecond < 1024 * 1024 * 1024) return '${(bytesPerSecond / (1024 * 1024)).toStringAsFixed(1)} MB/s';
    return '${(bytesPerSecond / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB/s';
  }

  @override
  void dispose() {
    _peerDiscoveredSubscription?.cancel();
    _connectionNotificationSubscription?.cancel();
    _peerDisconnectedSubscription?.cancel();
    _webShareService.stopServer();
    super.dispose();
  }
}
