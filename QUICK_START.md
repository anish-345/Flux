# Flux - Quick Start Guide

## What is Flux?

Flux is a fast, secure, and easy-to-use file sharing application that allows you to transfer files between devices using Bluetooth, WiFi, or hotspot connections. Built with Flutter and Rust, Flux provides enterprise-grade encryption and performance.

## Features

✨ **Fast Transfer** - Transfer files at high speeds over WiFi or Bluetooth
🔒 **Secure** - AES-256-GCM encryption for all transfers
📱 **Cross-Platform** - Works on Android and iOS
🎯 **Easy to Use** - Simple, intuitive interface
🔋 **Efficient** - Optimized for battery life
🌙 **Dark Mode** - Beautiful dark theme support
🌍 **Multilingual** - Support for multiple languages

## Installation

### From Source

```bash
# Clone the repository
git clone https://github.com/yourusername/flux.git
cd flux

# Install dependencies
flutter pub get

# Generate code
flutter pub run build_runner build --delete-conflicting-outputs

# Run the app
flutter run
```

### From App Store

- **Android**: [Google Play Store](https://play.google.com/store/apps/details?id=com.flux.app)
- **iOS**: [Apple App Store](https://apps.apple.com/app/flux/id123456789)

## Getting Started

### 1. Enable Bluetooth/WiFi

Make sure Bluetooth or WiFi is enabled on both devices.

### 2. Discover Devices

1. Open Flux on both devices
2. Go to "Discover Devices"
3. Wait for devices to appear
4. Tap "Connect" to establish connection

### 3. Send Files

1. Go to "File Transfer"
2. Select target device
3. Tap "Add Files" to select files
4. Tap "Send" to start transfer

### 4. Receive Files

Files are automatically received and saved to your Downloads folder.

## Settings

### Device Name
Change your device name to make it easier to identify on the network.

### Theme
Choose between Light, Dark, or System theme.

### Transfer Settings
- **Auto-Accept**: Automatically accept transfers from trusted devices
- **Max Concurrent**: Set maximum number of simultaneous transfers
- **Encryption**: Enable/disable file encryption

### Notifications
Enable or disable transfer notifications.

## Troubleshooting

### Devices Not Discovered

1. Check Bluetooth/WiFi is enabled
2. Ensure both devices are on the same network
3. Try refreshing the device list
4. Restart the app

### Transfer Failed

1. Check network connection
2. Ensure sufficient storage space
3. Try again with a smaller file
4. Check app permissions

### Slow Transfer Speed

1. Move closer to the router
2. Reduce interference (move away from microwaves)
3. Close other apps using network
4. Try WiFi instead of Bluetooth

## Permissions

Flux requires the following permissions:

- **Bluetooth**: For device discovery and connection
- **WiFi**: For network connectivity
- **Storage**: For file access and transfer
- **Notifications**: For transfer notifications

## Privacy & Security

- All files are encrypted with AES-256-GCM
- No data is stored on external servers
- Device pairing is required for transfers
- Trusted devices can be managed in settings

## Tips & Tricks

1. **Trust Devices**: Trust frequently used devices for faster connections
2. **Batch Transfers**: Send multiple files at once
3. **Schedule Transfers**: Use auto-accept for scheduled transfers
4. **Monitor Progress**: Watch real-time transfer progress
5. **Clear History**: Regularly clear transfer history for privacy

## Keyboard Shortcuts

- **Ctrl+O**: Open file picker
- **Ctrl+S**: Send selected files
- **Ctrl+P**: Pause transfer
- **Ctrl+R**: Resume transfer
- **Ctrl+X**: Cancel transfer

## FAQ

**Q: Is my data secure?**
A: Yes, all transfers are encrypted with AES-256-GCM encryption.

**Q: Can I transfer to multiple devices?**
A: Yes, you can set up to 5 concurrent transfers.

**Q: What file types can I transfer?**
A: Any file type - documents, images, videos, etc.

**Q: Is there a file size limit?**
A: No, you can transfer files of any size.

**Q: Can I pause and resume transfers?**
A: Yes, transfers can be paused and resumed anytime.

**Q: Does Flux work offline?**
A: Yes, Flux works over local networks without internet.

## Support

- **Documentation**: [docs.flux.app](https://docs.flux.app)
- **GitHub Issues**: [github.com/flux/issues](https://github.com/flux/issues)
- **Email**: support@flux.app
- **Discord**: [discord.gg/flux](https://discord.gg/flux)

## Contributing

We welcome contributions! Please see [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

## License

Flux is licensed under the MIT License. See [LICENSE](LICENSE) for details.

## Changelog

### Version 1.0.0 (2024)
- Initial release
- Device discovery
- File transfer
- Encryption support
- Settings management
- Transfer history

---

**Made with ❤️ by the Flux Team**
