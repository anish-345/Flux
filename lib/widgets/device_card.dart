import 'package:flutter/material.dart';
import 'package:flux/models/device.dart';

class DeviceCard extends StatelessWidget {
  final Device device;
  final VoidCallback onConnect;
  final VoidCallback onDisconnect;
  final VoidCallback onTrust;
  final VoidCallback onUntrust;

  const DeviceCard({
    super.key,
    required this.device,
    required this.onConnect,
    required this.onDisconnect,
    required this.onTrust,
    required this.onUntrust,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with device info
            Row(
              children: [
                Text(device.type.icon, style: const TextStyle(fontSize: 32)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        device.name,
                        style: Theme.of(context).textTheme.titleMedium,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        device.type.displayName,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                // Connection Status Badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: device.isConnected
                        ? Colors.green.withOpacity(0.2)
                        : Colors.grey.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    device.isConnected ? 'Connected' : 'Disconnected',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: device.isConnected ? Colors.green : Colors.grey,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Device Details
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildDetailRow(
                        context,
                        'Connection:',
                        device.connectionType.displayName,
                      ),
                      _buildDetailRow(context, 'IP Address:', device.ipAddress),
                      if (device.osVersion != null)
                        _buildDetailRow(context, 'OS:', device.osVersion!),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Trust Status
            if (device.isTrusted)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.verified, size: 16, color: Colors.blue),
                      const SizedBox(width: 6),
                      Text(
                        'Trusted Device',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.blue,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: device.isConnected ? onDisconnect : onConnect,
                    icon: Icon(
                      device.isConnected ? Icons.link_off : Icons.link,
                    ),
                    label: Text(device.isConnected ? 'Disconnect' : 'Connect'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: device.isTrusted ? onUntrust : onTrust,
                    icon: Icon(
                      device.isTrusted ? Icons.verified_user : Icons.person_add,
                    ),
                    label: Text(device.isTrusted ? 'Untrust' : 'Trust'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodySmall,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
