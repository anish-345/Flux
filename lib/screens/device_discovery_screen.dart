import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flux/models/device.dart';
import 'package:flux/providers/device_provider.dart';
import 'package:flux/providers/connection_provider.dart';
import 'package:flux/widgets/device_card.dart';
import 'package:flux/widgets/connection_indicator.dart';
import 'package:flux/utils/logger.dart';

class DeviceDiscoveryScreen extends ConsumerStatefulWidget {
  const DeviceDiscoveryScreen({super.key});

  @override
  ConsumerState<DeviceDiscoveryScreen> createState() =>
      _DeviceDiscoveryScreenState();
}

class _DeviceDiscoveryScreenState extends ConsumerState<DeviceDiscoveryScreen> {
  String _searchQuery = '';
  bool _isDiscovering = false;

  @override
  void initState() {
    super.initState();
    _startDiscovery();
  }

  Future<void> _startDiscovery() async {
    try {
      setState(() => _isDiscovering = true);
      await ref.read(deviceProvider.notifier).refreshDeviceList();
      await ref.read(connectionProvider.notifier).startDiscovery();
    } catch (e) {
      AppLogger.error('Failed to start discovery', e);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Discovery failed: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isDiscovering = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final devices = ref.watch(deviceProvider);
    final connectionState = ref.watch(connectionProvider);
    final connectedDevices = ref.watch(connectedDevicesProvider);

    final filteredDevices = devices
        .where(
          (device) =>
              device.name.toLowerCase().contains(_searchQuery.toLowerCase()),
        )
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Discover Devices'),
        elevation: 0,
        actions: [
          IconButton(
            icon: _isDiscovering
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.refresh),
            onPressed: _isDiscovering ? null : _startDiscovery,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Column(
        children: [
          // Connection Status Bar
          Container(
            padding: const EdgeInsets.all(16),
            color: Theme.of(context).colorScheme.surfaceVariant,
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
                        'Connected Devices: ${connectedDevices.length}',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      Text(
                        'Total Discovered: ${devices.length}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search devices...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              ),
              onChanged: (value) {
                setState(() => _searchQuery = value);
              },
            ),
          ),

          // Device List
          Expanded(
            child: filteredDevices.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.devices_other,
                          size: 64,
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
                            'Make sure Bluetooth is enabled',
                            style: Theme.of(context).textTheme.bodySmall,
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
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleConnect(Device device) async {
    try {
      await ref.read(deviceProvider.notifier).connectToDevice(device.id);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Connected to ${device.name}')));
      }
    } catch (e) {
      AppLogger.error('Failed to connect to device', e);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Connection failed: $e')));
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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Disconnection failed: $e')));
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
}
