import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flux/models/device.dart';
import 'package:flux/services/bluetooth_service.dart';
import 'package:flux/utils/logger.dart';

/// Provider for managing discovered and connected devices
final deviceProvider = StateNotifierProvider<DeviceNotifier, List<Device>>((
  ref,
) {
  return DeviceNotifier();
});

/// Provider for getting a specific device by ID
final deviceByIdProvider = Provider.family<Device?, String>((ref, deviceId) {
  final devices = ref.watch(deviceProvider);
  try {
    return devices.firstWhere((device) => device.id == deviceId);
  } catch (e) {
    return null;
  }
});

/// Provider for getting connected devices only
final connectedDevicesProvider = Provider<List<Device>>((ref) {
  final devices = ref.watch(deviceProvider);
  return devices.where((device) => device.isConnected).toList();
});

/// Provider for getting trusted devices only
final trustedDevicesProvider = Provider<List<Device>>((ref) {
  final devices = ref.watch(deviceProvider);
  return devices.where((device) => device.isTrusted).toList();
});

class DeviceNotifier extends StateNotifier<List<Device>> {
  late BluetoothService _bluetoothService;
  final Map<String, Device> _deviceCache = {};

  DeviceNotifier() : super([]) {
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      _bluetoothService = BluetoothService();
      await _bluetoothService.initialize();
      _setupListeners();
      AppLogger.info('DeviceNotifier initialized');
    } catch (e) {
      AppLogger.error('Failed to initialize DeviceNotifier', e);
    }
  }

  void _setupListeners() {
    // Listen for device discovery events
    _bluetoothService.discoveredDevicesStream.listen((devices) {
      _updateDeviceList(devices);
    });

    // Listen for connection state changes
    _bluetoothService.connectionStateStream.listen((event) {
      _handleConnectionStateChange(event);
    });
  }

  void _updateDeviceList(List<Device> discoveredDevices) {
    final updatedDevices = <Device>[];

    // Keep existing devices
    for (final device in state) {
      updatedDevices.add(device);
    }

    // Add new devices
    for (final newDevice in discoveredDevices) {
      final existingIndex = updatedDevices.indexWhere(
        (d) => d.id == newDevice.id,
      );
      if (existingIndex >= 0) {
        updatedDevices[existingIndex] = newDevice;
      } else {
        updatedDevices.add(newDevice);
      }
    }

    state = updatedDevices;
    _deviceCache.clear();
    for (final device in updatedDevices) {
      _deviceCache[device.id] = device;
    }
  }

  void _handleConnectionStateChange(Map<String, dynamic> event) {
    final deviceId = event['deviceId'] as String?;
    final isConnected = event['isConnected'] as bool?;

    if (deviceId != null && isConnected != null) {
      final updatedDevices = state.map((device) {
        if (device.id == deviceId) {
          return device.copyWith(isConnected: isConnected);
        }
        return device;
      }).toList();

      state = updatedDevices;
      _deviceCache.clear();
      for (final device in updatedDevices) {
        _deviceCache[device.id] = device;
      }
    }
  }

  Future<void> connectToDevice(String deviceId) async {
    try {
      AppLogger.info('Connecting to device: $deviceId');
      await _bluetoothService.connectToDeviceById(deviceId);
      AppLogger.info('Connected to device: $deviceId');
    } catch (e) {
      AppLogger.error('Failed to connect to device', e);
      rethrow;
    }
  }

  Future<void> disconnectFromDevice(String deviceId) async {
    try {
      AppLogger.info('Disconnecting from device: $deviceId');
      await _bluetoothService.disconnectFromDeviceById(deviceId);
      AppLogger.info('Disconnected from device: $deviceId');
    } catch (e) {
      AppLogger.error('Failed to disconnect from device', e);
      rethrow;
    }
  }

  Future<void> trustDevice(String deviceId) async {
    try {
      final updatedDevices = state.map((device) {
        if (device.id == deviceId) {
          return device.copyWith(isTrusted: true);
        }
        return device;
      }).toList();

      state = updatedDevices;
      AppLogger.info('Device trusted: $deviceId');
    } catch (e) {
      AppLogger.error('Failed to trust device', e);
      rethrow;
    }
  }

  Future<void> untrustDevice(String deviceId) async {
    try {
      final updatedDevices = state.map((device) {
        if (device.id == deviceId) {
          return device.copyWith(isTrusted: false);
        }
        return device;
      }).toList();

      state = updatedDevices;
      AppLogger.info('Device untrusted: $deviceId');
    } catch (e) {
      AppLogger.error('Failed to untrust device', e);
      rethrow;
    }
  }

  Future<void> removeDevice(String deviceId) async {
    try {
      state = state.where((device) => device.id != deviceId).toList();
      _deviceCache.remove(deviceId);
      AppLogger.info('Device removed: $deviceId');
    } catch (e) {
      AppLogger.error('Failed to remove device', e);
      rethrow;
    }
  }

  Future<void> refreshDeviceList() async {
    try {
      AppLogger.info('Refreshing device list');
      await _bluetoothService.startDiscovery();
    } catch (e) {
      AppLogger.error('Failed to refresh device list', e);
      rethrow;
    }
  }

  Device? getDeviceById(String deviceId) {
    return _deviceCache[deviceId];
  }

  int getConnectedDevicesCount() {
    return state.where((device) => device.isConnected).length;
  }

  int getTrustedDevicesCount() {
    return state.where((device) => device.isTrusted).length;
  }
}
