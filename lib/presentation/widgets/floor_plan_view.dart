import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../domain/entities/sensor_data.dart';
import '../providers/providers.dart';

class FloorPlanView extends ConsumerWidget {
  const FloorPlanView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sensors = ref.watch(liveSensorProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Home Layout', style: theme.textTheme.titleLarge),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.accentCyan.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '2D Live Map',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.accentCyan,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return Stack(
                  children: [
                    // Base Floor Plan Silhouette
                    Center(
                      child: Container(
                        width: constraints.maxWidth * 0.9,
                        height: constraints.maxHeight * 0.8,
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.cardBackground : Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: AppColors.cardBorder, width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: CustomPaint(
                          painter: FloorPlanPainter(isDark: isDark),
                        ),
                      ),
                    ),
                    
                    // Interactive Sensor Nodes
                    _buildSensorNode(
                      constraints, 
                      top: 0.25, left: 0.25, 
                      type: SensorType.temperature, 
                      label: 'Kitchen',
                      data: sensors[SensorType.temperature],
                    ),
                    _buildSensorNode(
                      constraints, 
                      top: 0.6, left: 0.3, 
                      type: SensorType.motion, 
                      label: 'Living',
                      data: sensors[SensorType.motion],
                    ),
                    _buildSensorNode(
                      constraints, 
                      top: 0.3, left: 0.7, 
                      type: SensorType.humidity, 
                      label: 'Master',
                      data: sensors[SensorType.humidity],
                    ),
                    _buildSensorNode(
                      constraints, 
                      top: 0.7, left: 0.7, 
                      type: SensorType.pressure, 
                      label: 'Office',
                      data: sensors[SensorType.pressure],
                    ),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Tap nodes to view detailed analytics',
            style: theme.textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  Widget _buildSensorNode(
    BoxConstraints constraints, {
    required double top,
    required double left,
    required SensorType type,
    required String label,
    SensorData? data,
  }) {
    final statusColor = data?.status == SensorStatus.critical 
        ? AppColors.criticalRed 
        : data?.status == SensorStatus.warning 
            ? AppColors.warningOrange 
            : AppColors.healthyGreen;

    return Positioned(
      top: constraints.maxHeight * top,
      left: constraints.maxWidth * left,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.background,
              shape: BoxShape.circle,
              border: Border.all(color: statusColor, width: 2),
              boxShadow: [
                BoxShadow(color: statusColor.withOpacity(0.3), blurRadius: 8, spreadRadius: 2),
              ],
            ),
            child: Icon(
              _getIcon(type),
              size: 20,
              color: statusColor,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.background.withOpacity(0.8),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              '$label\n${data?.value ?? "--"}${data?.unit ?? ""}',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getIcon(SensorType type) {
    switch(type) {
      case SensorType.temperature: return Icons.thermostat_rounded;
      case SensorType.humidity: return Icons.water_drop_rounded;
      case SensorType.pressure: return Icons.compress_rounded;
      case SensorType.motion: return Icons.motion_photos_on_rounded;
    }
  }
}

class FloorPlanPainter extends CustomPainter {
  final bool isDark;
  FloorPlanPainter({required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = isDark ? Colors.white24 : Colors.black12
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    // Outer Walls
    canvas.drawRect(Offset.zero & size, paint);

    // Inner Partition walls
    final path = Path();
    
    // Vertical partition
    path.moveTo(size.width * 0.5, 0);
    path.lineTo(size.width * 0.5, size.height * 0.4);
    
    path.moveTo(size.width * 0.5, size.height * 0.6);
    path.lineTo(size.width * 0.5, size.height);

    // Horizontal partition
    path.moveTo(0, size.height * 0.5);
    path.lineTo(size.width * 0.4, size.height * 0.5);
    
    path.moveTo(size.width * 0.6, size.height * 0.5);
    path.lineTo(size.width, size.height * 0.5);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
