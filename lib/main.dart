import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flux/src/rust/frb_generated.dart';
import 'package:flux/config/app_theme.dart';
import 'package:flux/utils/logger.dart';
import 'package:flux/services/permission_service.dart';
import 'package:flux/services/connectivity_service.dart';
import 'package:flux/providers/settings_provider.dart';
import 'package:flux/screens/home_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Rust bridge
  try {
    await RustLib.init();
    AppLogger.info('Rust bridge initialized successfully');
  } catch (e) {
    AppLogger.error('Failed to initialize Rust bridge', e);
  }

  // Initialize services
  await _initializeServices();

  runApp(const ProviderScope(child: MyApp()));
}

Future<void> _initializeServices() async {
  try {
    AppLogger.info('Initializing services...');

    // Initialize permission service
    await PermissionService().initialize();

    // Initialize connectivity service
    await ConnectivityService().initialize();

    AppLogger.info('All services initialized successfully');
  } catch (e) {
    AppLogger.error('Failed to initialize services', e);
  }
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
