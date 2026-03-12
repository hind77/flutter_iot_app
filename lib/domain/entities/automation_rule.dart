import '../../domain/entities/sensor_data.dart';

class AutomationRule {
  final String id;
  final String name;
  final SensorType triggerSensor;
  final double triggerValue;
  final bool triggerAbove; // true if > value, false if < value
  final String targetActuatorId;
  final bool actionOn; // true to turn ON, false for OFF
  final bool isEnabled;

  AutomationRule({
    required this.id,
    required this.name,
    required this.triggerSensor,
    required this.triggerValue,
    required this.triggerAbove,
    required this.targetActuatorId,
    required this.actionOn,
    this.isEnabled = true,
  });

  AutomationRule copyWith({
    String? id,
    String? name,
    SensorType? triggerSensor,
    double? triggerValue,
    bool? triggerAbove,
    String? targetActuatorId,
    bool? actionOn,
    bool? isEnabled,
  }) {
    return AutomationRule(
      id: id ?? this.id,
      name: name ?? this.name,
      triggerSensor: triggerSensor ?? this.triggerSensor,
      triggerValue: triggerValue ?? this.triggerValue,
      triggerAbove: triggerAbove ?? this.triggerAbove,
      targetActuatorId: targetActuatorId ?? this.targetActuatorId,
      actionOn: actionOn ?? this.actionOn,
      isEnabled: isEnabled ?? this.isEnabled,
    );
  }
}
