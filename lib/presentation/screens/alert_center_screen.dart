import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../domain/entities/alert_entity.dart';
import '../../domain/entities/sensor_data.dart';
import '../providers/providers.dart';
import 'sensor_detail_screen.dart';

class AlertCenterScreen extends ConsumerWidget {
  const AlertCenterScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final alertState = ref.watch(alertProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Alert Center'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep_rounded, color: AppColors.criticalRed),
            onPressed: () => ref.read(alertProvider.notifier).clearAllAlerts(),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: alertState.when(
        data: (alerts) {
          final activeAlerts = alerts.where((a) => !a.isResolved).toList();
          final criticalCount = activeAlerts.where((a) => a.severity == AlertSeverity.critical).length;
          final newCount = activeAlerts.length;

          return ListView(
            padding: const EdgeInsets.all(24),
            children: [
              if (criticalCount > 0)
                _buildCriticalBanner(context, activeAlerts),
              if (criticalCount > 0)
                const SizedBox(height: 32),
              
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Recent Alerts',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  if (newCount > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.systemGray.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        '$newCount New',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              
              ...activeAlerts.map((alert) => _buildAlertItem(context, alert, ref)).toList(),
              
              if (activeAlerts.isEmpty)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32.0),
                    child: Text(
                      'No active alerts',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  ),
                ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.accentCyan)),
        error: (error, _) => Center(child: Text('Error loading alerts: $error')),
      ),
    );
  }

  Widget _buildCriticalBanner(BuildContext context, List<AlertEntity> activeAlerts) {
    final criticalAlerts = activeAlerts.where((a) => a.severity == AlertSeverity.critical).toList();
    final count = criticalAlerts.length;
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.criticalRed.withOpacity(0.5)),
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: const BoxDecoration(
                  color: AppColors.criticalRed,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.error_outline_rounded, color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.white, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$count Critical Alert Active',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: AppColors.criticalRed,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Immediate action required for monitored sensors',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                final lastSensor = criticalAlerts.first.sensorType ?? SensorType.temperature;
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SensorDetailScreen(sensorType: lastSensor),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.criticalRed,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: const Text('View Details', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAlertItem(BuildContext context, AlertEntity alert, WidgetRef ref) {
    Color severityColor;
    String badgeText;
    IconData icon;
    Color iconBgColor;
    
    if (alert.sensorType != null) {
      switch (alert.sensorType!) {
        case SensorType.temperature:
          icon = Icons.thermostat_rounded;
          iconBgColor = AppColors.criticalRed.withOpacity(0.2);
          break;
        case SensorType.humidity:
          icon = Icons.water_drop_rounded;
          iconBgColor = AppColors.warningOrange.withOpacity(0.2);
          break;
        case SensorType.pressure:
          icon = Icons.compress_rounded;
          iconBgColor = AppColors.accentCyan.withOpacity(0.2);
          break;
        case SensorType.motion:
          icon = Icons.motion_photos_on_rounded;
          iconBgColor = AppColors.accentPurple.withOpacity(0.2);
          break;
      }
    } else {
      icon = Icons.notifications_active_rounded;
      iconBgColor = AppColors.systemGray.withOpacity(0.2);
    }
    
    switch (alert.severity) {
      case AlertSeverity.critical:
        severityColor = AppColors.criticalRed;
        badgeText = 'CRITICAL';
        break;
      case AlertSeverity.warning:
        severityColor = AppColors.warningOrange;
        badgeText = 'WARNING';
        break;
      case AlertSeverity.system:
        severityColor = AppColors.systemGray;
        badgeText = 'SYSTEM';
        break;
    }

    final timeFormat = DateFormat('hh:mm a');

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: iconBgColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: severityColor, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: severityColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            badgeText,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: severityColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 10,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          timeFormat.format(alert.timestamp),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      alert.title,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              if (alert.severity == AlertSeverity.critical)
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _showResolutionDialog(context, ref, alert),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accentPurple,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 0,
                    ),
                    child: const Text('Solve Now', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                )
              else if (alert.severity == AlertSeverity.warning)
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => ref.read(alertProvider.notifier).resolveAlert(alert.id),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).dividerColor,
                      foregroundColor: Theme.of(context).textTheme.bodyLarge?.color,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 0,
                    ),
                    child: const Text('Check Sensor', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              
              if (alert.severity != AlertSeverity.system)
                const SizedBox(width: 12),
                
              Expanded(
                child: ElevatedButton(
                  onPressed: () => ref.read(alertProvider.notifier).dismissAlert(alert.id),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).dividerColor,
                    foregroundColor: Theme.of(context).textTheme.bodyLarge?.color,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 0,
                  ),
                  child: const Text('Dismiss', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showResolutionDialog(BuildContext context, WidgetRef ref, AlertEntity alert) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).cardTheme.color,
        title: Text('Resolve ${alert.title}', style: TextStyle(color: Theme.of(context).textTheme.titleLarge?.color)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(alert.description, style: const TextStyle(color: AppColors.textSecondary)),
            const SizedBox(height: 24),
            Text('Suggested Action:', style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).textTheme.titleMedium?.color)),
            const SizedBox(height: 12),
            if (alert.sensorType == SensorType.temperature) 
              _buildActionTile(context, ref, 'Turn on cooling system', Icons.ac_unit, 'ac_unit'),
            if (alert.sensorType == SensorType.humidity)
              _buildActionTile(context, ref, 'Activate Dehumidifier', Icons.air, 'kitchen_fan'),
            if (alert.sensorType == SensorType.motion)
              _buildActionTile(context, ref, 'Activate Security Lights', Icons.lightbulb, 'living_room_light'),
            if (alert.sensorType == SensorType.pressure)
              _buildActionTile(context, ref, 'Open Ventilation Damper', Icons.wind_power, 'pressure_valve'),
            
            // Helpful text if it's an old alert or system alert
            if (alert.sensorType == null)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8.0),
                child: Text('• Check sensor battery\n• Verify MQTT broker connection\n• Recalibrate sensor node', 
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () {
              ref.read(alertProvider.notifier).resolveAlert(alert.id);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.healthyGreen),
            child: const Text('Mark as Resolved'),
          ),
        ],
      ),
    );
  }

  Widget _buildActionTile(BuildContext context, WidgetRef ref, String label, IconData icon, String actuatorId) {
    final status = ref.watch(actuatorProvider)[actuatorId] ?? false;
    return ListTile(
      leading: Icon(icon, color: AppColors.accentCyan),
      title: Text(label, style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color, fontSize: 14)),
      trailing: Switch(
        value: status,
        onChanged: (val) => ref.read(actuatorProvider.notifier).toggle(actuatorId),
      ),
      contentPadding: EdgeInsets.zero,
    );
  }
}
