import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flux/models/device.dart';
import 'package:flux/providers/device_provider.dart';
import 'package:flux/providers/connection_provider.dart';
import 'package:flux/screens/file_transfer_screen.dart';
import 'package:flux/widgets/device_card.dart';
import 'package:flux/widgets/app_card.dart';
import 'package:flux/config/app_theme.dart';
import 'package:flux/utils/logger.dart';

class DeviceDiscoveryScreen extends ConsumerStatefulWidget {
  const DeviceDiscoveryScreen({super.key});

  @override
  ConsumerState<DeviceDiscoveryScreen> createState() =>
      _DeviceDiscoveryScreenState();
}

class _DeviceDiscoveryScreenState
    extends ConsumerState<DeviceDiscoveryScreen> {
  String _searchQuery = '';
  bool _isDiscovering = false;

  @override
  void initState() {
    super.initState();
    // Delay so the widget tree is ready before triggering async calls
    WidgetsBinding.instance.addPostFrameCallback((_) => _startDiscovery());
  }

  Future<void> _startDiscovery() async {
    if (!mounted) return;
    try {
      setState(() => _isDiscovering = true);
      await ref.read(deviceProvider.notifier).refreshDeviceList();
      await ref.read(connectionProvider.notifier).startDiscovery();
    } catch (e) {
      AppLogger.error('Failed to start discovery', e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Discovery failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isDiscovering = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final devices = ref.watch(deviceProvider);
    final connectionState = ref.watch(connectionProvider);
    final connectedDevices = ref.watch(connectedDevicesProvider);

    // Determine if we are shown as a push route (has a Navigator above) or
    // embedded in the IndexedStack. If embedded, we supply our own header.
    final isRootInStack =
        ModalRoute.of(context)?.settings.name == null &&
        Navigator.of(context).canPop() == false;

    final filteredDevices = devices
        .where(
          (device) =>
              device.name.toLowerCase().contains(_searchQuery.toLowerCase()),
        )
        .toList();

    final body = Column(
      children: [
        // ── Connection Status Bar ──
        AppCard(
          margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          padding: const EdgeInsets.all(16),
          elevated: false,
          backgroundColor: AppTheme.surfaceVariant,
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: connectionState.isBluetoothEnabled
                      ? AppTheme.accentColor.withValues(alpha: 0.1)
                      : AppTheme.textDisabled.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.bluetooth_rounded,
                  size: 20,
                  color: connectionState.isBluetoothEnabled
                      ? AppTheme.accentColor
                      : AppTheme.textTertiary,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${connectedDevices.length} Connected',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    Text(
                      '${devices.length} Discovered nearby',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppTheme.textTertiary,
                          ),
                    ),
                  ],
                ),
              ),
              if (_isDiscovering) ...[
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ] else
                TextButton.icon(
                  onPressed: _startDiscovery,
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: const Text('Scan'),
                ),
            ],
          ),
        ),

        // ── Search Bar ──
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: TextField(
            decoration: InputDecoration(
              hintText: 'Search devices...',
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear_rounded),
                      onPressed: () => setState(() => _searchQuery = ''),
                    )
                  : null,
            ),
            onChanged: (value) => setState(() => _searchQuery = value),
          ),
        ),

        // ── Device List ──
        Expanded(
          child: filteredDevices.isEmpty
              ? _buildEmptyState(context)
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filteredDevices.length,
                  itemBuilder: (context, index) {
                    final device = filteredDevices[index];
                    return DeviceCard(
                      device: device,
                      onConnect: () => _handleConnect(device),
                      onDisconnect: () => _handleDisconnect(device),
                      onTrust: () => _handleTrust(device),
                      onUntrust: () => _handleUntrust(device),
                      onSendFiles: () => _handleSendFiles(device),
                    );
                  },
                ),
        ),
      ],
    );

    // When pushed as a standalone route, wrap in Scaffold with AppBar
    if (!isRootInStack && Navigator.of(context).canPop()) {
      return Scaffold(
        backgroundColor: AppTheme.backgroundColor,
        appBar: AppBar(
          title: const Text('Discover Devices'),
          actions: [
            IconButton(
              icon: _isDiscovering
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.refresh_rounded),
              onPressed: _isDiscovering ? null : _startDiscovery,
              tooltip: 'Scan again',
            ),
          ],
        ),
        body: body,
      );
    }

    // Embedded inside HomeScreen's IndexedStack — no extra Scaffold
    return body;
  }

  Widget _buildEmptyState(BuildContext context) {
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
              Icons.devices_other_outlined,
              size: 56,
              color: AppTheme.textTertiary,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            _searchQuery.isEmpty
                ? 'No devices discovered'
                : 'No devices match your search',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 8),
          if (_searchQuery.isEmpty)
            Text(
              'Make sure Bluetooth is enabled and\ntap Scan to discover nearby devices.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textTertiary,
                  ),
              textAlign: TextAlign.center,
            ),
          const SizedBox(height: 24),
          if (_searchQuery.isEmpty)
            FilledButton.icon(
              onPressed: _startDiscovery,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Scan Now'),
            ),
        ],
      ),
    );
  }

  // ── Handlers ──────────────────────────────────

  Future<void> _handleConnect(Device device) async {
    try {
      await ref.read(deviceProvider.notifier).connectToDevice(device.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Connected to ${device.name}')),
        );
      }
    } catch (e) {
      AppLogger.error('Failed to connect to device', e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Connection failed: $e')),
        );
      }
    }
  }

  Future<void> _handleDisconnect(Device device) async {
    try {
      await ref.read(deviceProvider.notifier).disconnectFromDevice(device.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Disconnected from ${device.name}')),
        );
      }
    } catch (e) {
      AppLogger.error('Failed to disconnect from device', e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Disconnection failed: $e')),
        );
      }
    }
  }

  Future<void> _handleTrust(Device device) async {
    try {
      await ref.read(deviceProvider.notifier).trustDevice(device.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${device.name} is now trusted')),
        );
      }
    } catch (e) {
      AppLogger.error('Failed to trust device', e);
    }
  }

  Future<void> _handleUntrust(Device device) async {
    try {
      await ref.read(deviceProvider.notifier).untrustDevice(device.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${device.name} is no longer trusted')),
        );
      }
    } catch (e) {
      AppLogger.error('Failed to untrust device', e);
    }
  }

  void _handleSendFiles(Device device) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FileTransferScreen(targetDevice: device),
      ),
    );
  }
}
