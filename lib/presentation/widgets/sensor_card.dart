import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../domain/entities/sensor_data.dart';
import '../screens/sensor_detail_screen.dart';

class SensorCard extends StatelessWidget {
  final SensorData data;

  const SensorCard({super.key, required this.data});

  IconData _getIcon() {
    switch (data.type) {
      case SensorType.temperature:
        return Icons.thermostat_rounded;
      case SensorType.humidity:
        return Icons.water_drop_rounded;
      case SensorType.pressure:
        return Icons.compress_rounded;
      case SensorType.motion:
        return Icons.radar_rounded;
    }
  }

  String _getTitle() {
    switch (data.type) {
      case SensorType.temperature:
        return 'Temperature';
      case SensorType.humidity:
        return 'Humidity';
      case SensorType.pressure:
        return 'Pressure';
      case SensorType.motion:
        return 'Motion';
    }
  }

  Color _getStatusColor() {
    switch (data.status) {
      case SensorStatus.normal:
        return AppColors.healthyGreen;
      case SensorStatus.warning:
        return AppColors.warningOrange;
      case SensorStatus.critical:
        return AppColors.criticalRed;
    }
  }
  
  String _getDisplayValue() {
    if (data.type == SensorType.motion) {
      return data.value > 0 ? "Detected" : "None";
    }
    // E.g., 24
    if (data.value == data.value.toInt()) {
      return data.value.toInt().toString();
    }
    return data.value.toStringAsFixed(1);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => SensorDetailScreen(sensorType: data.type),
          ),
        );
      },
      child: Container(
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
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).dividerColor.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _getIcon(),
                    color: AppColors.accentCyan,
                    size: 24,
                  ),
                ),
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _getStatusColor(),
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),
            const Spacer(),
            Text(
              _getTitle(),
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 4),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  _getDisplayValue(),
                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                    fontSize: 28,
                  ),
                ),
                if (data.type != SensorType.motion) ...[
                  const SizedBox(width: 4),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      data.unit,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ]
              ],
            ),
            const SizedBox(height: 16),
            // Mini sparkline representation (using simple colored bars)
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(6, (index) {
                // Determine heights based on history. If motion, use fixed heights for none.
                double height = 4;
                Color color = AppColors.systemGray.withOpacity(0.3);
                
                if (data.history.length >= 6) {
                  // Normalize last 6 points
                  final relevantHistory = data.history.sublist(data.history.length - 6);
                  if (data.type == SensorType.motion) {
                     height = relevantHistory[index] > 0 ? 16 : 4;
                     color = relevantHistory[index] > 0 ? AppColors.accentCyan : AppColors.systemGray.withOpacity(0.3);
                  } else {
                     final minVal = relevantHistory.reduce((a, b) => a < b ? a : b);
                     final maxVal = relevantHistory.reduce((a, b) => a > b ? a : b);
                     final range = (maxVal - minVal) == 0 ? 1 : (maxVal - minVal);
                     final normalized = (relevantHistory[index] - minVal) / range;
                     height = 6 + (normalized * 12); // Range from 6 to 18
                     color = AppColors.accentCyan.withOpacity(0.5 + (0.5 * normalized));
                  }
                }
                
                return Container(
                  width: 6,
                  height: height,
                  margin: const EdgeInsets.only(right: 4),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(2),
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}
