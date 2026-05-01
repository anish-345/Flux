# Feature 1: User-Friendly Error Messages

**Estimated Time:** 2 hours  
**Priority:** 🔴 Foundation (implement first)  
**Status:** Ready for Implementation

---

## 📋 Overview

This feature implements a comprehensive error handling system that provides users with clear, actionable error messages instead of technical jargon. It includes error categorization, user-friendly descriptions, recovery suggestions, and retry mechanisms.

### What Users Will See

**Before (Current):**
```
❌ Exception: SocketException: Connection refused
```

**After (New):**
```
❌ Connection Failed
Couldn't connect to the device. Make sure:
• Both devices are on the same network
• The other device is online
• Bluetooth is enabled

[Retry] [Cancel]
```

---

## 🎯 Implementation Goals

1. ✅ Categorize all possible errors
2. ✅ Create user-friendly messages
3. ✅ Provide recovery suggestions
4. ✅ Implement retry mechanism
5. ✅ Show errors in UI consistently
6. ✅ Log errors for debugging

---

## 📁 Files to Create

### 1. `lib/models/app_error.dart` (NEW)

```dart
/// Represents all possible errors in the app
enum ErrorType {
  // Network errors
  connectionFailed,
  connectionTimeout,
  networkUnreachable,
  
  // Device errors
  deviceNotFound,
  deviceOffline,
  deviceBusy,
  
  // File errors
  fileNotFound,
  fileAccessDenied,
  fileCorrupted,
  insufficientStorage,
  
  // Transfer errors
  transferCancelled,
  transferFailed,
  transferTimeout,
  
  // Security errors
  encryptionFailed,
  decryptionFailed,
  invalidSignature,
  
  // Permission errors
  permissionDenied,
  permissionNotRequested,
  
  // Unknown errors
  unknown,
}

/// Represents an app error with user-friendly information
class AppError implements Exception {
  final ErrorType type;
  final String message;
  final String? userMessage;
  final String? suggestion;
  final dynamic originalError;
  final StackTrace? stackTrace;
  final DateTime timestamp;
  
  AppError({
    required this.type,
    required this.message,
    this.userMessage,
    this.suggestion,
    this.originalError,
    this.stackTrace,
  }) : timestamp = DateTime.now();
  
  /// Get a user-friendly title for this error
  String get title {
    switch (type) {
      case ErrorType.connectionFailed:
        return 'Connection Failed';
      case ErrorType.connectionTimeout:
        return 'Connection Timeout';
      case ErrorType.networkUnreachable:
        return 'Network Unreachable';
      case ErrorType.deviceNotFound:
        return 'Device Not Found';
      case ErrorType.deviceOffline:
        return 'Device Offline';
      case ErrorType.deviceBusy:
        return 'Device Busy';
      case ErrorType.fileNotFound:
        return 'File Not Found';
      case ErrorType.fileAccessDenied:
        return 'Access Denied';
      case ErrorType.fileCorrupted:
        return 'File Corrupted';
      case ErrorType.insufficientStorage:
        return 'Insufficient Storage';
      case ErrorType.transferCancelled:
        return 'Transfer Cancelled';
      case ErrorType.transferFailed:
        return 'Transfer Failed';
      case ErrorType.transferTimeout:
        return 'Transfer Timeout';
      case ErrorType.encryptionFailed:
        return 'Encryption Failed';
      case ErrorType.decryptionFailed:
        return 'Decryption Failed';
      case ErrorType.invalidSignature:
        return 'Invalid Signature';
      case ErrorType.permissionDenied:
        return 'Permission Denied';
      case ErrorType.permissionNotRequested:
        return 'Permission Required';
      case ErrorType.unknown:
        return 'Something Went Wrong';
    }
  }
  
  /// Get a user-friendly description
  String get description {
    return userMessage ?? message;
  }
  
  /// Get recovery suggestions
  String? get recoverySuggestion {
    return suggestion;
  }
  
  /// Check if this error is retryable
  bool get isRetryable {
    return [
      ErrorType.connectionFailed,
      ErrorType.connectionTimeout,
      ErrorType.deviceBusy,
      ErrorType.transferFailed,
      ErrorType.transferTimeout,
    ].contains(type);
  }
  
  /// Check if this error requires user action
  bool get requiresUserAction {
    return [
      ErrorType.permissionDenied,
      ErrorType.permissionNotRequested,
      ErrorType.fileAccessDenied,
      ErrorType.insufficientStorage,
    ].contains(type);
  }
  
  @override
  String toString() => 'AppError($type): $message';
}

/// Factory for creating AppError instances
class AppErrorFactory {
  /// Create error from exception
  static AppError fromException(dynamic exception, [StackTrace? stackTrace]) {
    if (exception is AppError) {
      return exception;
    }
    
    final message = exception.toString();
    
    // Network errors
    if (message.contains('Connection refused') || 
        message.contains('Connection reset')) {
      return AppError(
        type: ErrorType.connectionFailed,
        message: message,
        userMessage: 'Couldn\'t connect to the device',
        suggestion: 'Make sure both devices are on the same network and online',
        originalError: exception,
        stackTrace: stackTrace,
      );
    }
    
    if (message.contains('timeout') || message.contains('Timeout')) {
      return AppError(
        type: ErrorType.connectionTimeout,
        message: message,
        userMessage: 'Connection took too long',
        suggestion: 'Check your network connection and try again',
        originalError: exception,
        stackTrace: stackTrace,
      );
    }
    
    if (message.contains('Network is unreachable')) {
      return AppError(
        type: ErrorType.networkUnreachable,
        message: message,
        userMessage: 'No network connection',
        suggestion: 'Connect to WiFi or mobile data and try again',
        originalError: exception,
        stackTrace: stackTrace,
      );
    }
    
    // File errors
    if (message.contains('FileSystemException') || 
        message.contains('No such file')) {
      return AppError(
        type: ErrorType.fileNotFound,
        message: message,
        userMessage: 'File not found',
        suggestion: 'The file may have been deleted or moved',
        originalError: exception,
        stackTrace: stackTrace,
      );
    }
    
    if (message.contains('Permission denied')) {
      return AppError(
        type: ErrorType.fileAccessDenied,
        message: message,
        userMessage: 'Permission denied',
        suggestion: 'Grant file access permission in app settings',
        originalError: exception,
        stackTrace: stackTrace,
      );
    }
    
    if (message.contains('No space left')) {
      return AppError(
        type: ErrorType.insufficientStorage,
        message: message,
        userMessage: 'Not enough storage space',
        suggestion: 'Free up space on your device and try again',
        originalError: exception,
        stackTrace: stackTrace,
      );
    }
    
    // Default to unknown error
    return AppError(
      type: ErrorType.unknown,
      message: message,
      userMessage: 'Something went wrong',
      suggestion: 'Try again or contact support if the problem persists',
      originalError: exception,
      stackTrace: stackTrace,
    );
  }
}
```

### 2. `lib/utils/error_mapper.dart` (NEW)

```dart
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
        return Icons.devices_off;
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
```

### 3. `lib/widgets/error_dialog.dart` (NEW)

```dart
import 'package:flutter/material.dart';
import '../models/app_error.dart';
import '../utils/error_mapper.dart';

/// Dialog for displaying errors to users
class ErrorDialog extends StatelessWidget {
  final AppError error;
  final VoidCallback? onRetry;
  final VoidCallback? onDismiss;
  final bool showDetails;
  
  const ErrorDialog({
    Key? key,
    required this.error,
    this.onRetry,
    this.onDismiss,
    this.showDetails = false,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      icon: Icon(
        ErrorMapper.getIcon(error.type),
        color: ErrorMapper.getColor(error.type),
        size: 48,
      ),
      title: Text(error.title),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Main message
            Text(
              error.description,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            
            // Suggestions
            if (error.recoverySuggestion != null) ...[
              Text(
                'What you can try:',
                style: Theme.of(context).textTheme.labelMedium,
              ),
              const SizedBox(height: 8),
              ..._buildSuggestions(context),
            ],
            
            // Technical details (if enabled)
            if (showDetails) ...[
              const SizedBox(height: 16),
              ExpansionTile(
                title: const Text('Technical Details'),
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: SelectableText(
                      error.message,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
      actions: [
        if (onDismiss != null)
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              onDismiss?.call();
            },
            child: const Text('Cancel'),
          ),
        if (error.isRetryable && onRetry != null)
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              onRetry?.call();
            },
            child: const Text('Retry'),
          ),
        if (!error.isRetryable || onRetry == null)
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
      ],
    );
  }
  
  List<Widget> _buildSuggestions(BuildContext context) {
    final suggestions = ErrorMapper.getDetailedSuggestions(error.type);
    return suggestions
        .map((suggestion) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('• ', style: TextStyle(fontWeight: FontWeight.bold)),
                  Expanded(
                    child: Text(
                      suggestion,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
            ))
        .toList();
  }
  
  /// Show this error dialog
  static Future<void> show(
    BuildContext context,
    AppError error, {
    VoidCallback? onRetry,
    VoidCallback? onDismiss,
    bool showDetails = false,
  }) {
    return showDialog(
      context: context,
      builder: (context) => ErrorDialog(
        error: error,
        onRetry: onRetry,
        onDismiss: onDismiss,
        showDetails: showDetails,
      ),
    );
  }
}

/// Snackbar for displaying errors
class ErrorSnackBar {
  static void show(
    BuildContext context,
    AppError error, {
    VoidCallback? onRetry,
    Duration duration = const Duration(seconds: 5),
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              ErrorMapper.getIcon(error.type),
              color: Colors.white,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    error.title,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    error.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: ErrorMapper.getColor(error.type),
        duration: duration,
        action: error.isRetryable && onRetry != null
            ? SnackBarAction(
                label: 'Retry',
                textColor: Colors.white,
                onPressed: onRetry,
              )
            : null,
      ),
    );
  }
}
```

---

## 🔧 Integration Steps

### Step 1: Update Existing Services

In each service that throws errors, wrap exceptions:

```dart
// Before
Future<void> connectToDevice(String deviceId) async {
  try {
    await _bluetoothService.connect(deviceId);
  } catch (e) {
    rethrow;
  }
}

// After
Future<void> connectToDevice(String deviceId) async {
  try {
    await _bluetoothService.connect(deviceId);
  } catch (e, st) {
    throw AppErrorFactory.fromException(e, st);
  }
}
```

### Step 2: Update Providers

In Riverpod providers, catch and handle errors:

```dart
final deviceConnectionProvider = FutureProvider<void>((ref) async {
  try {
    await ref.watch(deviceServiceProvider).connect(deviceId);
  } on AppError catch (error) {
    // Error is already user-friendly
    rethrow;
  } catch (e, st) {
    throw AppErrorFactory.fromException(e, st);
  }
});
```

### Step 3: Update UI Screens

In screens, show errors to users:

```dart
class FileTransferScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transferState = ref.watch(fileTransferProvider);
    
    return transferState.when(
      data: (data) => _buildContent(context, data),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, st) {
        final appError = error is AppError 
            ? error 
            : AppErrorFactory.fromException(error, st);
        
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                ErrorMapper.getIcon(appError.type),
                size: 64,
                color: ErrorMapper.getColor(appError.type),
              ),
              const SizedBox(height: 16),
              Text(appError.title),
              const SizedBox(height: 8),
              Text(appError.description),
              const SizedBox(height: 16),
              if (appError.isRetryable)
                ElevatedButton(
                  onPressed: () => ref.refresh(fileTransferProvider),
                  child: const Text('Retry'),
                ),
            ],
          ),
        );
      },
    );
  }
}
```

---

## 📊 Error Handling Checklist

- [ ] Create `app_error.dart` with ErrorType enum and AppError class
- [ ] Create `error_mapper.dart` with UI mapping functions
- [ ] Create `error_dialog.dart` with error display widgets
- [ ] Update all services to wrap exceptions
- [ ] Update all providers to handle errors
- [ ] Update all screens to show error dialogs
- [ ] Test error messages on different screen sizes
- [ ] Verify retry mechanism works
- [ ] Test with actual network failures
- [ ] Verify error logging works

---

## 🧪 Testing Scenarios

### Test 1: Connection Error
```
1. Disable WiFi
2. Try to connect to device
3. Verify error dialog shows
4. Verify suggestions are helpful
5. Enable WiFi
6. Click Retry
7. Verify connection succeeds
```

### Test 2: File Not Found
```
1. Select a file
2. Delete the file before transfer
3. Start transfer
4. Verify error dialog shows
5. Verify suggestion to select another file
```

### Test 3: Permission Error
```
1. Deny file access permission
2. Try to select files
3. Verify error dialog shows
4. Verify suggestion to grant permission
5. Grant permission
6. Verify file selection works
```

---

## 💡 Key Benefits

✅ **User-Friendly** - Clear, non-technical messages  
✅ **Actionable** - Suggestions for recovery  
✅ **Consistent** - Same error handling everywhere  
✅ **Debuggable** - Technical details available  
✅ **Retryable** - Easy retry for transient errors  
✅ **Accessible** - Icons and colors for clarity  

---

**Next:** After implementing this feature, move to Feature 2 (File Transfer Optimization)
