# Flux Implementation Guide

## Overview
This guide provides detailed instructions for implementing the remaining components of the Flux file sharing application.

## Phase 1: Foundation (Completed ✓)

### Completed Components
- ✓ Design system and theme configuration
- ✓ Data models (Device, FileMetadata, TransferStatus, ConnectionState)
- ✓ Base service architecture
- ✓ Permission service
- ✓ Connectivity service
- ✓ Bluetooth service
- ✓ File service
- ✓ Home screen UI
- ✓ Android/iOS permissions configuration
- ✓ Utility functions and extensions

## Phase 2: State Management (Next)

### Providers to Implement

#### 1. ConnectionProvider
**File**: `lib/providers/connection_provider.dart`

```dart
class ConnectionProvider extends StateNotifier<AppConnectionState> {
  // Monitor network connectivity
  // Track Bluetooth status
  // Track WiFi status
  // Manage device IP address
}
```

**Responsibilities**:
- Monitor internet connectivity
- Track Bluetooth enabled/disabled state
- Track WiFi enabled/disabled state
- Get current device IP address
- Emit state changes

#### 2. DeviceProvider
**File**: `lib/providers/device_provider.dart`

```dart
class DeviceProvider extends StateNotifier<List<Device>> {
  // Discover nearby devices
  // Connect to devices
  // Manage device list
  // Handle device pairing
}
```

**Responsibilities**:
- Discover devices via Bluetooth and WiFi
- Manage discovered devices list
- Handle device connections
- Store trusted devices
- Emit device list updates

#### 3. FileTransferProvider
**File**: `lib/providers/file_transfer_provider.dart`

```dart
class FileTransferProvider extends StateNotifier<List<TransferStatus>> {
  // Track active transfers
  // Manage transfer queue
  // Handle pause/resume
  // Track transfer history
}
```

**Responsibilities**:
- Track active file transfers
- Manage transfer queue
- Handle pause/resume operations
- Calculate transfer speed
- Estimate time remaining
- Store transfer history

#### 4. SettingsProvider
**File**: `lib/providers/settings_provider.dart`

```dart
class SettingsProvider extends StateNotifier<AppSettings> {
  // Store user preferences
  // Manage app configuration
  // Handle theme selection
}
```

**Responsibilities**:
- Store user preferences
- Manage app settings
- Handle theme selection
- Persist settings to local storage

## Phase 3: Screens (Next)

### Screens to Implement

#### 1. Device Discovery Screen
**File**: `lib/screens/device_discovery_screen.dart`

**Features**:
- List of discovered devices
- Connection status for each device
- Connect/disconnect buttons
- Device details modal
- Search/filter devices
- Refresh device list

**UI Components**:
- Device cards with status
- Connection type indicators
- Signal strength display
- Trust/untrust buttons

#### 2. File Transfer Screen
**File**: `lib/screens/file_transfer_screen.dart`

**Features**:
- File picker integration
- Selected files list
- Target device selection
- Transfer progress tracking
- Pause/resume/cancel options
- Transfer speed display
- Time remaining estimate

**UI Components**:
- File list with thumbnails
- Progress bars
- Speed/time indicators
- Action buttons

#### 3. Settings Screen
**File**: `lib/screens/settings_screen.dart`

**Features**:
- Device name configuration
- Theme selection
- Notification settings
- Storage location settings
- Clear cache/history
- About section
- Version information

**UI Components**:
- Settings list tiles
- Toggle switches
- Dropdown selectors
- Text input fields

#### 4. Transfer History Screen
**File**: `lib/screens/transfer_history_screen.dart`

**Features**:
- List of past transfers
- Filter by direction (send/receive)
- Filter by date
- Transfer details
- Retry failed transfers
- Clear history

**UI Components**:
- History list items
- Date grouping
- Status indicators
- Action buttons

## Phase 4: Widgets (Next)

### Reusable Widgets

#### 1. DeviceCard
**File**: `lib/widgets/device_card.dart`

```dart
class DeviceCard extends StatelessWidget {
  final Device device;
  final VoidCallback onConnect;
  final VoidCallback onDisconnect;
  
  // Display device info
  // Show connection status
  // Provide action buttons
}
```

#### 2. TransferProgressWidget
**File**: `lib/widgets/transfer_progress_widget.dart`

```dart
class TransferProgressWidget extends StatelessWidget {
  final TransferStatus transfer;
  final VoidCallback onPause;
  final VoidCallback onResume;
  final VoidCallback onCancel;
  
  // Show progress bar
  // Display speed and time
  // Provide action buttons
}
```

#### 3. ConnectionIndicator
**File**: `lib/widgets/connection_indicator.dart`

```dart
class ConnectionIndicator extends StatelessWidget {
  final ConnectionType type;
  final bool isConnected;
  
  // Show connection status
  // Display connection type icon
  // Animate connection state
}
```

#### 4. FileListItem
**File**: `lib/widgets/file_list_item.dart`

```dart
class FileListItem extends StatelessWidget {
  final FileMetadata file;
  final VoidCallback onSelect;
  final VoidCallback onRemove;
  
  // Display file info
  // Show file icon
  // Provide selection/removal
}
```

## Phase 5: Rust Implementation (Next)

### Rust Modules

#### 1. Crypto Module
**File**: `rust/src/api/crypto.rs`

```rust
pub fn encrypt_aes_gcm(
    plaintext: Vec<u8>,
    key: Vec<u8>,
    nonce: Vec<u8>,
) -> Result<Vec<u8>, String>

pub fn decrypt_aes_gcm(
    ciphertext: Vec<u8>,
    key: Vec<u8>,
    nonce: Vec<u8>,
) -> Result<Vec<u8>, String>

pub fn generate_key() -> Vec<u8>

pub fn generate_nonce() -> Vec<u8>

pub fn hash_sha256(data: Vec<u8>) -> Vec<u8>
```

**Responsibilities**:
- AES-256-GCM encryption/decryption
- Key and nonce generation
- SHA-256 file hashing
- Secure random number generation

#### 2. File Transfer Module
**File**: `rust/src/api/file_transfer.rs`

```rust
pub fn chunk_file(
    file_path: String,
    chunk_size: usize,
) -> Result<Vec<Vec<u8>>, String>

pub fn verify_file_integrity(
    file_path: String,
    expected_hash: String,
) -> Result<bool, String>

pub fn calculate_file_hash(
    file_path: String,
) -> Result<String, String>
```

**Responsibilities**:
- File chunking for transfer
- File integrity verification
- Hash calculation
- Chunk reassembly

#### 3. Network Module
**File**: `rust/src/api/network.rs`

```rust
pub struct NetworkSocket {
    // Socket management
}

impl NetworkSocket {
    pub fn new(address: String, port: u16) -> Result<Self, String>
    pub fn send(&mut self, data: Vec<u8>) -> Result<(), String>
    pub fn receive(&mut self) -> Result<Vec<u8>, String>
    pub fn close(&mut self) -> Result<(), String>
}
```

**Responsibilities**:
- Socket creation and management
- Data sending/receiving
- Connection handling
- Error recovery

#### 4. Discovery Module
**File**: `rust/src/api/discovery.rs`

```rust
pub fn discover_devices(
    timeout_ms: u64,
) -> Result<Vec<DeviceInfo>, String>

pub fn broadcast_presence(
    device_name: String,
    port: u16,
) -> Result<(), String>
```

**Responsibilities**:
- Device discovery protocol
- Broadcast presence
- Device information collection

## Phase 6: Integration (Next)

### Service Integration

#### 1. Connect Services to Providers
- Link ConnectivityService to ConnectionProvider
- Link BluetoothService to DeviceProvider
- Link FileService to FileTransferProvider

#### 2. Implement Transfer Protocol
- Define message format
- Implement handshake
- Handle file transfer
- Verify integrity

#### 3. Add Error Handling
- Network errors
- File access errors
- Encryption errors
- Device connection errors

## Phase 7: Testing (Next)

### Unit Tests
```bash
# Test services
flutter test test/services/

# Test providers
flutter test test/providers/

# Test utilities
flutter test test/utils/
```

### Widget Tests
```bash
# Test screens
flutter test test/screens/

# Test widgets
flutter test test/widgets/
```

### Integration Tests
```bash
# Test complete workflows
flutter test integration_test/
```

## Implementation Checklist

### Phase 2: State Management
- [ ] Create ConnectionProvider
- [ ] Create DeviceProvider
- [ ] Create FileTransferProvider
- [ ] Create SettingsProvider
- [ ] Add provider tests

### Phase 3: Screens
- [ ] Implement DeviceDiscoveryScreen
- [ ] Implement FileTransferScreen
- [ ] Implement SettingsScreen
- [ ] Implement TransferHistoryScreen
- [ ] Add screen navigation
- [ ] Add screen tests

### Phase 4: Widgets
- [ ] Implement DeviceCard
- [ ] Implement TransferProgressWidget
- [ ] Implement ConnectionIndicator
- [ ] Implement FileListItem
- [ ] Add widget tests

### Phase 5: Rust
- [ ] Implement crypto module
- [ ] Implement file transfer module
- [ ] Implement network module
- [ ] Implement discovery module
- [ ] Generate Dart bindings
- [ ] Add Rust tests

### Phase 6: Integration
- [ ] Connect services to providers
- [ ] Implement transfer protocol
- [ ] Add error handling
- [ ] Add logging
- [ ] Test end-to-end

### Phase 7: Testing
- [ ] Write unit tests
- [ ] Write widget tests
- [ ] Write integration tests
- [ ] Achieve 80%+ coverage

### Phase 8: Polish
- [ ] Performance optimization
- [ ] UI refinements
- [ ] Accessibility improvements
- [ ] Documentation
- [ ] Release preparation

## Code Generation Commands

```bash
# Generate all code
flutter pub run build_runner build --delete-conflicting-outputs

# Generate Rust bindings
flutter pub run flutter_rust_bridge:build

# Format code
dart format lib/

# Analyze code
flutter analyze
```

## Next Steps

1. **Implement State Management** (Phase 2)
   - Create all provider classes
   - Connect to services
   - Add state listeners

2. **Build Screens** (Phase 3)
   - Create screen files
   - Add navigation
   - Implement UI logic

3. **Create Widgets** (Phase 4)
   - Build reusable components
   - Add animations
   - Test responsiveness

4. **Implement Rust** (Phase 5)
   - Write crypto functions
   - Implement file operations
   - Add network handling

5. **Integration & Testing** (Phase 6-7)
   - Connect all components
   - Write comprehensive tests
   - Fix bugs and issues

6. **Polish & Release** (Phase 8)
   - Optimize performance
   - Improve UX
   - Prepare for release

## Resources

- [Provider Documentation](https://pub.dev/packages/provider)
- [Freezed Documentation](https://pub.dev/packages/freezed)
- [Flutter Rust Bridge](https://cjycode.com/flutter_rust_bridge/)
- [Material Design 3](https://m3.material.io/)
- [Rust Book](https://doc.rust-lang.org/book/)

## Support

For questions or issues:
1. Check existing documentation
2. Review code examples
3. Check GitHub issues
4. Create new issue with details
