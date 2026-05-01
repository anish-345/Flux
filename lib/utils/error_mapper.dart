import 'package:flutter/material.dart';
import '../models/app_error.dart';

/// Maps errors to UI representations
class ErrorMapper {
  /// Get icon for error type
  static IconData getIcon(ErrorType type) {
    switch (type) {
      case ErrorType.connectionFailed:
      case ErrorType.connectionTimeout:
      case ErrorType.networkUnreachable:
        return Icons.wifi_off;
      case ErrorType.deviceNotFound:
      case ErrorType.deviceOffline:
      case ErrorType.deviceBusy:
        return Icons.devices;
      case ErrorType.fileNotFound:
      case ErrorType.fileAccessDenied:
      case ErrorType.fileCorrupted:
        return Icons.file_present;
      case ErrorType.insufficientStorage:
        return Icons.storage;
      case ErrorType.transferCancelled:
      case ErrorType.transferFailed:
      case ErrorType.transferTimeout:
        return Icons.error_outline;
      case ErrorType.encryptionFailed:
      case ErrorType.decryptionFailed:
      case ErrorType.invalidSignature:
        return Icons.lock_outline;
      case ErrorType.permissionDenied:
      case ErrorType.permissionNotRequested:
        return Icons.lock;
      case ErrorType.unknown:
        return Icons.help_outline;
    }
  }

  /// Get color for error type
  static Color getColor(ErrorType type) {
    switch (type) {
      case ErrorType.permissionDenied:
      case ErrorType.permissionNotRequested:
        return Colors.orange;
      case ErrorType.encryptionFailed:
      case ErrorType.decryptionFailed:
      case ErrorType.invalidSignature:
        return Colors.red;
      default:
        return Colors.red;
    }
  }

  /// Get detailed suggestions based on error type
  static List<String> getDetailedSuggestions(ErrorType type) {
    switch (type) {
      case ErrorType.connectionFailed:
        return [
          'Make sure both devices are on the same WiFi network',
          'Check if the other device is online',
          'Try moving closer to the router',
          'Restart your WiFi router',
        ];
      case ErrorType.connectionTimeout:
        return [
          'Check your internet connection',
          'Try again in a moment',
          'Move closer to the WiFi router',
          'Restart the app',
        ];
      case ErrorType.networkUnreachable:
        return [
          'Connect to WiFi or mobile data',
          'Check airplane mode is off',
          'Restart your device',
        ];
      case ErrorType.deviceNotFound:
        return [
          'Make sure the device is online',
          'Check if the device is in range',
          'Restart the app on both devices',
        ];
      case ErrorType.deviceOffline:
        return [
          'Turn on the other device',
          'Check if it\'s connected to the network',
          'Wait a moment and try again',
        ];
      case ErrorType.fileNotFound:
        return [
          'The file may have been deleted',
          'Check if the file still exists',
          'Try selecting the file again',
        ];
      case ErrorType.fileAccessDenied:
        return [
          'Grant file access in app settings',
          'Check file permissions',
          'Try a different file',
        ];
      case ErrorType.insufficientStorage:
        return [
          'Delete unnecessary files',
          'Clear app cache',
          'Free up storage space',
        ];
      case ErrorType.transferFailed:
        return [
          'Check your connection',
          'Try again',
          'Try with a smaller file',
        ];
      case ErrorType.permissionDenied:
        return [
          'Grant permission in app settings',
          'Go to Settings > Apps > Flux > Permissions',
          'Enable the required permission',
        ];
      default:
        return [
          'Try again',
          'Restart the app',
          'Contact support if the problem persists',
        ];
    }
  }
}
