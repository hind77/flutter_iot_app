import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../providers/providers.dart';
import 'dashboard_screen.dart';
import 'alert_center_screen.dart';
import 'devices_screen.dart';
import 'settings_screen.dart';
import '../widgets/voice_command_fab.dart';

class MainScreen extends ConsumerStatefulWidget {
  const MainScreen({super.key});

  @override
  ConsumerState<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends ConsumerState<MainScreen> {
  @override
  void initState() {
    super.initState();
    // Try to connect to MQTT broker on startup
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(mqttManagerProvider).connectDefault();
    });
  }

  int _currentIndex = 0;

  final List<Widget> _screens = [
    const DashboardScreen(),
    const AlertCenterScreen(),
    const DevicesScreen(),
    const SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    // Watch alerts to show badge
    final alertState = ref.watch(alertProvider);
    final activeAlertsCount = alertState.value?.where((a) => !a.isResolved).length ?? 0;

    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8,
        color: AppColors.background,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(0, Icons.dashboard_rounded, 'DASHBOARD'),
            _buildNavItem(1, Icons.notifications_rounded, 'ALERTS', badge: activeAlertsCount),
            const SizedBox(width: 40), // Space for FAB
            _buildNavItem(2, Icons.router_rounded, 'DEVICES'),
            _buildNavItem(3, Icons.settings_rounded, 'SETTINGS'),
          ],
        ),
      ),
      floatingActionButton: const VoiceCommandFab(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label, {int badge = 0}) {
    final isSelected = _currentIndex == index;
    return InkWell(
      onTap: () => setState(() => _currentIndex = index),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Icon(
                icon,
                color: isSelected ? AppColors.accentCyan : AppColors.systemGray,
              ),
              if (badge > 0)
                Positioned(
                  right: -4,
                  top: -4,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: AppColors.criticalRed,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected ? AppColors.accentCyan : AppColors.systemGray,
            ),
          ),
        ],
      ),
    );
  }
}
