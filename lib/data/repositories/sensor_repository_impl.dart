import '../../domain/entities/sensor_data.dart';
import '../../domain/repositories/sensor_repository.dart';
import '../services/mqtt_service.dart';

class SensorRepositoryImpl implements SensorRepository {
  final MqttService _mqttService;

  SensorRepositoryImpl(this._mqttService);

  @override
  Stream<Map<SensorType, SensorData>> get sensorDataStream => _mqttService.sensorDataStream;

  @override
  Future<bool> connect(String host, int port, String topic) async {
    return await _mqttService.connect(host, port, topic);
  }

  @override
  Future<void> disconnect() async {
    _mqttService.disconnect();
  }

  @override
  Future<void> updateThreshold(SensorType type, double min, double max) async {
    // In a real app, this might send an MQTT message back to the broker to update device thresholds
    // or just store locally so the app logic uses them.
    // For this UI demo, we will handle thresholds in the viewmodel/provider level.
  }
}
