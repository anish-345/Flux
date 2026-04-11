# Flux - Quick Reference Guide

## Essential Commands

### Setup & Installation
```bash
# Initial setup
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs

# Watch for changes during development
flutter pub run build_runner watch

# Generate Rust bindings
flutter pub run flutter_rust_bridge:build
```

### Running the App
```bash
# Android
flutter run -d android

# iOS
flutter run -d ios

# Web
flutter run -d web

# Release build
flutter build apk --release
flutter build ios --release
```

### Code Quality
```bash
# Format code
dart format lib/

# Analyze code
flutter analyze

# Run tests
flutter test

# Run specific test
flutter test test/services/file_service_test.dart
```

### Cleaning
```bash
# Clean Flutter
flutter clean

# Clean Rust
cargo clean

# Full clean
flutter clean && cargo clean
```

## File Locations

### Configuration
- **Theme**: `lib/config/app_theme.dart`
- **Constants**: `lib/config/app_constants.dart`

### Models
- **Device**: `lib/models/device.dart`
- **Files**: `lib/models/file_metadata.dart`
- **Connection**: `lib/models/connection_state.dart`

### Services
- **Base**: `lib/services/base_service.dart`
- **Permissions**: `lib/services/permission_service.dart`
- **Connectivity**: `lib/services/connectivity_service.dart`
- **Bluetooth**: `lib/services/bluetooth_service.dart`
- **Files**: `lib/services/file_service.dart`

### UI
- **Home**: `lib/screens/home_screen.dart`
- **Main**: `lib/main.dart`

### Utilities
- **Logger**: `lib/utils/logger.dart`
- **Extensions**: `lib/utils/extensions.dart`
- **Validators**: `lib/utils/validators.dart`

### Platform Config
- **Android**: `android/app/src/main/AndroidManifest.xml`
- **iOS**: `ios/Runner/Info.plist`

### Documentation
- **Setup**: `SETUP.md`
- **Implementation**: `IMPLEMENTATION_GUIDE.md`
- **Summary**: `PROJECT_SUMMARY.md`
- **Design System**: `.kiro/steering/flux_design_system.md`

## Common Tasks

### Add a New Service
```dart
// 1. Create file: lib/services/my_service.dart
class MyService extends BaseService {
  static final MyService _instance = MyService._internal();
  
  factory MyService() => _instance;
  MyService._internal();
  
  @override
  Future<void> initialize() async {
    await super.initialize();
    // Initialize
  }
}

// 2. Add to main.dart providers
Provider<MyService>(create: (_) => MyService())
```

### Add a New Screen
```dart
// 1. Create file: lib/screens/my_screen.dart
class MyScreen extends StatefulWidget {
  const MyScreen({super.key});
  
  @override
  State<MyScreen> createState() => _MyScreenState();
}

class _MyScreenState extends State<MyScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Screen')),
      body: Center(child: Text('Content')),
    );
  }
}

// 2. Add navigation in home_screen.dart
```

### Add a New Model
```dart
// 1. Create file: lib/models/my_model.dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'my_model.freezed.dart';
part 'my_model.g.dart';

@freezed
class MyModel with _$MyModel {
  const factory MyModel({
    required String id,
    required String name,
  }) = _MyModel;
  
  factory MyModel.fromJson(Map<String, dynamic> json) =>
      _$MyModelFromJson(json);
}

// 2. Generate code
flutter pub run build_runner build --delete-conflicting-outputs
```

### Add a New Provider
```dart
// 1. Create file: lib/providers/my_provider.dart
final myProvider = StateNotifierProvider<MyNotifier, MyState>((ref) {
  return MyNotifier();
});

// 2. Use in widget
Consumer(
  builder: (context, ref, child) {
    final state = ref.watch(myProvider);
    return Text(state.toString());
  },
)
```

### Add Logging
```dart
// Use the AppLogger utility
import 'package:flux/utils/logger.dart';

AppLogger.debug('Debug message');
AppLogger.info('Info message');
AppLogger.warning('Warning message');
AppLogger.error('Error message', exception, stackTrace);
```

### Format Bytes
```dart
import 'package:flux/utils/extensions.dart';

String formatted = StringExtensions.formatBytes(1024 * 1024); // "1.00 MB"
```

### Format Duration
```dart
import 'package:flux/utils/extensions.dart';

String formatted = StringExtensions.formatDuration(Duration(hours: 1, minutes: 30));
// "1:30:00"
```

### Format Speed
```dart
import 'package:flux/utils/extensions.dart';

String formatted = StringExtensions.formatSpeed(1024 * 1024); // "1.00 MB/s"
```

## Color Reference

### Primary Colors
```dart
AppTheme.primaryColor        // #6366F1 (Indigo)
AppTheme.secondaryColor      // #8B5CF6 (Purple)
AppTheme.accentColor         // #06B6D4 (Cyan)
```

### Status Colors
```dart
AppTheme.successColor        // #10B981 (Emerald)
AppTheme.warningColor        // #F59E0B (Amber)
AppTheme.errorColor          // #EF4444 (Red)
AppTheme.infoColor           // #3B82F6 (Blue)
```

### Neutral Colors
```dart
AppTheme.backgroundColor    // #FAFAFA
AppTheme.surfaceColor       // #FFFFFF
AppTheme.borderColor        // #E5E7EB
AppTheme.textPrimary        // #111827
AppTheme.textSecondary      // #6B7280
AppTheme.textTertiary       // #9CA3AF
```

## Constants Reference

### Network
```dart
AppConstants.defaultPort              // 9876
AppConstants.discoveryPort            // 9877
AppConstants.connectionTimeout        // 30 seconds
AppConstants.discoveryTimeout         // 10 seconds
AppConstants.maxConcurrentTransfers   // 3
AppConstants.fileChunkSize            // 1MB
```

### File Transfer
```dart
AppConstants.maxFileSize              // 5GB
AppConstants.allowedFileTypes         // List of types
AppConstants.encryptionKeySize        // 256-bit
AppConstants.encryptionNonceSize      // 96-bit
```

### UI
```dart
AppConstants.animationDuration        // 300ms
AppConstants.shortAnimationDuration   // 150ms
```

## Debugging Tips

### Enable Verbose Logging
```bash
flutter run -v
```

### Check Device Logs
```bash
# Android
adb logcat

# iOS
xcrun simctl spawn booted log stream --predicate 'process == "Runner"'
```

### Debug Bluetooth
```bash
# Android
adb logcat | grep -i bluetooth
```

### Check Permissions
```bash
# Android
adb shell dumpsys package com.example.flux | grep permission
```

### Profile App
```bash
flutter run --profile
```

### Check Memory Usage
```bash
flutter run --profile
# Then use DevTools
```

## Useful Shortcuts

### VS Code
- `Ctrl+Shift+P` - Command palette
- `Ctrl+P` - Quick file open
- `Ctrl+Shift+F` - Find in files
- `Ctrl+H` - Find and replace
- `Ctrl+/` - Toggle comment
- `Alt+Up/Down` - Move line
- `Shift+Alt+Up/Down` - Copy line

### Android Studio
- `Cmd+Shift+O` - Go to class
- `Cmd+Shift+F` - Find in files
- `Cmd+H` - Find and replace
- `Cmd+/` - Toggle comment
- `Cmd+Up/Down` - Move line

## Common Issues & Solutions

### Build Fails
```bash
# Clean and rebuild
flutter clean
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs
flutter run
```

### Rust Compilation Error
```bash
# Update Rust
rustup update

# Clean Rust
cargo clean

# Rebuild
flutter run
```

### Permissions Not Working
```bash
# Reinstall app
flutter clean
flutter run

# Or manually uninstall
adb uninstall com.example.flux
flutter run
```

### Hot Reload Not Working
```bash
# Use hot restart
flutter run
# Press 'R' for hot restart instead of 'r' for hot reload
```

### Bluetooth Not Connecting
```bash
# Check permissions
adb shell dumpsys package com.example.flux | grep permission

# Restart Bluetooth
adb shell svc bluetooth restart

# Restart app
```

## Performance Tips

### Reduce Build Time
```bash
# Use split APKs
flutter build apk --split-per-abi

# Use release mode for testing
flutter run --release
```

### Optimize App Size
```bash
# Build release APK
flutter build apk --release

# Check size
ls -lh build/app/outputs/apk/release/app-release.apk
```

### Improve Startup Time
```dart
// Use const constructors
const MyWidget()

// Lazy load screens
// Use Provider selectors to avoid rebuilds
```

## Testing Commands

### Run All Tests
```bash
flutter test
```

### Run Specific Test File
```bash
flutter test test/services/file_service_test.dart
```

### Run Tests with Coverage
```bash
flutter test --coverage
```

### Generate Coverage Report
```bash
# Install lcov
brew install lcov

# Generate report
genhtml coverage/lcov.info -o coverage/html

# Open report
open coverage/html/index.html
```

## Release Checklist

- [ ] Update version in pubspec.yaml
- [ ] Update version in android/app/build.gradle.kts
- [ ] Update version in ios/Runner/Info.plist
- [ ] Run tests: `flutter test`
- [ ] Build release APK: `flutter build apk --release`
- [ ] Build release IPA: `flutter build ios --release`
- [ ] Test on real devices
- [ ] Update CHANGELOG.md
- [ ] Create git tag
- [ ] Push to repository

## Useful Links

- [Flutter Docs](https://flutter.dev/docs)
- [Dart Docs](https://dart.dev/guides)
- [Material Design 3](https://m3.material.io/)
- [Provider Docs](https://pub.dev/packages/provider)
- [Freezed Docs](https://pub.dev/packages/freezed)
- [Flutter Rust Bridge](https://cjycode.com/flutter_rust_bridge/)
- [Rust Book](https://doc.rust-lang.org/book/)

## Support

For issues:
1. Check documentation files
2. Review code examples
3. Check GitHub issues
4. Create new issue with details

---

**Last Updated**: April 2026
