import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:flux/services/peer_discovery_service.dart';

/// QR Scanner View
/// Handles camera and QR code decoding
class QrScannerView extends StatefulWidget {
  final PeerDiscoveryService peerDiscovery;
  final Function(String code) onCodeScanned;
  final VoidCallback? onCancel;

  const QrScannerView({
    super.key,
    required this.peerDiscovery,
    required this.onCodeScanned,
    this.onCancel,
  });

  @override
  State<QrScannerView> createState() => _QrScannerViewState();
}

class _QrScannerViewState extends State<QrScannerView> {
  bool _isProcessing = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Scan QR Code',
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          if (widget.onCancel != null)
            IconButton(
              icon: const Icon(Icons.close, color: Colors.white),
              onPressed: widget.onCancel,
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: MobileScanner(
              onDetect: _onDetect,
              errorBuilder: (context, error, child) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.camera_alt_outlined,
                        size: 64,
                        color: Colors.white54,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Camera error: $error',
                        style: const TextStyle(color: Colors.white54),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.all(24),
            color: Colors.black,
            child: Column(
              children: [
                const Text(
                  'Point camera at QR code',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'The app will automatically connect when a valid code is detected',
                  style: TextStyle(
                    color: Colors.white54,
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _onDetect(BarcodeCapture capture) {
    if (_isProcessing) return;

    final barcode = capture.barcodes.first;
    if (barcode.rawValue == null) return;

    final code = barcode.rawValue!;
    
    // Try to parse as ConnectionInfo
    final connectionInfo = widget.peerDiscovery.parseConnectionInfo(code);
    if (connectionInfo != null) {
      _isProcessing = true;
      widget.onCodeScanned(code);
      
      // Reset processing flag after delay
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          setState(() => _isProcessing = false);
        }
      });
    }
  }
}
