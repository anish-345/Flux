/// Input validators
class Validators {
  /// Validate IP address
  static String? validateIPAddress(String? value) {
    if (value == null || value.isEmpty) {
      return 'IP address is required';
    }

    final ipRegex = RegExp(
      r'^(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$',
    );

    if (!ipRegex.hasMatch(value)) {
      return 'Invalid IP address format';
    }

    return null;
  }

  /// Validate port number
  static String? validatePort(String? value) {
    if (value == null || value.isEmpty) {
      return 'Port is required';
    }

    final port = int.tryParse(value);
    if (port == null) {
      return 'Port must be a number';
    }

    if (port < 1 || port > 65535) {
      return 'Port must be between 1 and 65535';
    }

    return null;
  }

  /// Validate device name
  static String? validateDeviceName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Device name is required';
    }

    if (value.length < 2) {
      return 'Device name must be at least 2 characters';
    }

    if (value.length > 50) {
      return 'Device name must not exceed 50 characters';
    }

    return null;
  }

  /// Validate file size
  static String? validateFileSize(int fileSize, int maxSize) {
    if (fileSize > maxSize) {
      return 'File size exceeds maximum allowed size';
    }
    return null;
  }

  /// Validate file type
  static String? validateFileType(String fileName, List<String> allowedTypes) {
    final extension = fileName.split('.').last.toLowerCase();
    if (!allowedTypes.contains(extension)) {
      return 'File type not allowed';
    }
    return null;
  }

  /// Validate not empty
  static String? validateNotEmpty(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }

  /// Validate minimum length
  static String? validateMinLength(
    String? value,
    int minLength,
    String fieldName,
  ) {
    if (value == null || value.length < minLength) {
      return '$fieldName must be at least $minLength characters';
    }
    return null;
  }

  /// Validate maximum length
  static String? validateMaxLength(
    String? value,
    int maxLength,
    String fieldName,
  ) {
    if (value == null || value.length > maxLength) {
      return '$fieldName must not exceed $maxLength characters';
    }
    return null;
  }
}
