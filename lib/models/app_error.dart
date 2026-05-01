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
