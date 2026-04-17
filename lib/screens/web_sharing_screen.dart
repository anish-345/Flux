import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:flux/services/connectivity_service.dart';
import 'package:flux/config/app_theme.dart';
import 'package:flux/utils/logger.dart';

class WebSharingScreen extends ConsumerStatefulWidget {
  const WebSharingScreen({super.key});

  @override
  ConsumerState<WebSharingScreen> createState() => _WebSharingScreenState();
}

class _WebSharingScreenState extends ConsumerState<WebSharingScreen> {
  String? _serverUrl;
  bool _isStarting = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _startWebServer();
  }

  Future<void> _startWebServer() async {
    try {
      final connectivity = ref.read(connectivityServiceProvider);
      final ip = await connectivity.getDeviceIPAddress();

      if (ip == null || ip == '0.0.0.0') {
        setState(() {
          _error = 'Not connected to a network. Please connect to WiFi or start a hotspot.';
          _isStarting = false;
        });
        return;
      }

      // TODO: Call actual Rust web server when bridge is generated
      // For now, we simulate the URL
      await Future.delayed(const Duration(seconds: 1));
      
      if (mounted) {
        setState(() {
          _serverUrl = 'http://$ip:8080';
          _isStarting = false;
        });
      }
    } catch (e) {
      AppLogger.error('Failed to start web server', e);
      if (mounted) {
        setState(() {
          _error = 'Failed to start web server: $e';
          _isStarting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Web Share'),
        centerTitle: true,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_isStarting) ...[
                const CircularProgressIndicator(),
                const SizedBox(height: 24),
                const Text('Starting web server...'),
              ] else if (_error != null) ...[
                Icon(Icons.error_outline, size: 64, color: Theme.of(context).colorScheme.error),
                const SizedBox(height: 24),
                Text(_error!, textAlign: TextAlign.center, style: const TextStyle(fontSize: 16)),
                const SizedBox(height: 24),
                FilledButton(onPressed: _startWebServer, child: const Text('Retry')),
              ] else ...[
                _buildQRCodeCard(),
                const SizedBox(height: 32),
                _buildInstructions(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQRCodeCard() {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            QrImageView(
              data: _serverUrl!,
              version: QrVersions.auto,
              size: 200.0,
              backgroundColor: Colors.white,
            ),
            const SizedBox(height: 24),
            Text(
              'Scan to connect',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _serverUrl!,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                  fontWeight: FontWeight.w500,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInstructions() {
    return Column(
      children: [
        _buildInfoStep(
          icon: Icons.wifi,
          text: 'Make sure the other device is on the same WiFi network or connected to your hotspot.',
        ),
        const SizedBox(height: 16),
        _buildInfoStep(
          icon: Icons.qr_code_scanner,
          text: 'Open the camera or a QR scanner on the other device and scan the code above.',
        ),
        const SizedBox(height: 16),
        _buildInfoStep(
          icon: Icons.file_present,
          text: 'Selected files will appear on the other device\'s browser for download.',
        ),
      ],
    );
  }

  Widget _buildInfoStep({required IconData icon, required String text}) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: AppTheme.primaryColor, size: 24),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            text,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.4),
          ),
        ),
      ],
    );
  }
}
