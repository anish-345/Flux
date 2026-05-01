import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flux/src/rust/frb_generated.dart';
import 'package:flux/config/app_theme.dart';
import 'package:flux/utils/logger.dart';
import 'package:flux/services/permission_service.dart';
import 'package:flux/services/connectivity_service.dart';
import 'package:flux/services/bluetooth_service.dart';
import 'package:flux/providers/settings_provider.dart';
import 'package:flux/screens/home_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Rust bridge - CRITICAL: Must succeed for crypto operations
  try {
    await RustLib.init();
    AppLogger.info('✅ Rust bridge initialized successfully');
  } catch (e) {
    AppLogger.error(
      '❌ FATAL: Rust bridge initialization failed - crypto unavailable',
      e,
    );
    // Show blocking error UI - Rust is required for security
    runApp(const ProviderScope(child: UnsupportedDeviceScreen()));
    return;
  }

  // Initialize services
  await _initializeServices();

  runApp(const ProviderScope(child: MyApp()));
}

Future<void> _initializeServices() async {
  AppLogger.info('🚀 Initializing services...');

  // Initialize permission service
  try {
    await PermissionService().initialize();
    AppLogger.info('✅ Permission service initialized');
  } catch (e) {
    AppLogger.error('⚠️ Failed to initialize permission service', e);
    // Continue - permissions can be requested on-demand
  }

  // Initialize connectivity service
  try {
    await ConnectivityService().initialize();
    AppLogger.info('✅ Connectivity service initialized');
  } catch (e) {
    AppLogger.error('⚠️ Failed to initialize connectivity service', e);
    // Continue - connectivity can be checked on-demand
  }

  // Initialize Bluetooth service
  try {
    final bluetoothService = BluetoothService();
    final isAvailable = await bluetoothService.isBluetoothAvailable();
    if (isAvailable) {
      AppLogger.info('✅ Bluetooth service initialized');
    } else {
      AppLogger.info('⚠️ Bluetooth not available on this device');
    }
  } catch (e) {
    AppLogger.error('⚠️ Failed to initialize Bluetooth service', e);
    // Continue - Bluetooth is optional
  }

  AppLogger.info('✅ All services initialized');
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);

    return MaterialApp(
      title: 'Flux Share',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme(),
      darkTheme: AppTheme.darkTheme(),
      themeMode: settings.themeMode,
      locale: Locale(settings.languageCode),
      home: const HomeScreen(),
    );
  }
}

/// Screen shown when Rust bridge initialization fails
/// This is a blocking error because crypto is required for security
class UnsupportedDeviceScreen extends StatelessWidget {
  const UnsupportedDeviceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flux Share - Unsupported Device',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme(),
      darkTheme: AppTheme.darkTheme(),
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 24),
                const Text(
                  'Device Not Supported',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Flux Share requires native cryptography support that is not available on this device.\n\n'
                  'This is a security requirement to protect your files during transfer.',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                ElevatedButton.icon(
                  onPressed: () {
                    // Exit app
                    exit(1);
                  },
                  icon: const Icon(Icons.exit_to_app),
                  label: const Text('Exit'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
