import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flux/services/feature_enablement_service.dart';
import 'package:flux/utils/logger.dart';

/// Error state model
class ErrorState {
  final String? message;
  final String? code;
  final FeatureType? affectedFeature;
  final bool requiresUserAction;
  final DateTime timestamp;

  ErrorState({
    this.message,
    this.code,
    this.affectedFeature,
    this.requiresUserAction = false,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  bool get hasError => message != null;

  ErrorState copyWith({
    String? message,
    String? code,
    FeatureType? affectedFeature,
    bool? requiresUserAction,
  }) {
    return ErrorState(
      message: message ?? this.message,
      code: code ?? this.code,
      affectedFeature: affectedFeature ?? this.affectedFeature,
      requiresUserAction: requiresUserAction ?? this.requiresUserAction,
    );
  }

  @override
  String toString() =>
      'ErrorState(message: $message, code: $code, requiresUserAction: $requiresUserAction)';
}

/// Feature status state model
class FeatureStatusState {
  final Map<FeatureType, FeatureEnablementResult> statuses;
  final bool allFeaturesReady;
  final List<FeatureType> missingFeatures;
  final List<FeatureType> disabledFeatures;

  FeatureStatusState({required this.statuses})
    : allFeaturesReady = statuses.values.every((r) => r.isNowEnabled),
      missingFeatures = statuses.entries
          .where((e) => e.value.status == FeatureStatus.unavailable)
          .map((e) => e.key)
          .toList(),
      disabledFeatures = statuses.entries
          .where((e) => e.value.status == FeatureStatus.disabled)
          .map((e) => e.key)
          .toList();

  bool isFeatureReady(FeatureType feature) {
    return statuses[feature]?.isNowEnabled ?? false;
  }

  String getFeatureStatus(FeatureType feature) {
    final result = statuses[feature];
    if (result == null) return 'Unknown';
    return result.status.toString();
  }
}

/// Error handling notifier
class ErrorHandlingNotifier extends StateNotifier<ErrorState> {
  final FeatureEnablementService _featureService = FeatureEnablementService();

  ErrorHandlingNotifier() : super(ErrorState());

  /// Clear error
  void clearError() {
    state = ErrorState();
  }

  /// Set error with feature context
  void setError({
    required String message,
    String? code,
    FeatureType? affectedFeature,
    bool requiresUserAction = false,
  }) {
    AppLogger.error(message, null);
    state = ErrorState(
      message: message,
      code: code,
      affectedFeature: affectedFeature,
      requiresUserAction: requiresUserAction,
    );
  }

  /// Handle feature error
  void handleFeatureError(FeatureEnablementResult result) {
    final message = _featureService.getErrorMessage(result);
    setError(
      message: message,
      code: result.status.toString(),
      affectedFeature: result.feature,
      requiresUserAction: result.requiresUserAction,
    );
  }
}

/// Feature status notifier
class FeatureStatusNotifier extends StateNotifier<FeatureStatusState> {
  final FeatureEnablementService _featureService = FeatureEnablementService();

  FeatureStatusNotifier() : super(FeatureStatusState(statuses: {})) {
    _initialize();
  }

  Future<void> _initialize() async {
    await checkAllFeatures();
  }

  /// Check all features
  Future<void> checkAllFeatures() async {
    try {
      AppLogger.info('Checking all features...');
      final results = await _featureService.checkAllFeatures();
      state = FeatureStatusState(statuses: results);
      AppLogger.info('Feature check complete');
    } catch (e) {
      AppLogger.error('Error checking features', e);
    }
  }

  /// Ensure Bluetooth is enabled
  Future<FeatureEnablementResult> ensureBluetoothEnabled() async {
    try {
      AppLogger.info('Ensuring Bluetooth is enabled...');
      final result = await _featureService.ensureBluetoothEnabled();

      // Update state
      final updated = Map<FeatureType, FeatureEnablementResult>.from(
        state.statuses,
      );
      updated[FeatureType.bluetooth] = result;
      state = FeatureStatusState(statuses: updated);

      if (result.success) {
        AppLogger.info('✅ Bluetooth is now enabled');
      } else {
        AppLogger.warning('Bluetooth enablement failed: ${result.message}');
      }

      return result;
    } catch (e) {
      AppLogger.error('Error ensuring Bluetooth', e);
      rethrow;
    }
  }

  /// Ensure WiFi is enabled
  Future<FeatureEnablementResult> ensureWiFiEnabled() async {
    try {
      AppLogger.info('Ensuring WiFi is enabled...');
      final result = await _featureService.ensureWiFiEnabled();

      // Update state
      final updated = Map<FeatureType, FeatureEnablementResult>.from(
        state.statuses,
      );
      updated[FeatureType.wifi] = result;
      state = FeatureStatusState(statuses: updated);

      if (result.success) {
        AppLogger.info('✅ WiFi is now enabled');
      } else {
        AppLogger.warning('WiFi enablement failed: ${result.message}');
      }

      return result;
    } catch (e) {
      AppLogger.error('Error ensuring WiFi', e);
      rethrow;
    }
  }

  /// Ensure location is enabled
  Future<FeatureEnablementResult> ensureLocationEnabled() async {
    try {
      AppLogger.info('Ensuring location is enabled...');
      final result = await _featureService.ensureLocationEnabled();

      // Update state
      final updated = Map<FeatureType, FeatureEnablementResult>.from(
        state.statuses,
      );
      updated[FeatureType.location] = result;
      state = FeatureStatusState(statuses: updated);

      if (result.success) {
        AppLogger.info('✅ Location is now enabled');
      } else {
        AppLogger.warning('Location enablement failed: ${result.message}');
      }

      return result;
    } catch (e) {
      AppLogger.error('Error ensuring location', e);
      rethrow;
    }
  }

  /// Check if all required features are ready
  bool areAllFeaturesReady() {
    return state.allFeaturesReady;
  }

  /// Get list of features that need user action
  List<FeatureType> getFeaturesNeedingUserAction() {
    return state.disabledFeatures;
  }
}

/// Error handling provider
final errorHandlingProvider =
    StateNotifierProvider<ErrorHandlingNotifier, ErrorState>((ref) {
      return ErrorHandlingNotifier();
    });

/// Feature status provider
final featureStatusProvider =
    StateNotifierProvider<FeatureStatusNotifier, FeatureStatusState>((ref) {
      return FeatureStatusNotifier();
    });

/// Bluetooth ready provider
final isBluetoothReadyProvider = Provider<bool>((ref) {
  final status = ref.watch(featureStatusProvider);
  return status.isFeatureReady(FeatureType.bluetooth);
});

/// WiFi ready provider
final isWiFiReadyProvider = Provider<bool>((ref) {
  final status = ref.watch(featureStatusProvider);
  return status.isFeatureReady(FeatureType.wifi);
});

/// Location ready provider
final isLocationReadyProvider = Provider<bool>((ref) {
  final status = ref.watch(featureStatusProvider);
  return status.isFeatureReady(FeatureType.location);
});

/// All features ready provider
final areAllFeaturesReadyProvider = Provider<bool>((ref) {
  final status = ref.watch(featureStatusProvider);
  return status.allFeaturesReady;
});

/// Features needing user action provider
final featuresNeedingActionProvider = Provider<List<FeatureType>>((ref) {
  final status = ref.watch(featureStatusProvider);
  return status.disabledFeatures;
});
