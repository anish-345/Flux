import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flux/utils/logger.dart';

/// App settings model
class AppSettings {
  final String deviceName;
  final ThemeMode themeMode;
  final bool notificationsEnabled;
  final String? downloadDirectory;
  final bool autoAcceptFromTrustedDevices;
  final int maxConcurrentTransfers;
  final bool enableEncryption;
  final String languageCode;

  const AppSettings({
    required this.deviceName,
    this.themeMode = ThemeMode.system,
    this.notificationsEnabled = true,
    this.downloadDirectory,
    this.autoAcceptFromTrustedDevices = false,
    this.maxConcurrentTransfers = 3,
    this.enableEncryption = true,
    this.languageCode = 'en',
  });

  AppSettings copyWith({
    String? deviceName,
    ThemeMode? themeMode,
    bool? notificationsEnabled,
    String? downloadDirectory,
    bool? autoAcceptFromTrustedDevices,
    int? maxConcurrentTransfers,
    bool? enableEncryption,
    String? languageCode,
  }) {
    return AppSettings(
      deviceName: deviceName ?? this.deviceName,
      themeMode: themeMode ?? this.themeMode,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      downloadDirectory: downloadDirectory ?? this.downloadDirectory,
      autoAcceptFromTrustedDevices:
          autoAcceptFromTrustedDevices ?? this.autoAcceptFromTrustedDevices,
      maxConcurrentTransfers:
          maxConcurrentTransfers ?? this.maxConcurrentTransfers,
      enableEncryption: enableEncryption ?? this.enableEncryption,
      languageCode: languageCode ?? this.languageCode,
    );
  }
}

/// Provider for app settings
final settingsProvider = StateNotifierProvider<SettingsNotifier, AppSettings>((
  ref,
) {
  return SettingsNotifier();
});

class SettingsNotifier extends StateNotifier<AppSettings> {
  late SharedPreferences _prefs;
  bool _isInitialized = false;

  SettingsNotifier()
    : super(
        const AppSettings(
          deviceName: 'My Device',
          themeMode: ThemeMode.system,
          notificationsEnabled: true,
          autoAcceptFromTrustedDevices: false,
          maxConcurrentTransfers: 3,
          enableEncryption: true,
          languageCode: 'en',
        ),
      ) {
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      _prefs = await SharedPreferences.getInstance();
      await _loadSettings();
      _isInitialized = true;
      AppLogger.info('SettingsNotifier initialized');
    } catch (e) {
      AppLogger.error('Failed to initialize SettingsNotifier', e);
    }
  }

  Future<void> _loadSettings() async {
    try {
      final deviceName = _prefs.getString('device_name') ?? 'My Device';
      final themeModeIndex = _prefs.getInt('theme_mode') ?? 0;
      final notificationsEnabled =
          _prefs.getBool('notifications_enabled') ?? true;
      final downloadDirectory = _prefs.getString('download_directory');
      final autoAcceptFromTrusted =
          _prefs.getBool('auto_accept_from_trusted') ?? false;
      final maxConcurrentTransfers =
          _prefs.getInt('max_concurrent_transfers') ?? 3;
      final enableEncryption = _prefs.getBool('enable_encryption') ?? true;
      final languageCode = _prefs.getString('language_code') ?? 'en';

      state = AppSettings(
        deviceName: deviceName,
        themeMode: ThemeMode.values[themeModeIndex],
        notificationsEnabled: notificationsEnabled,
        downloadDirectory: downloadDirectory,
        autoAcceptFromTrustedDevices: autoAcceptFromTrusted,
        maxConcurrentTransfers: maxConcurrentTransfers,
        enableEncryption: enableEncryption,
        languageCode: languageCode,
      );

      AppLogger.info('Settings loaded from storage');
    } catch (e) {
      AppLogger.error('Failed to load settings', e);
    }
  }

  Future<void> _saveSettings() async {
    try {
      if (!_isInitialized) return;

      await _prefs.setString('device_name', state.deviceName);
      await _prefs.setInt('theme_mode', state.themeMode.index);
      await _prefs.setBool('notifications_enabled', state.notificationsEnabled);
      if (state.downloadDirectory != null) {
        await _prefs.setString('download_directory', state.downloadDirectory!);
      }
      await _prefs.setBool(
        'auto_accept_from_trusted',
        state.autoAcceptFromTrustedDevices,
      );
      await _prefs.setInt(
        'max_concurrent_transfers',
        state.maxConcurrentTransfers,
      );
      await _prefs.setBool('enable_encryption', state.enableEncryption);
      await _prefs.setString('language_code', state.languageCode);

      AppLogger.info('Settings saved to storage');
    } catch (e) {
      AppLogger.error('Failed to save settings', e);
    }
  }

  Future<void> updateDeviceName(String name) async {
    try {
      state = state.copyWith(deviceName: name);
      await _saveSettings();
      AppLogger.info('Device name updated: $name');
    } catch (e) {
      AppLogger.error('Failed to update device name', e);
      rethrow;
    }
  }

  Future<void> updateThemeMode(ThemeMode mode) async {
    try {
      state = state.copyWith(themeMode: mode);
      await _saveSettings();
      AppLogger.info('Theme mode updated: ${mode.name}');
    } catch (e) {
      AppLogger.error('Failed to update theme mode', e);
      rethrow;
    }
  }

  Future<void> updateNotificationsEnabled(bool enabled) async {
    try {
      state = state.copyWith(notificationsEnabled: enabled);
      await _saveSettings();
      AppLogger.info('Notifications enabled: $enabled');
    } catch (e) {
      AppLogger.error('Failed to update notifications setting', e);
      rethrow;
    }
  }

  Future<void> updateDownloadDirectory(String? directory) async {
    try {
      state = state.copyWith(downloadDirectory: directory);
      await _saveSettings();
      AppLogger.info('Download directory updated: $directory');
    } catch (e) {
      AppLogger.error('Failed to update download directory', e);
      rethrow;
    }
  }

  Future<void> updateAutoAcceptFromTrusted(bool enabled) async {
    try {
      state = state.copyWith(autoAcceptFromTrustedDevices: enabled);
      await _saveSettings();
      AppLogger.info('Auto-accept from trusted devices: $enabled');
    } catch (e) {
      AppLogger.error('Failed to update auto-accept setting', e);
      rethrow;
    }
  }

  Future<void> updateMaxConcurrentTransfers(int count) async {
    try {
      state = state.copyWith(maxConcurrentTransfers: count);
      await _saveSettings();
      AppLogger.info('Max concurrent transfers updated: $count');
    } catch (e) {
      AppLogger.error('Failed to update max concurrent transfers', e);
      rethrow;
    }
  }

  Future<void> updateEncryption(bool enabled) async {
    try {
      state = state.copyWith(enableEncryption: enabled);
      await _saveSettings();
      AppLogger.info('Encryption enabled: $enabled');
    } catch (e) {
      AppLogger.error('Failed to update encryption setting', e);
      rethrow;
    }
  }

  Future<void> updateLanguage(String languageCode) async {
    try {
      state = state.copyWith(languageCode: languageCode);
      await _saveSettings();
      AppLogger.info('Language updated: $languageCode');
    } catch (e) {
      AppLogger.error('Failed to update language', e);
      rethrow;
    }
  }

  Future<void> resetToDefaults() async {
    try {
      state = const AppSettings(
        deviceName: 'My Device',
        themeMode: ThemeMode.system,
        notificationsEnabled: true,
        autoAcceptFromTrustedDevices: false,
        maxConcurrentTransfers: 3,
        enableEncryption: true,
        languageCode: 'en',
      );
      await _saveSettings();
      AppLogger.info('Settings reset to defaults');
    } catch (e) {
      AppLogger.error('Failed to reset settings', e);
      rethrow;
    }
  }
}
