import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../domain/entities/alert_entity.dart';
import '../providers/providers.dart';

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
            icon: const Icon(Icons.tune_rounded),
            onPressed: () {},
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
                _buildCriticalBanner(context, criticalCount),
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
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Text(
                      'No active alerts',
                      style: Theme.of(context).textTheme.bodyMedium,
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

  Widget _buildCriticalBanner(BuildContext context, int count) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
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
                child: const Icon(Icons.error_outline_rounded, color: Colors.white, size: 28),
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
                    Text(
                      'Immediate action required for Kitchen sensor',
                      style: Theme.of(context).textTheme.bodyMedium,
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
              onPressed: () {},
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
    
    switch (alert.severity) {
      case AlertSeverity.critical:
        severityColor = AppColors.criticalRed;
        badgeText = 'CRITICAL';
        icon = Icons.thermostat_rounded;
        iconBgColor = AppColors.criticalRed.withOpacity(0.2);
        break;
      case AlertSeverity.warning:
        severityColor = AppColors.warningOrange;
        badgeText = 'WARNING';
        icon = Icons.water_drop_rounded;
        iconBgColor = AppColors.warningOrange.withOpacity(0.2);
        break;
      case AlertSeverity.system:
        severityColor = AppColors.systemGray;
        badgeText = 'SYSTEM';
        icon = Icons.battery_alert_rounded;
        iconBgColor = AppColors.systemGray.withOpacity(0.2);
        break;
    }

    final timeFormat = DateFormat('hh:mm a');

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
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
                    onPressed: () => ref.read(alertProvider.notifier).resolveAlert(alert.id),
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
                      backgroundColor: AppColors.cardBorder,
                      foregroundColor: Colors.white,
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
                    backgroundColor: AppColors.cardBorder,
                    foregroundColor: Colors.white,
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
}
