import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../core/theme/app_colors.dart';
import '../../domain/entities/sensor_data.dart';
import '../providers/providers.dart';

class SensorDetailScreen extends ConsumerStatefulWidget {
  final SensorType sensorType;

  const SensorDetailScreen({super.key, required this.sensorType});

  @override
  ConsumerState<SensorDetailScreen> createState() => _SensorDetailScreenState();
}

class _SensorDetailScreenState extends ConsumerState<SensorDetailScreen> {
  double _maxLimit = 28.0;
  double _minLimit = 18.0;
  bool _smartNotifications = true;

  String _getTitle() {
    switch (widget.sensorType) {
      case SensorType.temperature:
        return 'Kitchen Temperature';
      case SensorType.humidity:
        return 'Office Humidity';
      case SensorType.pressure:
        return 'Living Room Pressure';
      case SensorType.motion:
        return 'Hallway Motion';
    }
  }

  @override
  Widget build(BuildContext context) {
    final sensorDataMap = ref.watch(liveSensorProvider);
    final data = sensorDataMap[widget.sensorType]!;

    return Scaffold(
      appBar: AppBar(
        title: Text(_getTitle()),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Large Value Display
            Text(
              '${data.value}${data.unit}',
              style: Theme.of(context).textTheme.displayLarge?.copyWith(
                fontSize: 64,
                shadows: [
                  Shadow(
                    color: AppColors.accentCyan.withOpacity(0.5),
                    blurRadius: 20,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            
            // Status Chip
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.healthyGreen.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.healthyGreen.withOpacity(0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.check_circle, color: AppColors.healthyGreen, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    'Status: ${data.status.name.toUpperCase()}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: data.status == SensorStatus.critical ? AppColors.criticalRed : AppColors.healthyGreen,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 32),
            
            // Chart Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.cardBackground,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('24h History', style: Theme.of(context).textTheme.titleLarge),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.systemGray.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text('Real-time', style: Theme.of(context).textTheme.bodySmall),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    height: 150,
                    child: _buildChart(data),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Stats Row
            Row(
              children: [
                Expanded(child: _buildStatCard('Min', '${data.history.isEmpty ? 0 : data.history.reduce((a, b) => a < b ? a : b).toStringAsFixed(1)}${data.unit}')),
                const SizedBox(width: 16),
                Expanded(child: _buildStatCard('Max', '${data.history.isEmpty ? 0 : data.history.reduce((a, b) => a > b ? a : b).toStringAsFixed(1)}${data.unit}')),
                const SizedBox(width: 16),
                Expanded(child: _buildStatCard('Avg', '${data.history.isEmpty ? 0 : (data.history.reduce((a, b) => a + b) / data.history.length).toStringAsFixed(1)}${data.unit}', highlight: true)),
              ],
            ),
            
            const SizedBox(height: 32),
            
            // Threshold Settings
            Builder(
              builder: (context) {
                final thresholds = ref.watch(thresholdProvider);
                final threshold = thresholds[widget.sensorType]!;
                final unit = data.unit;

                return Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.cardBackground,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.cardBorder),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.notifications_active, color: AppColors.accentCyan),
                          const SizedBox(width: 12),
                          Text('Threshold Settings', style: Theme.of(context).textTheme.titleLarge),
                        ],
                      ),
                      const SizedBox(height: 24),
                      
                      if (widget.sensorType != SensorType.motion) ...[
                        () {
                          double minRange = 0;
                          double maxRange = 100;
                          
                          // Custom ranges per sensor type logic
                          if (widget.sensorType == SensorType.pressure) {
                            minRange = 900;
                            maxRange = 1100;
                          } else if (widget.sensorType == SensorType.temperature) {
                            minRange = -20;
                            maxRange = 60;
                          }

                          return Column(
                            children: [
                              _buildSliderRow('Max Alert Limit', threshold.max ?? maxRange, minRange, maxRange, unit, (val) {
                                ref.read(thresholdProvider.notifier).updateThreshold(widget.sensorType, threshold.min, val);
                              }),
                              
                              const SizedBox(height: 16),
                              
                              _buildSliderRow('Min Alert Limit', threshold.min ?? minRange, minRange, maxRange, unit, (val) {
                                ref.read(thresholdProvider.notifier).updateThreshold(widget.sensorType, val, threshold.max);
                              }),
                            ],
                          );
                        }(),
                      ] else
                        const Text('Alerts are triggered on any motion detection.', style: TextStyle(color: AppColors.textSecondary)),
                      
                      const Divider(height: 32, color: AppColors.cardBorder),
                      
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Smart Notifications', style: Theme.of(context).textTheme.titleMedium),
                              const SizedBox(height: 4),
                              Text('Alert if threshold is crossed', style: Theme.of(context).textTheme.bodySmall),
                            ],
                          ),
                          Switch(
                            value: threshold.isEnabled,
                            onChanged: (val) {
                              ref.read(thresholdProvider.notifier).toggleThreshold(widget.sensorType, val);
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, String value, {bool highlight = false}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: highlight ? AppColors.accentCyan : Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSliderRow(String label, double value, double min, double max, String unit, ValueChanged<double> onChanged) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: Theme.of(context).textTheme.bodyMedium),
            Text('${value.toInt()}$unit', style: Theme.of(context).textTheme.titleMedium?.copyWith(color: AppColors.accentCyan)),
          ],
        ),
        const SizedBox(height: 8),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 4,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
          ),
          child: Slider(
            value: value,
            min: min,
            max: max,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  Widget _buildChart(SensorData data) {
    // Generate dummy spots based on history data
    final List<FlSpot> spots = [];
    for (int i = 0; i < data.history.length; i++) {
        spots.add(FlSpot(i.toDouble(), data.history[i]));
    }
    // If not enough history, pad it
    if (spots.isEmpty) {
        spots.addAll([
          const FlSpot(0, 20),
          const FlSpot(1, 23),
          const FlSpot(2, 22),
          const FlSpot(3, 25),
          const FlSpot(4, 21),
          const FlSpot(5, 24),
        ]);
    }

    return LineChart(
      LineChartData(
        gridData: FlGridData(show: false),
        titlesData: FlTitlesData(
          show: true,
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 22,
              interval: 1,
              getTitlesWidget: (value, meta) {
                if (value % 2 != 0 && value != spots.length - 1) return const SizedBox.shrink();
                String text = '';
                if (value == 0) text = '00:00';
                else if (value == 2) text = '06:00';
                else if (value == 4) text = '12:00';
                else if (value == spots.length - 1) text = 'NOW';
                
                return Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    text,
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 10),
                  ),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        minX: 0,
        maxX: (spots.length - 1).toDouble(),
        minY: 15, // Dummy bounds for demo
        maxY: 30,
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: AppColors.accentCyan,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [
                  AppColors.accentCyan.withOpacity(0.3),
                  AppColors.accentCyan.withOpacity(0.0),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
