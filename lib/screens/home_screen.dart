import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flux/screens/unified_transfer_screen.dart';
import 'package:flux/screens/settings_screen.dart';
import 'package:flux/screens/transfer_history_screen.dart';
import 'package:flux/screens/web_sharing_screen.dart';
import 'package:flux/providers/connection_provider.dart';
import 'package:flux/providers/file_transfer_provider.dart';
import 'package:flux/providers/settings_provider.dart';
import 'package:flux/models/connection_state.dart';
import 'package:flux/services/network_manager_service.dart';
import 'package:flux/services/hotspot_service.dart';
import 'package:flux/config/app_theme.dart';
import 'package:flux/widgets/app_card.dart';

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
      backgroundColor: AppTheme.backgroundColor,
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          _HomeView(
            onNavigateToHistory: () => setState(() => _selectedIndex = 1),
          ),
          const TransferHistoryScreen(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        backgroundColor: AppTheme.surfaceColor,
        elevation: 0,
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) => setState(() => _selectedIndex = index),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.history_outlined),
            selectedIcon: Icon(Icons.history_rounded),
            label: 'History',
          ),
        ],
      ),
    );
  }
}

class _HomeView extends ConsumerWidget {
  final VoidCallback onNavigateToHistory;

  const _HomeView({required this.onNavigateToHistory});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connectionState = ref.watch(connectionProvider);
    final settings = ref.watch(settingsProvider);
    final historyCount = ref.watch(transferHistoryProvider).whenData((h) => h.length).value ?? 0;
    final activeCount = ref.watch(activeTransfersProvider).whenData((a) => a.length).value ?? 0;
    final isDesktop = Platform.isWindows || Platform.isLinux || Platform.isMacOS;

    return CustomScrollView(
      slivers: [
        // Clean App Bar
        SliverAppBar(
          floating: true,
          pinned: true,
          elevation: 0,
          backgroundColor: AppTheme.backgroundColor,
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppTheme.primaryColor, AppTheme.accentColor],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.swap_horiz_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Flux',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textPrimary,
                      letterSpacing: -0.5,
                    ),
              ),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.settings_outlined, color: AppTheme.textSecondary),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              ),
            ),
            const SizedBox(width: 8),
          ],
        ),

        // Content
        SliverPadding(
          padding: EdgeInsets.all(isDesktop ? 32 : 20),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              // Welcome Section
              _buildWelcomeSection(context, settings.deviceName),
              const SizedBox(height: 28),

              // Network Status Banner
              _NetworkStatusBanner(),
              const SizedBox(height: 24),

              // Big Send/Receive Buttons - ShareMe Style
              _buildMainActions(context, isDesktop),
              const SizedBox(height: 32),

              // Secondary Actions Row
              _buildSecondaryActions(context, onNavigateToHistory),
              const SizedBox(height: 32),

              // Stats Row
              _buildStatsRow(context, activeCount, historyCount),
              const SizedBox(height: 32),

              // Connection Status
              SectionHeader(title: 'Connection Status'),
              const SizedBox(height: 12),
              _buildConnectionStatus(context, connectionState),
              const SizedBox(height: 24),
            ]),
          ),
        ),
      ],
    );
  }

  Widget _buildWelcomeSection(BuildContext context, String deviceName) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Hello there!',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: AppTheme.textSecondary,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          deviceName,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
              ),
        ),
      ],
    );
  }

  Widget _buildMainActions(BuildContext context, bool isDesktop) {
    final size = isDesktop ? 200.0 : 160.0;
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Host Transfer Button (creates hotspot if needed)
        _ActionButton(
          size: size,
          icon: Icons.wifi_tethering_rounded,
          label: 'Host',
          gradient: const [Color(0xFF6366F1), Color(0xFF0EA5E9)],
          onTap: () {
            HapticFeedback.mediumImpact();
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const UnifiedTransferScreen(initiallyHosting: true),
              ),
            );
          },
        ),
        SizedBox(width: isDesktop ? 40 : 24),
        // Join Transfer Button (scans for host)
        _ActionButton(
          size: size,
          icon: Icons.wifi_find_rounded,
          label: 'Join',
          gradient: const [Color(0xFF10B981), Color(0xFF34D399)],
          onTap: () {
            HapticFeedback.mediumImpact();
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const UnifiedTransferScreen(initiallyHosting: false),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildSecondaryActions(BuildContext context, VoidCallback onHistory) {
    return Row(
      children: [
        Expanded(
          child: _SecondaryActionButton(
            icon: Icons.language_rounded,
            label: 'Web Share',
            color: AppTheme.warningColor,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const WebSharingScreen()),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _SecondaryActionButton(
            icon: Icons.history_rounded,
            label: 'History',
            color: AppTheme.accentColor,
            onTap: onHistory,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _SecondaryActionButton(
            icon: Icons.settings_outlined,
            label: 'Settings',
            color: AppTheme.textSecondary,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatsRow(BuildContext context, int active, int total) {
    return Row(
      children: [
        Expanded(
          child: StatCard(
            label: 'Active',
            value: active.toString(),
            icon: Icons.sync_rounded,
            color: AppTheme.accentColor,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: StatCard(
            label: 'Completed',
            value: total.toString(),
            icon: Icons.check_circle_outline_rounded,
            color: AppTheme.successColor,
          ),
        ),
      ],
    );
  }

  Widget _buildConnectionStatus(BuildContext context, AppConnectionState state) {
    return AppCard(
      elevated: false,
      backgroundColor: AppTheme.surfaceVariant,
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          InfoRow(
            icon: Icons.wifi_rounded,
            label: 'WiFi',
            value: state.isWiFiEnabled ? (state.currentWiFiSSID ?? 'Connected') : 'Not Connected',
            active: state.isWiFiEnabled,
          ),
          if (state.isWiFiEnabled && state.deviceIPAddress != null) ...[
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Divider(height: 1),
            ),
            InfoRow(
              icon: Icons.router_outlined,
              label: 'IP Address',
              value: state.deviceIPAddress!,
              active: true,
            ),
          ],
        ],
      ),
    );
  }
}

/// Big circular action button - ShareMe style
class _BigActionButton extends StatefulWidget {
  final double size;
  final double iconSize;
  final String label;
  final IconData icon;
  final List<Color> gradient;
  final VoidCallback onTap;

  const _BigActionButton({
    required this.size,
    required this.iconSize,
    required this.label,
    required this.icon,
    required this.gradient,
    required this.onTap,
  });

  @override
  State<_BigActionButton> createState() => _BigActionButtonState();
}

class _BigActionButtonState extends State<_BigActionButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        HapticFeedback.lightImpact();
        widget.onTap();
      },
      onTapCancel: () => _controller.reverse(),
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) => Transform.scale(
          scale: _scaleAnimation.value,
          child: child,
        ),
        child: Column(
          children: [
            // Gradient circle button
            Container(
              width: widget.size,
              height: widget.size,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: widget.gradient,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(widget.size / 2),
                boxShadow: [
                  BoxShadow(
                    color: widget.gradient[0].withValues(alpha: 0.4),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Icon(
                widget.icon,
                size: widget.iconSize,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              widget.label,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Large circular action button for Send/Receive
class _ActionButton extends StatelessWidget {
  final double size;
  final IconData icon;
  final String label;
  final List<Color> gradient;
  final VoidCallback onTap;

  const _ActionButton({
    required this.size,
    required this.icon,
    required this.label,
    required this.gradient,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: gradient,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(size * 0.35),
              boxShadow: [
                BoxShadow(
                  color: gradient[0].withOpacity(0.4),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Icon(
              icon,
              size: size * 0.4,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          label,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
              ),
        ),
      ],
    );
  }
}

/// Secondary action button for row
class _SecondaryActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _SecondaryActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: AppTheme.surfaceColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.borderColor.withValues(alpha: 0.5)),
          boxShadow: [AppTheme.shadowSm],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(height: 10),
            Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Network status banner showing offline mode and hotspot status
class _NetworkStatusBanner extends StatefulWidget {
  @override
  State<_NetworkStatusBanner> createState() => _NetworkStatusBannerState();
}

class _NetworkStatusBannerState extends State<_NetworkStatusBanner> {
  final NetworkManagerService _networkManager = NetworkManagerService();
  final HotspotService _hotspotService = HotspotService();
  NetworkState _networkState = NetworkState.checking;
  bool _isHotspotActive = false;

  @override
  void initState() {
    super.initState();
    _checkNetworkStatus();
    
    // Listen to network changes
    _networkManager.stateStream.listen((state) {
      if (mounted) {
        setState(() => _networkState = state);
      }
    });
  }

  Future<void> _checkNetworkStatus() async {
    final state = _networkManager.currentState;
    final hotspotActive = await _hotspotService.isHotspotEnabled();
    
    if (mounted) {
      setState(() {
        _networkState = state;
        _isHotspotActive = hotspotActive;
      });
    }
  }

  Future<void> _enableHotspot() async {
    final result = await _hotspotService.startHotspot();
    if (result && mounted) {
      setState(() => _isHotspotActive = true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Hotspot enabled. Other devices can now connect.'),
          backgroundColor: AppTheme.successColor,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Don't show banner if connected to WiFi
    if (_networkState == NetworkState.wifiConnected) {
      return const SizedBox.shrink();
    }

    if (_networkState == NetworkState.checking) {
      return AppCard(
        elevated: false,
        backgroundColor: AppTheme.surfaceVariant,
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppTheme.warningColor,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Checking network...',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
            ),
          ],
        ),
      );
    }

    if (_networkState == NetworkState.noConnection) {
      return AppCard(
        elevated: false,
        backgroundColor: AppTheme.errorColor.withValues(alpha: 0.08),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.wifi_off_rounded,
                  color: AppTheme.errorColor,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'No network connection',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppTheme.errorColor,
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Connect to WiFi or enable hotspot to share files',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
            ),
            if (Platform.isAndroid) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _enableHotspot,
                  icon: const Icon(Icons.wifi_tethering_rounded, size: 18),
                  label: const Text('Enable Hotspot'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppTheme.errorColor,
                  ),
                ),
              ),
            ],
          ],
        ),
      );
    }

    if (_networkState == NetworkState.hotspotActive || _isHotspotActive) {
      final ssid = _hotspotService.currentSSID ?? 'Flux Hotspot';
      final password = _hotspotService.getHotspotPassword() ?? 'flux-password';

      return AppCard(
        elevated: false,
        backgroundColor: const Color(0xFF0EA5E9).withValues(alpha: 0.08),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Color(0xFF0EA5E9),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.wifi_tethering_rounded,
                  color: const Color(0xFF0EA5E9),
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Hotspot Active',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF0EA5E9),
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.borderColor),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'SSID: ',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppTheme.textTertiary,
                            ),
                      ),
                      Text(
                        ssid,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        'Password: ',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppTheme.textTertiary,
                            ),
                      ),
                      Text(
                        password,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Other devices can connect to this hotspot to transfer files',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.textTertiary,
                  ),
            ),
          ],
        ),
      );
    }

    return const SizedBox.shrink();
  }
}

