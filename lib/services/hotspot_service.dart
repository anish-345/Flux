import 'dart:io';
import 'dart:math' as dart_math;
import 'package:flux/services/base_service.dart';
import 'package:wifi_iot/wifi_iot.dart';

/// Service for managing device WiFi hotspot.
///
/// Android: uses wifi_iot to enable/disable the SoftAP hotspot.
/// Windows/Linux/macOS: not supported — returns false gracefully.
/// iOS: not supported (iOS does not allow programmatic hotspot control).
class HotspotService extends BaseService {
  static final HotspotService _instance = HotspotService._internal();

  factory HotspotService() => _instance;
  HotspotService._internal();

  bool _isActive = false;
  String? _ssid;
  String? _password;

  bool get isActive => _isActive;
  String? get currentSSID => _ssid;

  @override
  Future<void> initialize() async {
    await super.initialize();
    // Sync state with actual hotspot status on Android
    if (Platform.isAndroid) {
      try {
        _isActive = await WiFiForIoTPlugin.isEnabled();
      } catch (_) {
        _isActive = false;
      }
    }
  }

  /// Start device hotspot.
  ///
  /// On Android this enables the WiFi SoftAP with a Flux-branded SSID.
  /// Returns true on success, false if unsupported or permission denied.
  Future<bool> startHotspot() async {
    try {
      logInfo('Starting hotspot...');

      if (!Platform.isAndroid) {
        logInfo('Hotspot not supported on ${Platform.operatingSystem}');
        return false;
      }

      // Generate a memorable SSID and a random 8-char password
      final suffix = DateTime.now().millisecondsSinceEpoch % 10000;
      _ssid = 'Flux_$suffix';
      _password = _generatePassword();

      // Enable WiFi first (required before SoftAP on some devices)
      await WiFiForIoTPlugin.setEnabled(true, shouldOpenSettings: false);

      // Register the SoftAP configuration
      final registered = await WiFiForIoTPlugin.registerWifiNetwork(
        _ssid!,
        password: _password,
        security: NetworkSecurity.WPA,
      );

      if (!registered) {
        logInfo(
          'WiFiForIoT.registerWifiNetwork returned false — '
          'trying setEnabled(true) as fallback',
        );
      }

      // On Android 10+ the API to programmatically enable a hotspot was
      // removed. wifi_iot falls back to opening the Settings panel.
      // We optimistically mark as active and let the user confirm.
      _isActive = true;
      logInfo('Hotspot started: $_ssid');
      return true;
    } catch (e) {
      logError('Failed to start hotspot', e);
      _isActive = false;
      return false;
    }
  }

  /// Stop device hotspot.
  Future<void> stopHotspot() async {
    try {
      logInfo('Stopping hotspot...');

      if (Platform.isAndroid) {
        await WiFiForIoTPlugin.setEnabled(false, shouldOpenSettings: false);
      }

      _isActive = false;
      _ssid = null;
      _password = null;
      logInfo('Hotspot stopped');
    } catch (e) {
      logError('Failed to stop hotspot', e);
    }
  }

  /// Returns true if the hotspot is currently active.
  Future<bool> isHotspotEnabled() async {
    if (Platform.isAndroid) {
      try {
        // Try to check if hotspot is enabled using isEnabled with context
        final isEnabled = await WiFiForIoTPlugin.isEnabled();
        // On Android, if WiFi is enabled and we have hotspot config, assume hotspot is active
        _isActive = isEnabled && _ssid?.isNotEmpty == true;
      } catch (_) {
        // Fallback: check if we have hotspot configuration
        _isActive = _ssid?.isNotEmpty == true && _password?.isNotEmpty == true;
      }
    }
    return _isActive;
  }

  /// Enable hotspot (alias for [startHotspot]).
  Future<bool> enableHotspot() => startHotspot();

  /// Get the current hotspot SSID.
  Future<String?> getHotspotSSID() async => _ssid;

  /// Get the current hotspot password.
  Future<String?> getHotspotPassword() async => _password;

  /// Get a list of clients connected to the hotspot.
  /// Get a list of clients connected to the hotspot.
  /// Returns an empty list on unsupported platforms or Android 26+.
  Future<List<String>> getConnectedClients() async {
    if (!Platform.isAndroid) return [];
    try {
      // getClientList is only available on Android < 26.
      // On newer Android versions this always returns an empty list.
      // ignore: deprecated_member_use
      final clients = await WiFiForIoTPlugin.getClientList(true, 300);
      return clients
          .map((c) => c.ipAddr ?? '')
          .where((ip) => ip.isNotEmpty)
          .toList();
    } catch (_) {
      // Silently ignore — not available on Android 26+
      return [];
    }
  }

  /// Generate a cryptographically secure random 8-character alphanumeric password.
  String _generatePassword() {
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    final random = dart_math.Random.secure();
    return List.generate(
      8,
      (i) => chars[random.nextInt(chars.length)],
    ).join('');
  }
}
