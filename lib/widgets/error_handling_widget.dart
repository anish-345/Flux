import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flux/providers/error_handling_provider.dart';
import 'package:flux/services/feature_enablement_service.dart';
import 'package:flux/config/app_theme.dart';

/// Widget for displaying and handling errors
class ErrorHandlingWidget extends ConsumerWidget {
  final Widget child;
  final VoidCallback? onErrorDismiss;

  const ErrorHandlingWidget({
    super.key,
    required this.child,
    this.onErrorDismiss,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final errorState = ref.watch(errorHandlingProvider);
    final featureStatus = ref.watch(featureStatusProvider);

    return Stack(
      children: [
        child,
        if (errorState.hasError)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _buildErrorBanner(context, ref, errorState),
          ),
        if (!featureStatus.allFeaturesReady)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: _buildFeatureWarning(context, ref, featureStatus),
          ),
      ],
    );
  }

  Widget _buildErrorBanner(
    BuildContext context,
    WidgetRef ref,
    ErrorState errorState,
  ) {
    return Material(
      child: Container(
        color: AppTheme.errorColor,
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Error',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        errorState.message ?? 'An error occurred',
                        style: Theme.of(
                          context,
                        ).textTheme.bodySmall?.copyWith(color: Colors.white),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () {
                    ref.read(errorHandlingProvider.notifier).clearError();
                    onErrorDismiss?.call();
                  },
                ),
              ],
            ),
            if (errorState.requiresUserAction)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppTheme.errorColor,
                    ),
                    onPressed: () {
                      _handleFeatureAction(context, ref, errorState);
                    },
                    child: const Text('Take Action'),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureWarning(
    BuildContext context,
    WidgetRef ref,
    FeatureStatusState featureStatus,
  ) {
    final disabledFeatures = featureStatus.disabledFeatures;

    if (disabledFeatures.isEmpty) {
      return const SizedBox.shrink();
    }

    return Material(
      child: Container(
        color: AppTheme.warningColor.withOpacity(0.9),
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.warning, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Required features disabled',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: disabledFeatures.map((feature) {
                return Chip(
                  label: Text(
                    'Enable ${feature.name}',
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                  backgroundColor: Colors.white.withOpacity(0.2),
                  onDeleted: () {
                    _enableFeature(ref, feature);
                  },
                  deleteIcon: const Icon(Icons.check, size: 16),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  void _handleFeatureAction(
    BuildContext context,
    WidgetRef ref,
    ErrorState errorState,
  ) {
    if (errorState.affectedFeature == null) return;

    _enableFeature(ref, errorState.affectedFeature!);
  }

  void _enableFeature(WidgetRef ref, FeatureType feature) {
    final notifier = ref.read(featureStatusProvider.notifier);

    switch (feature) {
      case FeatureType.bluetooth:
        notifier.ensureBluetoothEnabled();
        break;
      case FeatureType.wifi:
        notifier.ensureWiFiEnabled();
        break;
      case FeatureType.location:
        notifier.ensureLocationEnabled();
        break;
      case FeatureType.hotspot:
        // Hotspot is typically enabled through WiFi
        notifier.ensureWiFiEnabled();
        break;
    }
  }
}

/// Dialog for feature enablement
class FeatureEnablementDialog extends ConsumerWidget {
  final FeatureType feature;
  final VoidCallback? onRetry;

  const FeatureEnablementDialog({
    super.key,
    required this.feature,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AlertDialog(
      title: Text('Enable ${feature.name}'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _getFeatureDescription(feature),
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          _buildFeatureInstructions(context, feature),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            _enableFeature(ref, feature);
            Navigator.pop(context);
            onRetry?.call();
          },
          child: const Text('Enable'),
        ),
      ],
    );
  }

  String _getFeatureDescription(FeatureType feature) {
    switch (feature) {
      case FeatureType.bluetooth:
        return 'Bluetooth is required for connecting to nearby devices.';
      case FeatureType.wifi:
        return 'WiFi is required for fast file transfers.';
      case FeatureType.location:
        return 'Location permission is required for WiFi scanning.';
      case FeatureType.hotspot:
        return 'WiFi hotspot is required for sharing files.';
    }
  }

  Widget _buildFeatureInstructions(BuildContext context, FeatureType feature) {
    final instructions = _getInstructions(feature);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Steps:',
          style: Theme.of(
            context,
          ).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        ...instructions.asMap().entries.map((entry) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${entry.key + 1}. ',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                Expanded(
                  child: Text(
                    entry.value,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ],
    );
  }

  List<String> _getInstructions(FeatureType feature) {
    switch (feature) {
      case FeatureType.bluetooth:
        return ['Open Settings', 'Go to Bluetooth', 'Toggle Bluetooth ON'];
      case FeatureType.wifi:
        return ['Open Settings', 'Go to WiFi', 'Select a network and connect'];
      case FeatureType.location:
        return [
          'Open Settings',
          'Go to Apps > Permissions',
          'Grant Location permission',
        ];
      case FeatureType.hotspot:
        return [
          'Open Settings',
          'Go to Hotspot & Tethering',
          'Enable WiFi Hotspot',
        ];
    }
  }

  void _enableFeature(WidgetRef ref, FeatureType feature) {
    final notifier = ref.read(featureStatusProvider.notifier);

    switch (feature) {
      case FeatureType.bluetooth:
        notifier.ensureBluetoothEnabled();
        break;
      case FeatureType.wifi:
        notifier.ensureWiFiEnabled();
        break;
      case FeatureType.location:
        notifier.ensureLocationEnabled();
        break;
      case FeatureType.hotspot:
        notifier.ensureWiFiEnabled();
        break;
    }
  }
}
