import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flux/screens/device_discovery_screen.dart';
import 'package:flux/screens/file_transfer_screen.dart';
import 'package:flux/screens/settings_screen.dart';
import 'package:flux/screens/transfer_history_screen.dart';
import 'package:flux/screens/web_sharing_screen.dart';
import 'package:flux/providers/connection_provider.dart';
import 'package:flux/providers/file_transfer_provider.dart';
import 'package:flux/providers/settings_provider.dart';
import 'package:flux/models/connection_state.dart';
import 'package:flux/config/app_theme.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          _HomeView(
            onNavigateToDiscovery: () => setState(() => _selectedIndex = 1),
            onNavigateToHistory: () => setState(() => _selectedIndex = 2),
          ),
          const DeviceDiscoveryScreen(),
          const TransferHistoryScreen(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) => setState(() => _selectedIndex = index),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.radar_outlined), selectedIcon: Icon(Icons.radar), label: 'Devices'),
          NavigationDestination(icon: Icon(Icons.history_outlined), selectedIcon: Icon(Icons.history), label: 'History'),
        ],
      ),
    );
  }
}

class _HomeView extends ConsumerWidget {
  final VoidCallback onNavigateToDiscovery;
  final VoidCallback onNavigateToHistory;

  const _HomeView({required this.onNavigateToDiscovery, required this.onNavigateToHistory});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connectionState = ref.watch(connectionProvider);
    final settings = ref.watch(settingsProvider);
    final historyCount = ref.watch(transferHistoryProvider).whenData((h) => h.length).value ?? 0;
    final activeCount = ref.watch(activeTransfersProvider).whenData((a) => a.length).value ?? 0;

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          expandedHeight: 200,
          flexibleSpace: FlexibleSpaceBar(
            background: _buildHeader(context, connectionState, settings.deviceName),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.settings_outlined),
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen())),
            ),
          ],
        ),
        SliverPadding(
          padding: const EdgeInsets.all(20),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              _buildStatsRow(context, activeCount, historyCount),
              const SizedBox(height: 32),
              Text('Quick Actions', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              _QuickActionGrid(
                onSend: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FileTransferScreen())),
                onReceive: onNavigateToDiscovery,
                onWebShare: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const WebSharingScreen())),
                onHistory: onNavigateToHistory,
              ),
              const SizedBox(height: 32),
              _buildConnectionStatus(context, connectionState),
            ]),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(BuildContext context, AppConnectionState state, String deviceName) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.primaryColor, AppTheme.secondaryColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Flux Share', style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(deviceName, style: const TextStyle(color: Colors.white70, fontSize: 16)),
              const SizedBox(height: 20),
              Row(
                children: [
                  _StatChip(icon: Icons.wifi, label: state.isWiFiEnabled ? 'WiFi' : 'No WiFi'),
                  const SizedBox(width: 8),
                  _StatChip(icon: Icons.bluetooth, label: state.isBluetoothEnabled ? 'BT On' : 'BT Off'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatsRow(BuildContext context, int active, int total) {
    return Row(
      children: [
        Expanded(child: _buildStatCard(context, 'Active', active.toString(), Colors.blue)),
        const SizedBox(width: 16),
        Expanded(child: _buildStatCard(context, 'Total', total.toString(), Colors.purple)),
      ],
    );
  }

  Widget _buildStatCard(BuildContext context, String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text(value, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildConnectionStatus(BuildContext context, AppConnectionState state) {
    return Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _StatusItem(icon: Icons.wifi, label: 'WiFi Network', value: state.isWiFiEnabled ? (state.currentWiFiSSID ?? 'Connected') : 'Not Connected', active: state.isWiFiEnabled),
            const Divider(height: 24),
            _StatusItem(icon: Icons.link, label: 'Local IP', value: state.deviceIPAddress ?? 'Unknown', active: state.isWiFiEnabled),
          ],
        ),
      ),
    );
  }
}

class _QuickActionGrid extends StatelessWidget {
  final VoidCallback onSend;
  final VoidCallback onReceive;
  final VoidCallback onWebShare;
  final VoidCallback onHistory;

  const _QuickActionGrid({required this.onSend, required this.onReceive, required this.onWebShare, required this.onHistory});

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      childAspectRatio: 1.1,
      children: [
        _ActionCard(title: 'Send', subtitle: 'Share files', icon: Icons.upload_rounded, color: Colors.blue, onTap: onSend),
        _ActionCard(title: 'Receive', subtitle: 'Get files', icon: Icons.download_rounded, color: Colors.green, onTap: onReceive),
        _ActionCard(title: 'Web Share', subtitle: 'Any Browser', icon: Icons.language_rounded, color: Colors.orange, onTap: onWebShare),
        _ActionCard(title: 'History', subtitle: 'Past actions', icon: Icons.history_rounded, color: Colors.purple, onTap: onHistory),
      ],
    );
  }
}

class _ActionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ActionCard({required this.title, required this.subtitle, required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.1)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 12),
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 2),
            Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _StatChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(20)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.white),
          const SizedBox(width: 4),
          Text(label, style: const TextStyle(color: Colors.white, fontSize: 12)),
        ],
      ),
    );
  }
}

class _StatusItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool active;

  const _StatusItem({required this.icon, required this.label, required this.value, required this.active});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: active ? AppTheme.primaryColor : Colors.grey, size: 20),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: Theme.of(context).textTheme.bodySmall),
            Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
          ],
        ),
      ],
    );
  }
}
