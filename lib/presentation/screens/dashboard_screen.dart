import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../domain/entities/sensor_data.dart';
import '../providers/providers.dart';
import '../providers/weather_provider.dart';
import '../widgets/sensor_card.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sensorData = ref.watch(liveSensorProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const CircleAvatar(
                      radius: 20,
                      backgroundColor: AppColors.accentCyan,
                      child: Icon(Icons.person, color: isDark ? AppColors.background : Colors.white),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'WELCOME BACK,',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                letterSpacing: 1.2,
                              ),
                            ),
                            const SizedBox(width: 8),
                            _buildConnectionStatus(ref),
                          ],
                        ),
                        Text(
                          'hind boukhairat',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ],
                    ),
                  ],
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.logout_rounded, color: AppColors.criticalRed),
                      tooltip: 'Logout (Deconnexion)',
                      onPressed: () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            backgroundColor: Theme.of(context).cardTheme.color,
                            title: const Text('Logout'),
                            content: const Text('Are you sure you want to disconnect from the application?'),
                            actions: [
                              TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                              TextButton(
                                onPressed: () => Navigator.pop(context, true), 
                                child: const Text('Logout', style: TextStyle(color: AppColors.criticalRed))
                              ),
                            ],
                          ),
                        );
                        
                        if (confirm == true) {
                          ref.read(authProvider.notifier).logout();
                        }
                      },
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.cardBackground,
                        shape: BoxShape.circle,
                        border: Border.all(color: Theme.of(context).dividerColor),
                      ),
                      child: Icon(
                        Icons.notifications_none_rounded, 
                        color: Theme.of(context).iconTheme.color,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 32),
            
            // System Status Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).cardTheme.color,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.accentCyan.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'All Systems Normal',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.accentCyan.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppColors.accentCyan),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: AppColors.accentCyan,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'HEALTHY',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppColors.accentCyan,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '4 active devices online',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      _buildStatusMiniCard(context, Icons.wifi, 'Network: 98%'),
                      const SizedBox(width: 16),
                      _buildStatusMiniCard(context, Icons.router_rounded, 'Nodes: OK'),
                    ],
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 32),

            // Contextual Weather Overlay
            ref.watch(weatherProvider).when(
              data: (weather) {
                final indoorTemp = sensorData[SensorType.temperature]?.value ?? 22.0;
                final difference = weather.temperature - indoorTemp;
                
                String message;
                if (difference > 5) {
                  message = "It's ${weather.temperature}°C outside, but your Kitchen is ${indoorTemp}°C. Good job keeping it cool!";
                } else if (indoorTemp > weather.temperature) {
                  message = "It's cooler outside (${weather.temperature}°C). You might want to open a window!";
                } else {
                  message = "Outside temp is ${weather.temperature}°C. Weather is matching indoors.";
                }

                return Container(
                  margin: const EdgeInsets.only(bottom: 32),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.accentCyan.withOpacity(0.2),
                        Theme.of(context).cardTheme.color!,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Theme.of(context).dividerColor),
                  ),
                  child: Row(
                    children: [
                      Text(weather.icon, style: const TextStyle(fontSize: 40)),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Weather Context',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                color: AppColors.accentCyan,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              message,
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => const SizedBox.shrink(),
            ),
            
            // Live Sensors Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Live Sensors',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                Text(
                  'See all',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.accentCyan,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Sensors Grid
            GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: 0.85,
              children: [
                SensorCard(data: sensorData[SensorType.temperature]!),
                SensorCard(data: sensorData[SensorType.humidity]!),
                SensorCard(data: sensorData[SensorType.pressure]!),
                SensorCard(data: sensorData[SensorType.motion]!),
              ],
            ),
            
            const SizedBox(height: 32),
            
            // Quick Actions / Actuators
            Text(
              'Quick Actions',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 120,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  _buildActuatorCard(ref, 'living_room_light', 'Light', Icons.lightbulb_outline),
                  const SizedBox(width: 16),
                  _buildActuatorCard(ref, 'kitchen_fan', 'Fan', Icons.air),
                  const SizedBox(width: 16),
                  _buildActuatorCard(ref, 'ac_unit', 'AC Unit', Icons.ac_unit),
                ],
              ),
            ),

            const SizedBox(height: 32),
            
            // Recent Activity
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Recent Activity',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const Icon(Icons.more_horiz, color: AppColors.textSecondary),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              decoration: BoxDecoration(
                color: Theme.of(context).cardTheme.color,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Theme.of(context).dividerColor),
              ),
              child: Column(
                children: [
                  _buildActivityItem(
                    context,
                    title: 'Front Door Unlocked',
                    subtitle: '12 mins ago • Alex',
                    color: AppColors.accentCyan,
                  ),
                  Divider(color: Theme.of(context).dividerColor, height: 1),
                  _buildActivityItem(
                    context,
                    title: 'Living Room Light Off',
                    subtitle: '45 mins ago • Automation',
                    color: AppColors.systemGray,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConnectionStatus(WidgetRef ref) {
    final isConnected = ref.watch(mqttConnectionStatusProvider);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: isConnected ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: isConnected ? Colors.green : Colors.red),
      ),
      child: Text(
        isConnected ? 'LIVE' : 'OFFLINE',
        style: TextStyle(
          fontSize: 8,
          fontWeight: FontWeight.bold,
          color: isConnected ? Colors.green : Colors.red,
        ),
      ),
    );
  }

  Widget _buildStatusMiniCard(BuildContext context, IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.accentCyan, size: 16),
          const SizedBox(width: 8),
          Text(text, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }

  Widget _buildActuatorCard(WidgetRef ref, String id, String label, IconData icon) {
    final status = ref.watch(actuatorProvider)[id] ?? false;
    
    return GestureDetector(
      onTap: () => ref.read(actuatorProvider.notifier).toggle(id),
      child: Container(
        width: 100,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: status ? AppColors.accentCyan : Theme.of(context).cardTheme.color,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Theme.of(context).dividerColor),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon, 
              color: status ? AppColors.background : AppColors.textSecondary,
              size: 32,
            ),
            const SizedBox(height: 8),
            Text(
              label, 
              style: TextStyle(
                color: status ? (isDark ? AppColors.background : Colors.white) : Theme.of(context).textTheme.bodySmall?.color,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityItem(BuildContext context, {required String title, required String subtitle, required Color color}) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 4),
                Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: AppColors.textSecondary),
        ],
      ),
    );
  }
}
