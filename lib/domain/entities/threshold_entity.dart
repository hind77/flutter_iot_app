import '../../domain/entities/sensor_data.dart';

class ThresholdEntity {
  final SensorType type;
  final double? min;
  final double? max;
  final bool isEnabled;

  const ThresholdEntity({
    required this.type,
    this.min,
    this.max,
    this.isEnabled = true,
  });

  ThresholdEntity copyWith({
    SensorType? type,
    double? min,
    double? max,
    bool? isEnabled,
  }) {
    return ThresholdEntity(
      type: type ?? this.type,
      min: min ?? this.min,
      max: max ?? this.max,
      isEnabled: isEnabled ?? this.isEnabled,
    );
  }
}
