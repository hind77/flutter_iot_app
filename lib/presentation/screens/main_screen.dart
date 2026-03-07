import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../providers/providers.dart';
import 'dashboard_screen.dart';
import 'alert_center_screen.dart';
import 'devices_screen.dart';
import 'settings_screen.dart';

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
      bottomNavigationBar: Theme(
        data: Theme.of(context).copyWith(
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          items: [
            const BottomNavigationBarItem(
              icon: Icon(Icons.dashboard_rounded),
              label: 'DASHBOARD',
            ),
            BottomNavigationBarItem(
              icon: Stack(
                clipBehavior: Clip.none,
                children: [
                  const Icon(Icons.notifications_rounded),
                  if (activeAlertsCount > 0)
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
              label: 'ALERTS',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.router_rounded),
              label: 'DEVICES',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.settings_rounded),
              label: 'SETTINGS',
            ),
          ],
        ),
      ),
    );
  }
}
