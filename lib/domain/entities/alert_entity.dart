import 'sensor_data.dart';

enum AlertSeverity { critical, warning, system }

class AlertEntity {
  final String id;
  final String title;
  final String description;
  final AlertSeverity severity;
  final DateTime timestamp;
  final bool isResolved;
  final SensorType? sensorType;

  const AlertEntity({
    required this.id,
    required this.title,
    required this.description,
    required this.severity,
    required this.timestamp,
    this.isResolved = false,
    this.sensorType,
  });

  AlertEntity copyWith({
    String? id,
    String? title,
    String? description,
    AlertSeverity? severity,
    DateTime? timestamp,
    bool? isResolved,
    SensorType? sensorType,
  }) {
    return AlertEntity(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      severity: severity ?? this.severity,
      timestamp: timestamp ?? this.timestamp,
      isResolved: isResolved ?? this.isResolved,
      sensorType: sensorType ?? this.sensorType,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'severity': severity.index,
      'timestamp': timestamp.toIso8601String(),
      'isResolved': isResolved ? 1 : 0,
      'sensorType': sensorType?.index,
    };
  }

  factory AlertEntity.fromMap(Map<String, dynamic> map) {
    return AlertEntity(
      id: map['id'] as String,
      title: map['title'] as String,
      description: map['description'] as String,
      severity: AlertSeverity.values[map['severity'] as int],
      timestamp: DateTime.parse(map['timestamp'] as String),
      isResolved: (map['isResolved'] as int) == 1,
      sensorType: map['sensorType'] != null ? SensorType.values[map['sensorType'] as int] : null,
    );
  }
}
