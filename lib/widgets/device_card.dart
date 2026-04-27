import 'package:flutter/material.dart';
import 'package:flux/models/device.dart';
import 'package:flux/config/app_theme.dart';
import 'package:flux/widgets/app_card.dart';

class DeviceCard extends StatelessWidget {
  final Device device;
  final VoidCallback onConnect;
  final VoidCallback onDisconnect;
  final VoidCallback onTrust;
  final VoidCallback onUntrust;
  final VoidCallback? onSendFiles;

  const DeviceCard({
    super.key,
    required this.device,
    required this.onConnect,
    required this.onDisconnect,
    required this.onTrust,
    required this.onUntrust,
    this.onSendFiles,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with device info
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceVariant,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  device.type.icon,
                  style: const TextStyle(fontSize: 28),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      device.name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      device.type.displayName,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppTheme.textTertiary,
                          ),
                    ),
                  ],
                ),
              ),
              StatusBadge(
                label: device.isConnected ? 'Connected' : 'Available',
                isActive: device.isConnected,
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Device Details
          _buildDetailRow(
            context,
            Icons.link_rounded,
            'Connection',
            device.connectionType.displayName,
          ),
          const SizedBox(height: 12),
          _buildDetailRow(
            context,
            Icons.router_outlined,
            'IP Address',
            device.ipAddress,
          ),
          if (device.osVersion != null) ...[
            const SizedBox(height: 12),
            _buildDetailRow(
              context,
              Icons.computer_outlined,
              'Operating System',
              device.osVersion!,
            ),
          ],

          // Trust Status
          if (device.isTrusted) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.verified_rounded,
                    size: 18,
                    color: AppTheme.primaryColor,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Trusted Device',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.primaryColor,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 20),
          const Divider(height: 1),
          const SizedBox(height: 20),

          // Action Buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: device.isConnected ? onDisconnect : onConnect,
                  icon: Icon(
                    device.isConnected
                        ? Icons.link_off_rounded
                        : Icons.link_rounded,
                    size: 20,
                  ),
                  label: Text(device.isConnected ? 'Disconnect' : 'Connect'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: device.isTrusted ? onUntrust : onTrust,
                  icon: Icon(
                    device.isTrusted
                        ? Icons.verified_user_rounded
                        : Icons.person_add_outlined,
                    size: 20,
                  ),
                  label: Text(device.isTrusted ? 'Untrust' : 'Trust'),
                ),
              ),
            ],
          ),

          // Send Files button — only when connected
          if (device.isConnected && onSendFiles != null) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: onSendFiles,
                icon: const Icon(Icons.upload_rounded, size: 20),
                label: const Text('Send Files'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDetailRow(
    BuildContext context,
    IconData icon,
    String label,
    String value,
  ) {
    return Row(
      children: [
        Icon(
          icon,
          size: 18,
          color: AppTheme.textTertiary,
        ),
        const SizedBox(width: 12),
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.textSecondary,
              ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );
  }
}
