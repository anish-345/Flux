# Flux - Cross-Platform File Sharing App

## Project Setup Guide

### Prerequisites
- Flutter SDK 3.10.7 or higher
- Rust toolchain (for native compilation)
- Android SDK (for Android development)
- Xcode (for iOS development)
- Git

### Installation Steps

#### 1. Clone and Setup
```bash
# Clone the repository
git clone <repository-url>
cd flux

# Get Flutter dependencies
flutter pub get

# Generate code (Freezed models, JSON serialization)
flutter pub run build_runner build --delete-conflicting-outputs
```

#### 2. Rust Setup
```bash
# Install Rust (if not already installed)
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh

# Add Android targets
rustup target add aarch64-linux-android armv7-linux-androideabi x86_64-linux-android

# Add iOS targets
rustup target add aarch64-apple-ios x86_64-apple-ios
```

#### 3. Android Setup
```bash
# Update Android SDK
flutter doctor --android-licenses

# Configure Android NDK (if needed)
# Set ANDROID_NDK_HOME environment variable
export ANDROID_NDK_HOME=$ANDROID_HOME/ndk/<version>
```

#### 4. iOS Setup
```bash
# Install iOS dependencies
cd ios
pod install
cd ..
```

### Running the App

#### Android
```bash
# Debug build
flutter run -d android

# Release build
flutter build apk --release
```

#### iOS
```bash
# Debug build
flutter run -d ios

# Release build
flutter build ios --release
```

#### Web (if supported)
```bash
flutter run -d web
```

### Development Workflow

#### Code Generation
After modifying models or services, regenerate code:
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

#### Rust Bridge
After modifying Rust API:
```bash
flutter pub run flutter_rust_bridge:build
```

#### Linting
```bash
flutter analyze
dart format lib/
```

#### Testing
```bash
# Run all tests
flutter test

# Run specific test file
flutter test test/services/file_service_test.dart
```

### Project Structure

```
flux/
├── lib/
│   ├── config/              # App configuration & theme
│   ├── models/              # Data models (Freezed)
│   ├── services/            # Business logic services
│   ├── providers/           # State management (Provider)
│   ├── screens/             # UI screens
│   ├── widgets/             # Reusable widgets
│   ├── utils/               # Utilities & helpers
│   └── main.dart            # App entry point
├── rust/                    # Rust source code
│   └── src/
│       ├── api/             # Rust API modules
│       └── lib.rs
├── android/                 # Android configuration
├── ios/                     # iOS configuration
├── test/                    # Unit & widget tests
├── integration_test/        # Integration tests
├── pubspec.yaml             # Flutter dependencies
└── flutter_rust_bridge.yaml # Rust bridge config
```

### Key Features

#### 1. File Sharing
- Send files via Bluetooth, WiFi, or Hotspot
- Receive files from nearby devices
- Support for large files (up to 5GB)
- Automatic file verification

#### 2. Device Discovery
- Discover nearby devices via Bluetooth
- Discover devices on local WiFi network
- Device pairing and trust management
- Connection history

#### 3. Security
- AES-256-GCM encryption for all transfers
- SHA-256 file verification
- Device authentication via public key exchange
- Secure storage of sensitive data

#### 4. User Interface
- Modern Material Design 3
- Beautiful gradient backgrounds
- Smooth animations and transitions
- Responsive layout for all screen sizes
- Dark mode support

### Configuration

#### App Constants
Edit `lib/config/app_constants.dart` to customize:
- Network ports and timeouts
- File transfer settings
- Encryption parameters
- UI animation durations

#### Theme
Edit `lib/config/app_theme.dart` to customize:
- Color palette
- Typography
- Component styles
- Dark mode colors

### Permissions

#### Android
The app requires the following permissions:
- Bluetooth (scan, connect)
- Location (for device discovery)
- Network (WiFi, hotspot)
- Storage (read/write files)

#### iOS
The app requires the following permissions:
- Bluetooth (peripheral, central)
- Local network
- Location

### Troubleshooting

#### Build Issues
```bash
# Clean build
flutter clean
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs

# Rebuild Rust
cargo clean
flutter run
```

#### Bluetooth Not Working
- Ensure Bluetooth is enabled on device
- Check permissions are granted
- Restart the app
- Restart Bluetooth on device

#### File Transfer Issues
- Check network connectivity
- Verify file permissions
- Ensure sufficient storage space
- Check file size limits

#### Rust Compilation Errors
- Update Rust toolchain: `rustup update`
- Clean Rust build: `cargo clean`
- Rebuild: `flutter run`

### Performance Optimization

#### File Transfer
- Uses 1MB chunks for optimal performance
- Parallel transfers up to 3 concurrent
- Automatic retry on failure
- Resume support for interrupted transfers

#### Memory Management
- Lazy loading of screens
- Efficient image caching
- Proper resource cleanup
- Stream-based file processing

### Testing

#### Unit Tests
```bash
flutter test test/services/
```

#### Widget Tests
```bash
flutter test test/widgets/
```

#### Integration Tests
```bash
flutter test integration_test/
```

### Deployment

#### Android
```bash
# Build release APK
flutter build apk --release

# Build release App Bundle
flutter build appbundle --release
```

#### iOS
```bash
# Build release IPA
flutter build ios --release

# Archive for App Store
flutter build ios --release --no-codesign
```

### Contributing

1. Create a feature branch
2. Make your changes
3. Run tests and linting
4. Submit a pull request

### License

This project is licensed under the MIT License - see LICENSE file for details.

### Support

For issues and questions:
- Check existing issues on GitHub
- Create a new issue with detailed description
- Include device info and error logs

### Resources

- [Flutter Documentation](https://flutter.dev/docs)
- [Rust Book](https://doc.rust-lang.org/book/)
- [Flutter Rust Bridge](https://cjycode.com/flutter_rust_bridge/)
- [Material Design 3](https://m3.material.io/)
