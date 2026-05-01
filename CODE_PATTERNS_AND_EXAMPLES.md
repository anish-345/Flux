# Flux Project - Code Patterns & Best Practices

**Created:** May 1, 2026

---

## 📋 Table of Contents

1. [State Management Patterns](#state-management-patterns)
2. [Service Implementation](#service-implementation)
3. [Error Handling](#error-handling)
4. [Async Operations](#async-operations)
5. [Security Patterns](#security-patterns)
6. [Testing Patterns](#testing-patterns)
7. [Performance Optimization](#performance-optimization)

---

## State Management Patterns

### Pattern 1: AsyncNotifierProvider for File Transfers

```dart
// Provider definition
final fileTransferProvider =
    AsyncNotifierProvider<FileTransferNotifier, Map<String, TransferStatus>>(
      FileTransferNotifier.new,
    );

// Notifier implementation
class FileTransferNotifier extends AsyncNotifier<Map<String, TransferStatus>> {
  @override
  FutureOr<Map<String, TransferStatus>> build() async {
    // Initialize from storage or return empty map
    return {};
  }

  // Add transfer
  Future<void> addTransfer(TransferStatus transfer) async {
    state = await AsyncValue.guard(() async {
      final current = await future;
      AppLogger.info('Transfer added: ${transfer.fileId}');
      return {...current, transfer.fileId: transfer};
    });
  }

  // Update progress
  Future<void> updateTransferProgress(
    String fileId,
    int transferredBytes,
    double speed,
    int remainingSeconds,
  ) async {
    state = await AsyncValue.guard(() async {
      final current = await future;
      final transfer = current[fileId];
      if (transfer != null) {
        return {...current, fileId: transfer.copyWith(
          transferredBytes: transferredBytes,
          speed: speed,
          remainingSeconds: remainingSeconds,
        )};
      }
      return current;
    });
  }
}

// Usage in widget
class TransferProgressWidget extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transfers = ref.watch(fileTransferProvider);
    
    return transfers.when(
      data: (transferMap) => ListView(
        children: transferMap.values.map((transfer) {
          return TransferCard(transfer: transfer);
        }).toList(),
      ),
      loading: () => CircularProgressIndicator(),
      error: (error, stack) => ErrorWidget(error: error),
    );
  }
}
```

### Pattern 2: StateNotifierProvider for Device Management

```dart
// Provider definition
final deviceProvider = StateNotifierProvider<DeviceNotifier, List<Device>>((ref) {
  return DeviceNotifier();
});

// Notifier implementation
class DeviceNotifier extends StateNotifier<List<Device>> {
  late BluetoothService _bluetoothService;
  final Map<String, Device> _deviceCache = {};

  DeviceNotifier() : super([]) {
    _initialize();
  }

  Future<void> _initialize() async {
    _bluetoothService = BluetoothService();
    await _bluetoothService.initialize();
    _setupListeners();
  }

  void _setupListeners() {
    _bluetoothService.discoveredDevicesStream
        .transform(_throttleDevices())
        .transform(_batchDevices())
        .listen((devices) => _updateDeviceList(devices));
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
        updatedDevices[existingIndex] = newDevice;
      } else {
        updatedDevices.add(newDevice);
      }
    }
    
    state = updatedDevices;
    _updateCache(updatedDevices);
  }

  void _updateCache(List<Device> devices) {
    _deviceCache.clear();
    for (final device in devices) {
      _deviceCache[device.id] = device;
    }
  }

  Future<void> connectToDevice(String deviceId) async {
    try {
      AppLogger.info('Connecting to device: $deviceId');
      await _bluetoothService.connectToDeviceById(deviceId);
    } catch (e) {
      AppLogger.error('Failed to connect to device', e);
      rethrow;
    }
  }
}

// Usage in widget
class DeviceListScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final devices = ref.watch(deviceProvider);
    
    return ListView.builder(
      itemCount: devices.length,
      itemBuilder: (context, index) {
        final device = devices[index];
        return DeviceCard(
          device: device,
          onConnect: () => ref.read(deviceProvider.notifier)
              .connectToDevice(device.id),
        );
      },
    );
  }
}
```

### Pattern 3: Derived Providers

```dart
// Filter active transfers
final activeTransfersProvider = Provider<AsyncValue<List<TransferStatus>>>((ref) {
  final transfers = ref.watch(fileTransferProvider);
  return transfers.whenData(
    (map) => map.values.where((t) => t.state.isActive).toList(),
  );
});

// Calculate total progress
final totalTransferProgressProvider = Provider<double>((ref) {
  final transfers = ref.watch(fileTransferProvider);

  return transfers.when(
    data: (map) {
      if (map.isEmpty) return 0.0;
      final totalBytes = map.values.fold<int>(0, (sum, t) => sum + t.totalBytes);
      final transferredBytes = map.values.fold<int>(
        0,
        (sum, t) => sum + t.transferredBytes,
      );
      if (totalBytes == 0) return 0.0;
      return transferredBytes / totalBytes;
    },
    loading: () => 0.0,
    error: (error, stackTrace) => 0.0,
  );
});

// Usage
class OverallProgressWidget extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progress = ref.watch(totalTransferProgressProvider);
    
    return LinearProgressIndicator(value: progress);
  }
}
```

---

## Service Implementation

### Pattern 1: Singleton Service with Logging

```dart
abstract class BaseService {
  void logDebug(String message) => AppLogger.debug(message);
  void logInfo(String message) => AppLogger.info(message);
  void logWarning(String message) => AppLogger.warning(message);
  void logError(String message, dynamic error) => 
      AppLogger.error(message, error);
}

class FileService extends BaseService {
  static final FileService _instance = FileService._internal();

  factory FileService() {
    return _instance;
  }

  FileService._internal();

  /// Pick files from device
  Future<List<XFile>?> pickFiles({
    String? dialogTitle,
    List<String>? allowedExtensions,
    bool allowMultiple = true,
  }) async {
    try {
      logInfo('Picking files...');

      final typeGroups = allowedExtensions != null
          ? <XTypeGroup>[
              XTypeGroup(label: 'Files', extensions: allowedExtensions),
            ]
          : <XTypeGroup>[];

      final files = allowMultiple
          ? await openFiles(acceptedTypeGroups: typeGroups)
          : [await openFile(acceptedTypeGroups: typeGroups)]
              .whereType<XFile>()
              .toList();

      if (files.isNotEmpty) {
        logInfo('Picked ${files.length} file(s)');
        return files;
      }
      return null;
    } catch (e) {
      logError('Failed to pick files', e);
      return null;
    }
  }

  /// Get file size
  Future<int> getFileSize(String filePath) async {
    try {
      final file = File(filePath);
      final size = await file.length();
      logDebug('File size: $size bytes');
      return size;
    } catch (e) {
      logError('Failed to get file size', e);
      return 0;
    }
  }
}
```

### Pattern 2: Service with Stream Monitoring

```dart
class ConnectivityService extends BaseService {
  static final ConnectivityService _instance = 
      ConnectivityService._internal();

  factory ConnectivityService() {
    return _instance;
  }

  ConnectivityService._internal();

  final Connectivity _connectivity = Connectivity();
  final NetworkInfo _networkInfo = NetworkInfo();

  /// Stream of connectivity changes
  Stream<ConnectivityResult> get connectivityStream =>
      _connectivity.onConnectivityChanged;

  /// Get current connectivity status
  Future<ConnectivityResult> getConnectivityStatus() async {
    try {
      final result = await _connectivity.checkConnectivity();
      logDebug('Connectivity status: $result');
      return result;
    } catch (e) {
      logError('Failed to get connectivity status', e);
      return ConnectivityResult.none;
    }
  }

  /// Check if device is connected to internet
  Future<bool> isConnectedToInternet() async {
    try {
      final result = await getConnectivityStatus();
      return result == ConnectivityResult.mobile ||
          result == ConnectivityResult.wifi ||
          result == ConnectivityResult.ethernet;
    } catch (e) {
      logError('Failed to check internet connection', e);
      return false;
    }
  }

  /// Listen to connectivity changes
  Stream<ConnectivityResult> onConnectivityChanged() {
    return _connectivity.onConnectivityChanged;
  }
}

// Usage in provider
final connectionProvider = 
    StateNotifierProvider<ConnectionNotifier, AppConnectionState>((ref) {
  return ConnectionNotifier();
});

class ConnectionNotifier extends StateNotifier<AppConnectionState> {
  late StreamSubscription _subscription;

  ConnectionNotifier() : super(AppConnectionState.initial()) {
    _initialize();
  }

  void _initialize() {
    _subscription = ConnectivityService()
        .onConnectivityChanged()
        .listen((result) {
      _updateConnectionState(result);
    });
  }

  void _updateConnectionState(ConnectivityResult result) {
    state = state.copyWith(
      isInternetConnected: result != ConnectivityResult.none,
    );
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
```

### Pattern 3: Encryption Service with Progress Tracking

```dart
class EncryptionService {
  static final EncryptionService _instance = EncryptionService._internal();
  factory EncryptionService() => _instance;
  EncryptionService._internal();

  /// Encrypt file with progress callback
  Future<Uint8List> encryptFile(
    String filePath,
    String base64Key, {
    Function(double progress)? onProgress,
  }) async {
    try {
      final key = encrypt.Key.fromBase64(base64Key);
      final iv = encrypt.IV.fromSecureRandom(16);
      final encrypter = encrypt.Encrypter(
        encrypt.AES(key, mode: encrypt.AESMode.gcm),
      );

      final file = File(filePath);
      final fileBytes = await file.readAsBytes();
      
      final chunkSize = 64 * 1024; // 64KB chunks
      final encryptedChunks = <int>[];
      
      // Add IV at the beginning
      encryptedChunks.addAll(iv.bytes);
      
      for (int i = 0; i < fileBytes.length; i += chunkSize) {
        final end = (i + chunkSize < fileBytes.length) 
            ? i + chunkSize 
            : fileBytes.length;
        final chunk = fileBytes.sublist(i, end);
        
        final encrypted = encrypter.encryptBytes(chunk, iv: iv);
        encryptedChunks.addAll(encrypted.bytes);
        
        // Update progress
        final progress = end / fileBytes.length;
        onProgress?.call(progress);
        
        // Yield to event loop
        await Future.delayed(Duration.zero);
      }

      AppLogger.info('File encrypted successfully: $filePath');
      return Uint8List.fromList(encryptedChunks);
    } catch (e) {
      AppLogger.error('Failed to encrypt file', e);
      rethrow;
    }
  }

  /// Decrypt file with progress callback
  Future<void> decryptFile(
    Uint8List encryptedData,
    String destinationPath,
    String base64Key, {
    Function(double progress)? onProgress,
  }) async {
    try {
      final key = encrypt.Key.fromBase64(base64Key);
      
      // Extract IV from beginning of encrypted data
      final ivBytes = encryptedData.sublist(0, 16);
      final iv = encrypt.IV(Uint8List.fromList(ivBytes));
      
      final encrypter = encrypt.Encrypter(
        encrypt.AES(key, mode: encrypt.AESMode.gcm),
      );

      final chunkSize = 64 * 1024 + 16; // 64KB + GCM tag
      final decryptedChunks = <int>[];
      
      final encryptedContent = encryptedData.sublist(16);
      
      for (int i = 0; i < encryptedContent.length; i += chunkSize) {
        final end = (i + chunkSize < encryptedContent.length) 
            ? i + chunkSize 
            : encryptedContent.length;
        final chunk = encryptedContent.sublist(i, end);
        
        final encrypted = encrypt.Encrypted(Uint8List.fromList(chunk));
        final decrypted = encrypter.decryptBytes(encrypted, iv: iv);
        decryptedChunks.addAll(decrypted);
        
        // Update progress
        final progress = end / encryptedContent.length;
        onProgress?.call(progress);
        
        // Yield to event loop
        await Future.delayed(Duration.zero);
      }

      // Write decrypted file
      final file = File(destinationPath);
      await file.writeAsBytes(decryptedChunks);

      AppLogger.info('File decrypted successfully: $destinationPath');
    } catch (e) {
      AppLogger.error('Failed to decrypt file', e);
      rethrow;
    }
  }
}
```

---

## Error Handling

### Pattern 1: Try-Catch with Logging

```dart
Future<void> performOperation() async {
  try {
    AppLogger.info('Starting operation...');
    
    // Perform operation
    final result = await someAsyncOperation();
    
    AppLogger.info('Operation completed successfully');
    return result;
  } on SpecificException catch (e) {
    AppLogger.warning('Specific error occurred: ${e.message}');
    // Handle specific error
    rethrow;
  } on Exception catch (e, stackTrace) {
    AppLogger.error('Unexpected error occurred', e);
    // Handle generic error
    rethrow;
  }
}
```

### Pattern 2: Result Type Pattern

```dart
// Define result type
typedef Result<T> = ({T? data, String? error});

// Usage
Future<Result<String>> readFile(String path) async {
  try {
    final file = File(path);
    final content = await file.readAsString();
    return (data: content, error: null);
  } catch (e) {
    return (data: null, error: e.toString());
  }
}

// Consume result
final result = await readFile('path/to/file.txt');
if (result.error != null) {
  AppLogger.error('Failed to read file', result.error);
} else {
  print('File content: ${result.data}');
}
```

### Pattern 3: Error Recovery with Retry

```dart
Future<T> retryWithBackoff<T>(
  Future<T> Function() operation, {
  int maxRetries = 3,
  Duration initialDelay = const Duration(milliseconds: 100),
}) async {
  int retryCount = 0;
  Duration delay = initialDelay;

  while (true) {
    try {
      return await operation();
    } catch (e) {
      retryCount++;
      if (retryCount >= maxRetries) {
        AppLogger.error('Operation failed after $maxRetries retries', e);
        rethrow;
      }

      AppLogger.warning(
        'Operation failed, retrying in ${delay.inMilliseconds}ms '
        '(attempt $retryCount/$maxRetries)',
      );

      await Future.delayed(delay);
      delay *= 2; // Exponential backoff
    }
  }
}

// Usage
final data = await retryWithBackoff(
  () => fetchDataFromServer(),
  maxRetries: 3,
);
```

---

## Async Operations

### Pattern 1: Async Initialization

```dart
class MyService {
  static final MyService _instance = MyService._internal();
  
  factory MyService() => _instance;
  MyService._internal();

  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;

    try {
      AppLogger.info('Initializing service...');
      
      // Perform async initialization
      await _loadConfiguration();
      await _setupConnections();
      
      _initialized = true;
      AppLogger.info('Service initialized successfully');
    } catch (e) {
      AppLogger.error('Failed to initialize service', e);
      rethrow;
    }
  }

  Future<void> _loadConfiguration() async {
    // Load configuration
  }

  Future<void> _setupConnections() async {
    // Setup connections
  }
}

// Usage in main.dart
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await MyService().initialize();
    runApp(const MyApp());
  } catch (e) {
    print('Failed to initialize app: $e');
  }
}
```

### Pattern 2: Concurrent Operations

```dart
// Using Future.wait for concurrent operations
Future<void> performConcurrentOperations() async {
  try {
    final results = await Future.wait([
      operation1(),
      operation2(),
      operation3(),
    ]);
    
    AppLogger.info('All operations completed');
  } catch (e) {
    AppLogger.error('One or more operations failed', e);
  }
}

// Using Future.wait with eagerError: false
Future<void> performConcurrentOperationsWithErrorHandling() async {
  try {
    final results = await Future.wait(
      [
        operation1(),
        operation2(),
        operation3(),
      ],
      eagerError: false,
    );
    
    AppLogger.info('All operations completed');
  } catch (e) {
    AppLogger.error('One or more operations failed', e);
  }
}
```

### Pattern 3: Timeout Handling

```dart
Future<T> withTimeout<T>(
  Future<T> Function() operation, {
  Duration timeout = const Duration(seconds: 30),
}) async {
  try {
    return await operation().timeout(
      timeout,
      onTimeout: () {
        throw TimeoutException('Operation timed out after ${timeout.inSeconds}s');
      },
    );
  } catch (e) {
    AppLogger.error('Operation failed or timed out', e);
    rethrow;
  }
}

// Usage
final data = await withTimeout(
  () => fetchDataFromServer(),
  timeout: const Duration(seconds: 10),
);
```

---

## Security Patterns

### Pattern 1: Secure Key Generation

```dart
class KeyManagement {
  /// Generate a secure random encryption key
  static String generateKey() {
    final random = encrypt.SecureRandom(32);
    return base64Encode(random.bytes);
  }

  /// Generate a secure random nonce
  static String generateNonce() {
    final random = encrypt.SecureRandom(12);
    return base64Encode(random.bytes);
  }

  /// Derive key from password with salt
  static String deriveKeyFromPassword(String password, {String? salt}) {
    final saltBytes = salt != null 
        ? base64Decode(salt)
        : encrypt.SecureRandom(16).bytes;
    
    var bytes = utf8.encode(password) + saltBytes;
    for (int i = 0; i < 10000; i++) {
      bytes = sha256.convert(bytes).bytes;
    }
    
    return base64Encode(bytes);
  }
}

// Usage
final key = KeyManagement.generateKey();
final nonce = KeyManagement.generateNonce();
final derivedKey = KeyManagement.deriveKeyFromPassword('password');
```

### Pattern 2: File Integrity Verification

```dart
class FileIntegrity {
  /// Calculate SHA-256 hash of file
  static Future<String> calculateHash(String filePath) async {
    try {
      final file = File(filePath);
      final bytes = await file.readAsBytes();
      final digest = sha256.convert(bytes);
      return digest.toString();
    } catch (e) {
      AppLogger.error('Failed to calculate file hash', e);
      return '';
    }
  }

  /// Verify file integrity
  static Future<bool> verifyIntegrity(
    String filePath,
    String expectedHash,
  ) async {
    try {
      final actualHash = await calculateHash(filePath);
      return actualHash.toLowerCase() == expectedHash.toLowerCase();
    } catch (e) {
      AppLogger.error('Failed to verify file integrity', e);
      return false;
    }
  }
}

// Usage
final hash = await FileIntegrity.calculateHash('path/to/file');
final isValid = await FileIntegrity.verifyIntegrity('path/to/file', hash);
```

---

## Testing Patterns

### Pattern 1: Unit Test for Service

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

void main() {
  group('FileService', () {
    late FileService fileService;

    setUp(() {
      fileService = FileService();
    });

    test('getFileSize returns correct size', () async {
      // Arrange
      const testFilePath = 'test/fixtures/test_file.txt';
      
      // Act
      final size = await fileService.getFileSize(testFilePath);
      
      // Assert
      expect(size, greaterThan(0));
    });

    test('getMimeType returns correct MIME type', () {
      // Arrange
      const filePath = 'document.pdf';
      
      // Act
      final mimeType = fileService.getMimeType(filePath);
      
      // Assert
      expect(mimeType, equals('application/pdf'));
    });

    test('getFileExtension returns correct extension', () {
      // Arrange
      const filePath = 'document.pdf';
      
      // Act
      final extension = fileService.getFileExtension(filePath);
      
      // Assert
      expect(extension, equals('pdf'));
    });
  });
}
```

### Pattern 2: Widget Test

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  group('DeviceCard Widget', () {
    testWidgets('displays device information', (WidgetTester tester) async {
      // Arrange
      final device = Device(
        id: '1',
        name: 'Test Device',
        ipAddress: '192.168.1.1',
        port: 8080,
        type: DeviceType.mobile,
        connectionType: ConnectionType.wifi,
        discoveredAt: DateTime.now(),
      );

      // Act
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: DeviceCard(device: device),
            ),
          ),
        ),
      );

      // Assert
      expect(find.text('Test Device'), findsOneWidget);
      expect(find.text('192.168.1.1'), findsOneWidget);
      expect(find.byIcon(Icons.smartphone), findsOneWidget);
    });

    testWidgets('calls onConnect when tapped', (WidgetTester tester) async {
      // Arrange
      bool connectCalled = false;
      final device = Device(
        id: '1',
        name: 'Test Device',
        ipAddress: '192.168.1.1',
        port: 8080,
        type: DeviceType.mobile,
        connectionType: ConnectionType.wifi,
        discoveredAt: DateTime.now(),
      );

      // Act
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: DeviceCard(
                device: device,
                onConnect: () => connectCalled = true,
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.byType(DeviceCard));
      await tester.pumpAndSettle();

      // Assert
      expect(connectCalled, isTrue);
    });
  });
}
```

---

## Performance Optimization

### Pattern 1: Backpressure Handling with Throttling

```dart
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

// Usage
_bluetoothService.discoveredDevicesStream
    .transform(_throttleDevices())
    .listen((devices) => _updateDeviceList(devices));
```

### Pattern 2: Efficient Caching

```dart
class DeviceCache {
  final Map<String, Device> _cache = {};

  void add(Device device) {
    _cache[device.id] = device;
  }

  Device? get(String deviceId) {
    return _cache[deviceId];
  }

  void update(Device device) {
    _cache[device.id] = device;
  }

  void remove(String deviceId) {
    _cache.remove(deviceId);
  }

  void clear() {
    _cache.clear();
  }

  List<Device> getAll() {
    return _cache.values.toList();
  }

  int get size => _cache.length;
}

// Usage
final cache = DeviceCache();
cache.add(device);
final cachedDevice = cache.get(device.id);
```

### Pattern 3: Lazy Loading

```dart
class LazyService {
  static final LazyService _instance = LazyService._internal();
  
  factory LazyService() => _instance;
  LazyService._internal();

  ExpensiveResource? _resource;

  Future<ExpensiveResource> getResource() async {
    if (_resource == null) {
      _resource = await _loadResource();
    }
    return _resource!;
  }

  Future<ExpensiveResource> _loadResource() async {
    AppLogger.info('Loading expensive resource...');
    // Simulate expensive operation
    await Future.delayed(const Duration(seconds: 2));
    return ExpensiveResource();
  }

  void dispose() {
    _resource?.dispose();
    _resource = null;
  }
}

// Usage
final service = LazyService();
final resource = await service.getResource(); // Loaded on first call
final resource2 = await service.getResource(); // Cached on second call
```

---

## Best Practices Summary

### ✅ Do's
- ✅ Use Riverpod for state management
- ✅ Use Freezed for immutable models
- ✅ Implement proper error handling
- ✅ Use structured logging
- ✅ Implement backpressure handling
- ✅ Use async/await for async operations
- ✅ Implement proper lifecycle management
- ✅ Use const constructors
- ✅ Implement proper testing
- ✅ Use security best practices

### ❌ Don'ts
- ❌ Don't use setState for complex state
- ❌ Don't ignore errors
- ❌ Don't use mutable models
- ❌ Don't block the UI thread
- ❌ Don't hardcode values
- ❌ Don't skip error handling
- ❌ Don't use deprecated APIs
- ❌ Don't ignore performance warnings
- ❌ Don't skip testing
- ❌ Don't compromise on security

---

**End of Code Patterns & Examples**

