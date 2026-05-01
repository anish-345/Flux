---
inclusion: auto
---

# Flux Design System & Architecture Guide

**Quick Navigation:** [Design System](#design-system) | [Architecture](#architecture) | [UI/UX Guidelines](#uiux-guidelines) | [Networking](#networking--file-transfer) | [Rust Integration](#rust-integration) | [Development Guidelines](#development-guidelines)

**Last Updated:** April 12, 2026  
**Status:** ✅ Active Knowledge Base  
**Confidence Level:** High (Tested and Verified)  
**Use Case:** Comprehensive guide for Flux app development, design patterns, and implementation standards

---

## 📋 Document Summary

This guide provides comprehensive standards for Flux app development:
- **Design System:** Colors, typography, spacing, shadows, and visual standards
- **Architecture:** Project structure, service patterns, state management, data models
- **UI/UX Guidelines:** Screen design, components, interactions, and animations
- **Networking & File Transfer:** Connection types, protocols, security, and encryption
- **Rust Integration:** Module organization, FFI bindings, and native code
- **Development Guidelines:** Code style, error handling, testing, and performance
- **Constants & Permissions:** Network settings, file transfer limits, and platform permissions

**When to use:** Auto-included in all contexts for consistency. Reference when developing Flux features or maintaining design standards.

---

## Overview

Flux is a cross-platform file sharing application built with Flutter and Rust. This document outlines the design system, architecture patterns, and implementation guidelines.

## Design System

### Color Palette
- **Primary**: `#6366F1` (Indigo) - Main brand color
- **Secondary**: `#8B5CF6` (Purple) - Accent color
- **Tertiary**: `#06B6D4` (Cyan) - Highlight color
- **Success**: `#10B981` (Emerald) - Positive actions
- **Warning**: `#F59E0B` (Amber) - Warnings
- **Error**: `#EF4444` (Red) - Errors
- **Info**: `#3B82F6` (Blue) - Information

### Neutral Colors
- **Background**: `#FAFAFA` - Page background
- **Surface**: `#FFFFFF` - Card/component background
- **Border**: `#E5E7EB` - Borders
- **Text Primary**: `#111827` - Main text
- **Text Secondary**: `#6B7280` - Secondary text
- **Text Tertiary**: `#9CA3AF` - Tertiary text

### Typography
- **Font Family**: Inter (via Google Fonts)
- **Display Large**: 32px, Bold
- **Display Medium**: 28px, Bold
- **Display Small**: 24px, Bold
- **Headline Medium**: 20px, Semi-bold
- **Title Large**: 16px, Semi-bold
- **Body Large**: 16px, Regular
- **Body Medium**: 14px, Regular
- **Body Small**: 12px, Regular

### Spacing
- **xs**: 4px
- **sm**: 8px
- **md**: 12px
- **lg**: 16px
- **xl**: 20px
- **2xl**: 24px
- **3xl**: 32px

### Border Radius
- **sm**: 6px
- **md**: 8px
- **lg**: 12px
- **xl**: 16px

### Shadows
- **sm**: blur 2px, offset 0,1px
- **md**: blur 4px, offset 0,2px
- **lg**: blur 8px, offset 0,4px

## Architecture

### Project Structure
```
lib/
├── config/              # App configuration
│   ├── app_constants.dart
│   └── app_theme.dart
├── models/              # Data models (Freezed)
│   ├── device.dart
│   ├── file_metadata.dart
│   └── connection_state.dart
├── services/            # Business logic
│   ├── base_service.dart
│   ├── permission_service.dart
│   ├── connectivity_service.dart
│   ├── bluetooth_service.dart
│   ├── file_service.dart
│   └── encryption_service.dart
├── providers/           # State management (Provider)
│   ├── connection_provider.dart
│   ├── device_provider.dart
│   └── file_transfer_provider.dart
├── screens/             # UI screens
│   ├── home_screen.dart
│   ├── device_discovery_screen.dart
│   ├── file_transfer_screen.dart
│   └── settings_screen.dart
├── widgets/             # Reusable widgets
│   ├── device_card.dart
│   ├── transfer_progress_widget.dart
│   └── connection_indicator.dart
├── utils/               # Utilities
│   ├── logger.dart
│   ├── extensions.dart
│   └── validators.dart
└── main.dart
```

### Service Layer Pattern
All services extend `BaseService` and follow the singleton pattern:

```dart
class MyService extends BaseService {
  static final MyService _instance = MyService._internal();
  
  factory MyService() => _instance;
  MyService._internal();
  
  @override
  Future<void> initialize() async {
    await super.initialize();
    // Service-specific initialization
  }
}
```

### State Management with Provider
Use Provider for state management:

```dart
// Create a provider
final myProvider = StateNotifierProvider<MyNotifier, MyState>((ref) {
  return MyNotifier();
});

// Use in widget
Consumer(
  builder: (context, ref, child) {
    final state = ref.watch(myProvider);
    return Text(state.toString());
  },
)
```

### Data Models with Freezed
All data models use Freezed for immutability:

```dart
@freezed
class MyModel with _$MyModel {
  const factory MyModel({
    required String id,
    required String name,
  }) = _MyModel;
  
  factory MyModel.fromJson(Map<String, dynamic> json) =>
      _$MyModelFromJson(json);
}
```

## UI/UX Guidelines

### Screens
- **Home Screen**: Dashboard with quick actions and status
- **Device Discovery**: List of discovered devices with connection options
- **File Transfer**: Progress tracking and file management
- **Settings**: App configuration and preferences

### Components
- **Cards**: Use for grouping related content
- **Buttons**: Primary (filled), Secondary (outlined), Tertiary (text)
- **Input Fields**: Consistent styling with validation feedback
- **Progress Indicators**: For file transfers and loading states
- **Status Badges**: For connection and transfer states

### Interactions
- **Animations**: 300ms for standard, 150ms for quick feedback
- **Feedback**: Haptic feedback for important actions
- **Loading States**: Show shimmer or skeleton screens
- **Error Handling**: Clear error messages with recovery options

## Networking & File Transfer

### Connection Types
1. **Bluetooth**: For short-range, low-power transfers
2. **WiFi Direct**: For direct device-to-device connections
3. **Hotspot**: For sharing via mobile hotspot
4. **Local Network**: For devices on same WiFi network

### File Transfer Protocol
- **Chunked Transfer**: 1MB chunks for large files
- **Encryption**: AES-256-GCM for secure transfers
- **Verification**: SHA-256 hashing for integrity
- **Resume Support**: Pause and resume transfers

### Security
- **Encryption**: All transfers encrypted with AES-256-GCM
- **Authentication**: Device pairing with public key exchange
- **Verification**: File hash verification after transfer
- **Secure Storage**: Sensitive data stored securely

## Rust Integration

### Modules
- **crypto.rs**: AES-GCM encryption/decryption
- **file_transfer.rs**: File chunking and hashing
- **network.rs**: Socket management and protocol
- **discovery.rs**: Device discovery logic

### FFI Bindings
Generated automatically by flutter_rust_bridge. Update with:
```bash
flutter pub run flutter_rust_bridge:build
```

## Development Guidelines

### Code Style
- Follow Dart style guide
- Use meaningful variable names
- Add documentation comments
- Keep functions small and focused

### Error Handling
- Use Result types in Rust
- Use custom exceptions in Dart
- Always provide user-friendly error messages
- Log errors for debugging

### Testing
- Unit tests for services
- Widget tests for UI components
- Integration tests for workflows
- Test on multiple devices

### Performance
- Use const constructors
- Avoid rebuilds with Provider selectors
- Lazy load screens
- Optimize file transfers with chunking

## Constants

### Network
- Default Port: 9876
- Discovery Port: 9877
- Connection Timeout: 30 seconds
- Discovery Timeout: 10 seconds
- Max Concurrent Transfers: 3
- File Chunk Size: 1MB

### File Transfer
- Max File Size: 5GB
- Allowed Types: Common document, image, audio, video, archive formats
- Encryption Key Size: 256-bit
- Encryption Nonce Size: 96-bit (GCM)

## Permissions

### Android
- INTERNET
- BLUETOOTH, BLUETOOTH_ADMIN, BLUETOOTH_SCAN, BLUETOOTH_CONNECT
- ACCESS_FINE_LOCATION, ACCESS_COARSE_LOCATION
- CHANGE_NETWORK_STATE, ACCESS_NETWORK_STATE
- READ_EXTERNAL_STORAGE, WRITE_EXTERNAL_STORAGE, MANAGE_EXTERNAL_STORAGE
- CHANGE_WIFI_STATE, ACCESS_WIFI_STATE

### iOS
- NSBluetoothPeripheralUsageDescription
- NSBluetoothCentralUsageDescription
- NSLocalNetworkUsageDescription
- NSLocationWhenInUseUsageDescription
- NSLocationAlwaysAndWhenInUseUsageDescription

## Future Enhancements
- [ ] Cloud backup integration
- [ ] Scheduled transfers
- [ ] Transfer templates
- [ ] Advanced analytics
- [ ] Multi-language support
- [ ] Dark mode refinements
- [ ] Accessibility improvements
