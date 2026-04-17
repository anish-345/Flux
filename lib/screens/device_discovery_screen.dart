import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flux/models/device.dart';
import 'package:flux/providers/device_provider.dart';
import 'package:flux/providers/connection_provider.dart';
import 'package:flux/screens/file_transfer_screen.dart';
import 'package:flux/widgets/device_card.dart';
import 'package:flux/widgets/connection_indicator.dart';
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
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          child: Row(
            children: [
              ConnectionIndicator(
                type: ConnectionType.bluetooth,
                isConnected: connectionState.isBluetoothEnabled,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Connected: ${connectedDevices.length}',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    Text(
                      'Discovered: ${devices.length}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              if (_isDiscovering) ...[
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                const SizedBox(width: 8),
                Text('Scanning…',
                    style: Theme.of(context).textTheme.bodySmall),
              ] else
                TextButton.icon(
                  onPressed: _startDiscovery,
                  icon: const Icon(Icons.refresh, size: 16),
                  label: const Text('Scan'),
                ),
            ],
          ),
        ),

        // ── Search Bar ──
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            decoration: InputDecoration(
              hintText: 'Search devices…',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
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
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.devices_other,
                        size: 72,
                        color: Theme.of(context).colorScheme.outline,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _searchQuery.isEmpty
                            ? 'No devices discovered'
                            : 'No devices match your search',
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      const SizedBox(height: 8),
                      if (_searchQuery.isEmpty)
                        Text(
                          'Make sure Bluetooth is enabled and\ntap Scan to discover nearby devices.',
                          style: Theme.of(context).textTheme.bodySmall,
                          textAlign: TextAlign.center,
                        ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
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
        appBar: AppBar(
          title: const Text('Discover Devices'),
          elevation: 0,
          actions: [
            IconButton(
              icon: _isDiscovering
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.refresh),
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
