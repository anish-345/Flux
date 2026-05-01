import 'dart:convert';
import 'dart:io';
import 'package:flux/utils/logger.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:wifi_iot/wifi_iot.dart';

/// Holds WiFi credentials that can be shared via QR code or Bluetooth.
class WifiCredentials {
  final String ssid;
  final String? password;
  final String? ipAddress;
  final int? fluxPort;

  const WifiCredentials({
    required this.ssid,
    this.password,
    this.ipAddress,
    this.fluxPort,
  });

  /// Encode as a QR-friendly JSON string.
  String toQrString() => jsonEncode({
    'type': 'flux_wifi',
    'ssid': ssid,
    if (password != null) 'password': password,
    if (ipAddress != null) 'ip': ipAddress,
    if (fluxPort != null) 'port': fluxPort,
  });

  /// Parse from QR JSON string. Returns null if not a valid flux_wifi payload.
  static WifiCredentials? fromQrString(String raw) {
    try {
      final json = jsonDecode(raw) as Map<String, dynamic>;
      if (json['type'] != 'flux_wifi') return null;
      return WifiCredentials(
        ssid: json['ssid'] as String,
        password: json['password'] as String?,
        ipAddress: json['ip'] as String?,
        fluxPort: (json['port'] as num?)?.toInt(),
      );
    } catch (_) {
      return null;
    }
  }

  @override
  String toString() =>
      'WifiCredentials(ssid: $ssid, ip: $ipAddress, port: $fluxPort)';
}

/// Service that reads the current WiFi SSID and, where possible, the password.
///
/// Password retrieval:
///   - Windows: `netsh wlan show profile name="<ssid>" key=clear`
///   - Android: requires root or Android 10+ Companion Device API — not available
///     without special permissions, so we return null and let the user type it.
///   - Linux/macOS: reads from NetworkManager / Keychain (best-effort).
class WifiCredentialService {
  final NetworkInfo _networkInfo = NetworkInfo();

  /// Get the current WiFi SSID.
  Future<String?> getCurrentSsid() async {
    try {
      return await _networkInfo.getWifiName();
    } catch (e) {
      AppLogger.warning('Could not get WiFi SSID: $e');
      return null;
    }
  }

  /// Get the current WiFi IP address.
  Future<String?> getCurrentIp() async {
    try {
      return await _networkInfo.getWifiIP();
    } catch (e) {
      AppLogger.warning('Could not get WiFi IP: $e');
      return null;
    }
  }

  /// Try to retrieve the WiFi password for the currently connected network.
  ///
  /// Returns null if the platform doesn't support it or permission is denied.
  Future<String?> getCurrentWifiPassword() async {
    try {
      if (Platform.isWindows) {
        return await _getWindowsWifiPassword();
      } else if (Platform.isLinux) {
        return await _getLinuxWifiPassword();
      }
      // Android / iOS / macOS — not accessible without special permissions
      return null;
    } catch (e) {
      AppLogger.warning('Could not retrieve WiFi password: $e');
      return null;
    }
  }

  /// Build a [WifiCredentials] object for the current network.
  /// [fluxPort] is the port the Flux transfer server is listening on.
  Future<WifiCredentials?> getCurrentNetworkCredentials({int? fluxPort}) async {
    final ssid = await getCurrentSsid();
    if (ssid == null || ssid.isEmpty) return null;

    final ip = await getCurrentIp();
    final password = await getCurrentWifiPassword();

    return WifiCredentials(
      ssid: ssid.replaceAll(
        '"',
        '',
      ), // network_info_plus wraps in quotes on some platforms
      password: password,
      ipAddress: ip,
      fluxPort: fluxPort,
    );
  }

  /// Connect to a WiFi network using the provided credentials.
  /// Android only — returns false on other platforms.
  Future<bool> connectToNetwork(WifiCredentials creds) async {
    if (!Platform.isAndroid) return false;
    if (creds.password == null) return false;

    try {
      AppLogger.info('Connecting to WiFi: ${creds.ssid}');
      final result = await WiFiForIoTPlugin.connect(
        creds.ssid,
        password: creds.password,
        joinOnce: true,
        security: NetworkSecurity.WPA,
      );
      AppLogger.info('WiFi connect result: $result');
      return result;
    } catch (e) {
      AppLogger.error('Failed to connect to WiFi', e);
      return false;
    }
  }

  // ── Platform-specific password retrieval ──────────────────────────────────

  Future<String?> _getWindowsWifiPassword() async {
    final ssid = await getCurrentSsid();
    if (ssid == null) return null;
    final cleanSsid = ssid.replaceAll('"', '');

    final result = await Process.run('netsh', [
      'wlan',
      'show',
      'profile',
      'name=$cleanSsid',
      'key=clear',
    ], stdoutEncoding: const SystemEncoding());

    if (result.exitCode != 0) return null;

    // Parse "Key Content : <password>" from netsh output
    final lines = (result.stdout as String).split('\n');
    for (final line in lines) {
      if (line.contains('Key Content')) {
        final parts = line.split(':');
        if (parts.length >= 2) {
          return parts.sublist(1).join(':').trim();
        }
      }
    }
    return null;
  }

  Future<String?> _getLinuxWifiPassword() async {
    final ssid = await getCurrentSsid();
    if (ssid == null) return null;
    final cleanSsid = ssid.replaceAll('"', '');

    // Try NetworkManager connection file
    final nmDir = Directory('/etc/NetworkManager/system-connections');
    if (!await nmDir.exists()) return null;

    await for (final entity in nmDir.list()) {
      if (entity is! File) continue;
      try {
        final content = await entity.readAsString();
        if (content.contains('ssid=$cleanSsid')) {
          for (final line in content.split('\n')) {
            if (line.startsWith('psk=')) {
              return line.substring(4).trim();
            }
          }
        }
      } catch (_) {}
    }
    return null;
  }
}
