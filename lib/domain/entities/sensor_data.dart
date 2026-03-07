enum SensorType { temperature, humidity, pressure, motion }
enum SensorStatus { normal, warning, critical }

class SensorData {
  final SensorType type;
  final double value;
  final String unit;
  final SensorStatus status;
  final DateTime timestamp;
  final List<double> history; // Last 10 readings for sparkline

  const SensorData({
    required this.type,
    required this.value,
    required this.unit,
    required this.status,
    required this.timestamp,
    this.history = const [],
  });

  SensorData copyWith({
    SensorType? type,
    double? value,
    String? unit,
    SensorStatus? status,
    DateTime? timestamp,
    List<double>? history,
  }) {
    return SensorData(
      type: type ?? this.type,
      value: value ?? this.value,
      unit: unit ?? this.unit,
      status: status ?? this.status,
      timestamp: timestamp ?? this.timestamp,
      history: history ?? this.history,
    );
  }
}
