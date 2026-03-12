import '../entities/sensor_data.dart';

abstract class SensorRepository {
  Stream<Map<SensorType, SensorData>> get sensorDataStream;
  Future<bool> connect(String host, int port, String topic);
  Future<void> disconnect();
  Future<void> sendCommand(String topic, String command);
  Future<void> updateThreshold(SensorType type, double min, double max);
}
