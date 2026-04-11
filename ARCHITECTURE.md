# Flux Architecture Documentation

## Overview

Flux follows a clean, layered architecture with clear separation of concerns. The application is built using Flutter for the UI layer and Rust for performance-critical operations.

## Architecture Layers

```
┌─────────────────────────────────────────┐
│         Presentation Layer              │
│  (Screens, Widgets, UI Components)      │
└──────────────┬──────────────────────────┘
               │
┌──────────────▼──────────────────────────┐
│      State Management Layer              │
│  (Riverpod Providers, StateNotifiers)    │
└──────────────┬──────────────────────────┘
               │
┌──────────────▼──────────────────────────┐
│       Business Logic Layer               │
│  (Services, Use Cases, Repositories)     │
└──────────────┬──────────────────────────┘
               │
┌──────────────▼──────────────────────────┐
│         Data Layer                       │
│  (Local Storage, Network, Rust FFI)      │
└─────────────────────────────────────────┘
```

## Layer Details

### 1. Presentation Layer

**Responsibility**: Display UI and handle user interactions

**Components**:
- **Screens**: Full-page UI components
  - `DeviceDiscoveryScreen`: Device discovery and connection
  - `FileTransferScreen`: File transfer interface
  - `SettingsScreen`: App configuration
  - `TransferHistoryScreen`: Transfer history view

- **Widgets**: Reusable UI components
  - `DeviceCard`: Device information display
  - `TransferProgressWidget`: Transfer progress indicator
  - `ConnectionIndicator`: Connection status
  - `FileListItem`: File list item

**Design Patterns**:
- Stateless widgets for presentation
- ConsumerWidget for provider access
- Responsive layouts
- Material Design 3

### 2. State Management Layer

**Responsibility**: Manage application state and reactive updates

**Components**:
- **Providers**: Riverpod providers for state access
  - `connectionProvider`: Network connectivity state
  - `deviceProvider`: Device discovery and management
  - `fileTransferProvider`: File transfer state
  - `settingsProvider`: User preferences

- **StateNotifiers**: Mutable state management
  - `ConnectionNotifier`: Manages connection state
  - `DeviceNotifier`: Manages device list
  - `FileTransferNotifier`: Manages transfers
  - `SettingsNotifier`: Manages settings

**Design Patterns**:
- Riverpod for reactive state
- StateNotifier for mutable state
- Family providers for parameterized access
- Computed providers for derived state

### 3. Business Logic Layer

**Responsibility**: Implement core application logic

**Components**:
- **Services**: Business logic implementation
  - `ConnectivityService`: Network monitoring
  - `BluetoothService`: Bluetooth operations
  - `FileService`: File operations
  - `PermissionService`: Permission handling

- **Use Cases**: High-level operations
  - Device discovery workflow
  - File transfer workflow
  - Settings management

**Design Patterns**:
- Singleton pattern for services
- Dependency injection via providers
- Error handling with Result types
- Logging for debugging

### 4. Data Layer

**Responsibility**: Handle data persistence and external communication

**Components**:
- **Local Storage**
  - SharedPreferences for settings
  - File system for transfers

- **Network Communication**
  - TCP sockets for file transfer
  - UDP for device discovery
  - TLS/SSL for secure connections

- **Rust FFI**
  - Encryption/decryption
  - File hashing
  - Network operations

**Design Patterns**:
- Repository pattern for data access
- Abstraction for storage backends
- Error handling and recovery

## Data Models

### Core Models

```dart
// Device information
Device {
  id: String
  name: String
  ipAddress: String
  port: int
  type: DeviceType
  connectionType: ConnectionType
  isConnected: bool
  isTrusted: bool
}

// File metadata
FileMetadata {
  id: String
  name: String
  size: int
  mimeType: String
  hash: String
  path: String
}

// Transfer status
TransferStatus {
  fileId: String
  fileName: String
  state: TransferState
  totalBytes: int
  transferredBytes: int
  speed: double
  remainingSeconds: int
}

// Connection state
AppConnectionState {
  isInternetConnected: bool
  isBluetoothEnabled: bool
  isWiFiEnabled: bool
  currentWiFiSSID: String?
  deviceIPAddress: String?
}
```

## State Flow

### Device Discovery Flow

```
User Action (Tap Discover)
    ↓
DeviceDiscoveryScreen
    ↓
DeviceProvider.refreshDeviceList()
    ↓
BluetoothService.startDiscovery()
    ↓
Rust: discovery::discover_devices()
    ↓
UDP Broadcast
    ↓
Device Responses
    ↓
Parse & Update State
    ↓
UI Updates
```

### File Transfer Flow

```
User Action (Select Files & Send)
    ↓
FileTransferScreen
    ↓
FileTransferProvider.addTransfer()
    ↓
FileService.prepareTransfer()
    ↓
Rust: crypto::encrypt_aes_gcm()
    ↓
Rust: network::send()
    ↓
Monitor Progress
    ↓
Update TransferStatus
    ↓
Complete Transfer
    ↓
Add to History
```

## Dependency Injection

### Provider Setup

```dart
// Connection provider
final connectionProvider = StateNotifierProvider<ConnectionNotifier, AppConnectionState>((ref) {
  return ConnectionNotifier();
});

// Device provider
final deviceProvider = StateNotifierProvider<DeviceNotifier, List<Device>>((ref) {
  return DeviceNotifier();
});

// File transfer provider
final fileTransferProvider = StateNotifierProvider<FileTransferNotifier, List<TransferStatus>>((ref) {
  return FileTransferNotifier();
});

// Settings provider
final settingsProvider = StateNotifierProvider<SettingsNotifier, AppSettings>((ref) {
  return SettingsNotifier();
});
```

### Service Initialization

```dart
// Services are initialized in main()
Future<void> _initializeServices() async {
  await PermissionService().initialize();
  await ConnectivityService().initialize();
}
```

## Error Handling

### Error Types

```dart
enum ErrorType {
  network,
  permission,
  storage,
  encryption,
  device,
  timeout,
  unknown,
}

class AppError {
  final ErrorType type;
  final String message;
  final StackTrace? stackTrace;
}
```

### Error Handling Strategy

1. **Catch at Service Level**: Services catch and log errors
2. **Propagate to Provider**: Providers handle and update state
3. **Display to User**: UI shows user-friendly error messages
4. **Log for Debugging**: All errors logged for debugging

## Performance Optimization

### Strategies

1. **Lazy Loading**: Screens loaded on demand
2. **Image Caching**: Images cached in memory
3. **Connection Pooling**: Reuse TCP connections
4. **Efficient Chunking**: 1MB chunks for transfers
5. **Rust for Heavy Ops**: Encryption/hashing in Rust

### Metrics

- App startup: < 2 seconds
- File transfer: > 10 MB/s (WiFi)
- Memory usage: < 100 MB
- Battery drain: < 5% per hour

## Testing Strategy

### Unit Tests

```dart
// Test providers
test('FileTransferNotifier adds transfer', () async {
  final notifier = FileTransferNotifier();
  await notifier.addTransfer(transfer);
  expect(notifier.state, hasLength(1));
});

// Test services
test('ConnectivityService detects WiFi', () async {
  final service = ConnectivityService();
  final isWiFi = await service.isWiFiEnabled();
  expect(isWiFi, isTrue);
});
```

### Widget Tests

```dart
// Test screens
testWidgets('DeviceDiscoveryScreen displays devices', (tester) async {
  await tester.pumpWidget(const MyApp());
  expect(find.byType(DeviceCard), findsWidgets);
});
```

### Integration Tests

```dart
// Test complete workflows
testWidgets('Complete file transfer workflow', (tester) async {
  // Discover device
  // Connect to device
  // Select files
  // Transfer files
  // Verify completion
});
```

## Security Architecture

### Encryption

- **Algorithm**: AES-256-GCM
- **Key Size**: 256 bits
- **Nonce Size**: 96 bits
- **Authentication**: Built-in with GCM

### Key Management

- Keys generated per transfer
- Nonces generated randomly
- Keys never stored
- Secure key exchange via device pairing

### Network Security

- TLS/SSL for connections
- Certificate pinning
- Secure device pairing
- Token-based authentication

## Scalability Considerations

### Current Limits

- Max 5 concurrent transfers
- Max 10 trusted devices
- Max 100 transfer history entries

### Future Improvements

- Increase concurrent transfers
- Add cloud sync
- Implement P2P mesh network
- Add group transfers

## Monitoring & Logging

### Logging Levels

- **Debug**: Detailed information for debugging
- **Info**: General information about app flow
- **Warning**: Warning messages for potential issues
- **Error**: Error messages for failures

### Logging Implementation

```dart
AppLogger.debug('Debug message');
AppLogger.info('Info message');
AppLogger.warning('Warning message');
AppLogger.error('Error message', exception);
```

## Future Architecture Improvements

1. **MVVM Pattern**: Implement ViewModel layer
2. **Repository Pattern**: Abstract data access
3. **Dependency Injection**: Use GetIt for DI
4. **Event Bus**: Implement event-driven architecture
5. **Caching Layer**: Add intelligent caching

---

**Last Updated**: 2024
**Version**: 1.0.0
