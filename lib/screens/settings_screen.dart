import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flux/providers/settings_provider.dart';
import 'package:flux/utils/logger.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  late TextEditingController _deviceNameController;

  @override
  void initState() {
    super.initState();
    final settings = ref.read(settingsProvider);
    _deviceNameController = TextEditingController(text: settings.deviceName);
  }

  @override
  void dispose() {
    _deviceNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          // Device Settings Section
          _buildSectionHeader(context, 'Device'),
          _buildDeviceNameTile(context),
          const Divider(),

          // Display Settings Section
          _buildSectionHeader(context, 'Display'),
          _buildThemeModeTile(context, settings),
          const Divider(),

          // Transfer Settings Section
          _buildSectionHeader(context, 'Transfer'),
          _buildAutoAcceptTile(context, settings),
          _buildMaxConcurrentTransfersTile(context, settings),
          _buildEncryptionTile(context, settings),
          const Divider(),

          // Notification Settings Section
          _buildSectionHeader(context, 'Notifications'),
          _buildNotificationsTile(context, settings),
          const Divider(),

          // Language Settings Section
          _buildSectionHeader(context, 'Language'),
          _buildLanguageTile(context, settings),
          const Divider(),

          // About Section
          _buildSectionHeader(context, 'About'),
          _buildAboutTile(context),
          _buildVersionTile(context),

          // Reset Button
          Padding(
            padding: const EdgeInsets.all(16),
            child: OutlinedButton.icon(
              onPressed: () => _showResetDialog(context),
              icon: const Icon(Icons.refresh),
              label: const Text('Reset to Defaults'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }

  Widget _buildDeviceNameTile(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: TextField(
        controller: _deviceNameController,
        decoration: InputDecoration(
          labelText: 'Device Name',
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          suffixIcon: IconButton(
            icon: const Icon(Icons.check),
            onPressed: () => _updateDeviceName(),
          ),
        ),
      ),
    );
  }

  Widget _buildThemeModeTile(BuildContext context, AppSettings settings) {
    return ListTile(
      title: const Text('Theme'),
      subtitle: Text(settings.themeMode.name.toUpperCase()),
      trailing: DropdownButton<ThemeMode>(
        value: settings.themeMode,
        items: ThemeMode.values
            .map(
              (mode) => DropdownMenuItem(
                value: mode,
                child: Text(mode.name.toUpperCase()),
              ),
            )
            .toList(),
        onChanged: (mode) {
          if (mode != null) {
            ref.read(settingsProvider.notifier).updateThemeMode(mode);
          }
        },
      ),
    );
  }

  Widget _buildAutoAcceptTile(BuildContext context, AppSettings settings) {
    return ListTile(
      title: const Text('Auto-Accept from Trusted Devices'),
      subtitle: const Text(
        'Automatically accept transfers from trusted devices',
      ),
      trailing: Switch(
        value: settings.autoAcceptFromTrustedDevices,
        onChanged: (value) {
          ref
              .read(settingsProvider.notifier)
              .updateAutoAcceptFromTrusted(value);
        },
      ),
    );
  }

  Widget _buildMaxConcurrentTransfersTile(
    BuildContext context,
    AppSettings settings,
  ) {
    return ListTile(
      title: const Text('Max Concurrent Transfers'),
      subtitle: Text('${settings.maxConcurrentTransfers} transfers'),
      trailing: DropdownButton<int>(
        value: settings.maxConcurrentTransfers,
        items: [1, 2, 3, 4, 5]
            .map(
              (count) => DropdownMenuItem(value: count, child: Text('$count')),
            )
            .toList(),
        onChanged: (count) {
          if (count != null) {
            ref
                .read(settingsProvider.notifier)
                .updateMaxConcurrentTransfers(count);
          }
        },
      ),
    );
  }

  Widget _buildEncryptionTile(BuildContext context, AppSettings settings) {
    return ListTile(
      title: const Text('Enable Encryption'),
      subtitle: const Text('Encrypt files during transfer'),
      trailing: Switch(
        value: settings.enableEncryption,
        onChanged: (value) {
          ref.read(settingsProvider.notifier).updateEncryption(value);
        },
      ),
    );
  }

  Widget _buildNotificationsTile(BuildContext context, AppSettings settings) {
    return ListTile(
      title: const Text('Notifications'),
      subtitle: const Text('Receive transfer notifications'),
      trailing: Switch(
        value: settings.notificationsEnabled,
        onChanged: (value) {
          ref.read(settingsProvider.notifier).updateNotificationsEnabled(value);
        },
      ),
    );
  }

  Widget _buildLanguageTile(BuildContext context, AppSettings settings) {
    return ListTile(
      title: const Text('Language'),
      subtitle: Text(settings.languageCode.toUpperCase()),
      trailing: DropdownButton<String>(
        value: settings.languageCode,
        items: ['en', 'es', 'fr', 'de', 'ja', 'zh']
            .map(
              (code) => DropdownMenuItem(
                value: code,
                child: Text(code.toUpperCase()),
              ),
            )
            .toList(),
        onChanged: (code) {
          if (code != null) {
            ref.read(settingsProvider.notifier).updateLanguage(code);
          }
        },
      ),
    );
  }

  Widget _buildAboutTile(BuildContext context) {
    return ListTile(
      title: const Text('About Flux'),
      subtitle: const Text('Fast, secure file sharing'),
      trailing: const Icon(Icons.info),
      onTap: () => _showAboutDialog(context),
    );
  }

  Widget _buildVersionTile(BuildContext context) {
    return ListTile(
      title: const Text('Version'),
      subtitle: const Text('1.0.0'),
      trailing: const Icon(Icons.code),
    );
  }

  Future<void> _updateDeviceName() async {
    try {
      await ref
          .read(settingsProvider.notifier)
          .updateDeviceName(_deviceNameController.text);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Device name updated')));
      }
    } catch (e) {
      AppLogger.error('Failed to update device name', e);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to update: $e')));
      }
    }
  }

  void _showResetDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Settings'),
        content: const Text(
          'Are you sure you want to reset all settings to defaults?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              await ref.read(settingsProvider.notifier).resetToDefaults();
              if (mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Settings reset to defaults')),
                );
              }
            },
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: 'Flux',
      applicationVersion: '1.0.0',
      applicationLegalese: '© 2024 Flux. All rights reserved.',
      children: [
        const SizedBox(height: 16),
        const Text('Fast, secure, and easy file sharing between devices.'),
      ],
    );
  }
}
