/// Application-wide constants
class AppConstants {
  // App Info
  static const String appName = 'Flux Share';
  static const String appVersion = '1.0.0';
  static const String appDescription = 'Fast & Secure File Sharing';

  // Network
  static const int defaultPort = 9876;
  static const int discoveryPort = 9877;
  static const Duration connectionTimeout = Duration(seconds: 30);
  static const Duration discoveryTimeout = Duration(seconds: 10);
  static const int maxConcurrentTransfers = 3;
  static const int fileChunkSize = 1024 * 1024; // 1MB chunks

  // Bluetooth
  static const String bluetoothServiceUuid =
      '12345678-1234-5678-1234-567812345678';
  static const String bluetoothCharacteristicUuid =
      '87654321-4321-8765-4321-876543218765';

  // File Transfer
  static const int maxFileSize = 5 * 1024 * 1024 * 1024; // 5GB
  static const List<String> allowedFileTypes = [
    'pdf',
    'doc',
    'docx',
    'xls',
    'xlsx',
    'ppt',
    'pptx',
    'jpg',
    'jpeg',
    'png',
    'gif',
    'bmp',
    'mp3',
    'mp4',
    'avi',
    'mkv',
    'zip',
    'rar',
    '7z',
    'txt',
    'csv',
    'json',
    'xml',
  ];

  // Encryption
  static const int encryptionKeySize = 32; // 256-bit
  static const int encryptionNonceSize = 12; // 96-bit for GCM

  // UI
  static const Duration animationDuration = Duration(milliseconds: 300);
  static const Duration shortAnimationDuration = Duration(milliseconds: 150);
}
