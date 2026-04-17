import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flux/models/device.dart';
import 'package:flux/services/bluetooth_service.dart';
import 'package:flux/utils/logger.dart';

/// Provider for managing discovered and connected devices with backpressure
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

/// Stream transformer for throttling device discovery events
StreamTransformer<List<Device>, List<Device>> _throttleDevices() {
  DateTime? lastEmit;
  List<Device> bufferedDevices = [];

  return StreamTransformer<List<Device>, List<Device>>.fromHandlers(
    handleData: (devices, sink) {
      final now = DateTime.now();

      // Buffer devices if we're throttling
      if (lastEmit != null &&
          now.difference(lastEmit!) < const Duration(milliseconds: 300)) {
        bufferedDevices.addAll(devices);
        return;
      }

      // Emit current batch
      final allDevices = [...bufferedDevices, ...devices];
      if (allDevices.isNotEmpty) {
        sink.add(allDevices);
        bufferedDevices.clear();
        lastEmit = now;
      }
    },
    handleDone: (sink) {
      // Emit any remaining buffered devices
      if (bufferedDevices.isNotEmpty) {
        sink.add(bufferedDevices);
      }
      sink.close();
    },
  );
}

/// Stream transformer for batching device updates
StreamTransformer<List<Device>, List<Device>> _batchDevices() {
  Timer? batchTimer;
  List<Device> batchBuffer = [];
  final StreamController<List<Device>> controller =
      StreamController<List<Device>>();

  void emitBatch() {
    if (batchBuffer.isNotEmpty) {
      controller.add([...batchBuffer]);
      batchBuffer.clear();
    }
  }

  return StreamTransformer<List<Device>, List<Device>>.fromHandlers(
    handleData: (devices, sink) {
      batchBuffer.addAll(devices);

      // Cancel existing timer
      batchTimer?.cancel();

      // Set new timer to emit batch
      batchTimer = Timer(const Duration(milliseconds: 500), () {
        emitBatch();
      });
    },
    handleDone: (sink) {
      batchTimer?.cancel();
      emitBatch();
      controller.close();
    },
  );
}

class DeviceNotifier extends StateNotifier<List<Device>> {
  late BluetoothService _bluetoothService;
  final Map<String, Device> _deviceCache = {};
  StreamSubscription? _discoverySubscription;
  StreamSubscription? _connectionSubscription;
  Timer? _throttleTimer;

  DeviceNotifier() : super([]) {
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      _bluetoothService = BluetoothService();
      await _bluetoothService.initialize();
      _setupListeners();
      AppLogger.info('DeviceNotifier initialized with backpressure handling');
    } catch (e) {
      AppLogger.error('Failed to initialize DeviceNotifier', e);
    }
  }

  void _setupListeners() {
    // Setup discovery listener with throttling and batching
    _discoverySubscription = _bluetoothService.discoveredDevicesStream
        .transform(_throttleDevices())
        .transform(_batchDevices())
        .listen(
          (devices) => _updateDeviceList(devices),
          onError: (error) {
            AppLogger.error('Device discovery stream error', error);
          },
        );

    // Setup connection state listener
    _connectionSubscription = _bluetoothService.connectionStateStream.listen(
      (event) => _handleConnectionStateChange(event),
      onError: (error) {
        AppLogger.error('Connection state stream error', error);
      },
    );
  }

  void _updateDeviceList(List<Device> discoveredDevices) {
    final updatedDevices = <Device>[];

    // Keep existing devices
    for (final device in state) {
      updatedDevices.add(device);
    }

    // Add new devices with deduplication
    for (final newDevice in discoveredDevices) {
      final existingIndex = updatedDevices.indexWhere(
        (d) => d.id == newDevice.id,
      );
      if (existingIndex >= 0) {
        // Update existing device
        updatedDevices[existingIndex] = newDevice;
      } else {
        // Add new device
        updatedDevices.add(newDevice);
      }
    }

    // Update state and cache
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

  @override
  void dispose() {
    _discoverySubscription?.cancel();
    _connectionSubscription?.cancel();
    _throttleTimer?.cancel();
    super.dispose();
  }
}
