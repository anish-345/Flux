import 'package:flutter/material.dart';
import 'package:flux/models/device.dart';

class ConnectionIndicator extends StatelessWidget {
  final ConnectionType type;
  final bool isConnected;

  const ConnectionIndicator({
    super.key,
    required this.type,
    required this.isConnected,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message:
          '${type.displayName}: ${isConnected ? "Connected" : "Disconnected"}',
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isConnected
              ? Colors.green.withValues(alpha: 0.2)
              : Colors.grey.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(type.icon, style: const TextStyle(fontSize: 20)),
            const SizedBox(width: 4),
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: isConnected ? Colors.green : Colors.grey,
                shape: BoxShape.circle,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
