import 'package:flux/utils/logger.dart';

/// Base service class for all services
abstract class BaseService {
  /// Service name for logging
  String get serviceName => runtimeType.toString();

  /// Initialize the service
  Future<void> initialize() async {
    AppLogger.info('[$serviceName] Initializing...');
  }

  /// Dispose the service
  Future<void> dispose() async {
    AppLogger.info('[$serviceName] Disposing...');
  }

  /// Check if service is initialized
  bool get isInitialized => true;

  /// Log debug message
  void logDebug(String message) {
    AppLogger.debug('[$serviceName] $message');
  }

  /// Log info message
  void logInfo(String message) {
    AppLogger.info('[$serviceName] $message');
  }

  /// Log warning message
  void logWarning(String message) {
    AppLogger.warning('[$serviceName] $message');
  }

  /// Log error message
  void logError(String message, [dynamic error, StackTrace? stackTrace]) {
    AppLogger.error('[$serviceName] $message', error, stackTrace);
  }
}
