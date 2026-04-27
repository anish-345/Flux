import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flux/config/app_theme.dart';

/// Animated radar widget for device discovery
/// Shows scanning animation with ripples and discovered devices
class DeviceRadar extends StatefulWidget {
  final bool isScanning;
  final List<RadarDevice> devices;
  final VoidCallback? onScan;
  final Function(RadarDevice device)? onDeviceTap;

  const DeviceRadar({
    super.key,
    this.isScanning = false,
    this.devices = const [],
    this.onScan,
    this.onDeviceTap,
  });

  @override
  State<DeviceRadar> createState() => _DeviceRadarState();
}

class _DeviceRadarState extends State<DeviceRadar>
    with TickerProviderStateMixin {
  late AnimationController _radarController;
  late AnimationController _pulseController;
  final List<AnimationController> _deviceAnimations = [];

  @override
  void initState() {
    super.initState();
    _radarController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    if (widget.isScanning) {
      _pulseController.repeat();
    }
  }

  @override
  void didUpdateWidget(DeviceRadar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isScanning != oldWidget.isScanning) {
      if (widget.isScanning) {
        _pulseController.repeat();
      } else {
        _pulseController.stop();
      }
    }
  }

  @override
  void dispose() {
    _radarController.dispose();
    _pulseController.dispose();
    for (final controller in _deviceAnimations) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1,
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.surfaceVariant,
          shape: BoxShape.circle,
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Radar rings
            ..._buildRadarRings(),

            // Scanning sweep
            if (widget.isScanning) _buildRadarSweep(),

            // Center hub
            _buildCenterHub(),

            // Discovered devices
            ..._buildDevices(),

            // Scan button overlay
            if (!widget.isScanning && widget.devices.isEmpty)
              _buildScanButton(),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildRadarRings() {
    return [
      _buildRing(0.8, Colors.transparent),
      _buildRing(0.6, AppTheme.primaryColor.withValues(alpha: 0.05)),
      _buildRing(0.4, AppTheme.primaryColor.withValues(alpha: 0.08)),
      _buildRing(0.2, AppTheme.primaryColor.withValues(alpha: 0.1)),
    ];
  }

  Widget _buildRing(double scale, Color color) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      margin: EdgeInsets.all(20 * (1 - scale)),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: AppTheme.borderColor.withValues(alpha: 0.3),
          width: 1,
        ),
        color: color,
      ),
    );
  }

  Widget _buildRadarSweep() {
    return AnimatedBuilder(
      animation: _radarController,
      builder: (context, child) {
        return Transform.rotate(
          angle: _radarController.value * 2 * pi,
          child: Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: SweepGradient(
                center: Alignment.center,
                startAngle: 0,
                endAngle: pi / 4,
                colors: [
                  AppTheme.accentColor.withValues(alpha: 0.0),
                  AppTheme.accentColor.withValues(alpha: 0.3),
                  AppTheme.accentColor.withValues(alpha: 0.0),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCenterHub() {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        final scale = widget.isScanning
            ? 1.0 + (_pulseController.value * 0.1)
            : 1.0;

        return Transform.scale(
          scale: scale,
          child: Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [AppTheme.primaryColor, AppTheme.accentColor],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryColor.withValues(alpha: 0.4),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Icon(
              widget.isScanning ? Icons.radar_rounded : Icons.wifi_rounded,
              color: Colors.white,
              size: 28,
            ),
          ),
        );
      },
    );
  }

  List<Widget> _buildDevices() {
    return widget.devices.asMap().entries.map((entry) {
      final index = entry.key;
      final device = entry.value;
      final angle = (index * (2 * pi / max(widget.devices.length, 1))) - pi / 2;
      final distance = 0.35 + (index % 2) * 0.15;

      return _buildDeviceDot(device, angle, distance);
    }).toList();
  }

  Widget _buildDeviceDot(RadarDevice device, double angle, double distance) {
    final x = cos(angle) * distance;
    final y = sin(angle) * distance;

    return Positioned(
      left: null,
      right: null,
      top: null,
      bottom: null,
      child: FractionallySizedBox(
        widthFactor: 0.5,
        heightFactor: 0.5,
        alignment: Alignment(x, y),
        child: GestureDetector(
          onTap: () => widget.onDeviceTap?.call(device),
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 500),
            builder: (context, value, child) {
              return Transform.scale(
                scale: value,
                child: child,
              );
            },
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      AppTheme.shadowMd,
                    ],
                    border: Border.all(
                      color: device.isConnected
                          ? AppTheme.successColor
                          : AppTheme.primaryColor,
                      width: 2,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      device.icon,
                      style: const TextStyle(fontSize: 20),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [AppTheme.shadowSm],
                  ),
                  child: Text(
                    device.name,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildScanButton() {
    return Center(
      child: GestureDetector(
        onTap: widget.onScan,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryColor.withValues(alpha: 0.4),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.search_rounded, color: Colors.white, size: 20),
              SizedBox(width: 8),
              Text(
                'Scan for Devices',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Data class for radar device
class RadarDevice {
  final String id;
  final String name;
  final String icon;
  final bool isConnected;
  final String? ipAddress;

  RadarDevice({
    required this.id,
    required this.name,
    required this.icon,
    this.isConnected = false,
    this.ipAddress,
  });
}
