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

  // Initialize Rust bridge
  try {
    await RustLib.init();
    AppLogger.info('✅ Rust bridge initialized successfully');
  } catch (e) {
    AppLogger.error('❌ Failed to initialize Rust bridge', e);
    // Continue anyway - Rust features may not be critical
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
      title: 'Flux',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme(),
      darkTheme: AppTheme.darkTheme(),
      themeMode: settings.themeMode,
      locale: Locale(settings.languageCode),
      home: const HomeScreen(),
    );
  }
}
