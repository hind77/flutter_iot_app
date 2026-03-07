import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import '../../domain/entities/sensor_data.dart';

class MqttService {
  MqttServerClient? _client;
  final _sensorDataController = StreamController<Map<SensorType, SensorData>>.broadcast();
  
  // Cache of latest sensor data
  Map<SensorType, SensorData> _currentData = {};

  Stream<Map<SensorType, SensorData>> get sensorDataStream => _sensorDataController.stream;

  Future<bool> connect(String host, int port, String topicPrefix) async {
    _client = MqttServerClient(host, 'flutter_client_${DateTime.now().millisecondsSinceEpoch}');
    _client!.port = port;
    _client!.logging(on: false);
    _client!.keepAlivePeriod = 20;

    final connMess = MqttConnectMessage()
        .startClean() // Non persistent session for simple example
        .withWillQos(MqttQos.atLeastOnce);
    
    _client!.connectionMessage = connMess;

    try {
      debugPrint('MQTT: Connecting to broker: $host, port: $port');
      await _client!.connect();
    } catch (e) {
      debugPrint('MQTT: Connection attempt failed: $e');
      _client!.disconnect();
      return false;
    }

    if (_client!.connectionStatus!.state == MqttConnectionState.connected) {
      debugPrint('MQTT: CONNECTION ESTABLISHED');
      _client!.updates!.listen(_onMessage);
      
      final subTopic = '$topicPrefix/#';
      debugPrint('MQTT: Subscribing to wildcard: $subTopic');
      _client!.subscribe(subTopic, MqttQos.atMostOnce);
      
      // Also subscribe to specific ones just in case wildcard is restricted on this broker
      _client!.subscribe('$topicPrefix/temperature', MqttQos.atMostOnce);
      _client!.subscribe('$topicPrefix/humidity', MqttQos.atMostOnce);
      
      return true;
    } else {
      debugPrint('MQTT: State is ${_client!.connectionStatus!.state}');
      _client!.disconnect();
      return false;
    }
  }

  void _onMessage(List<MqttReceivedMessage<MqttMessage>> event) {
    debugPrint('MQTT EVENT: Received ${event.length} messages');
    for (final message in event) {
      final recMess = message.payload as MqttPublishMessage;
      final payload = MqttPublishPayload.bytesToStringAsString(recMess.payload.message);
      final topic = message.topic;
      
      print('>>> MQTT DATA RECEIVED: $topic | $payload');
      debugPrint('>>> MQTT DATA RECEIVED: $topic | $payload');

      try {
        final Map<String, dynamic> data = jsonDecode(payload);
        final double value = (data['value'] as num).toDouble();
        final String unit = data['unit'] ?? '';
        final String statusStr = data['status'] ?? 'normal';
        
        SensorStatus status = SensorStatus.normal;
        if (statusStr == 'critical') status = SensorStatus.critical;
        if (statusStr == 'warning') status = SensorStatus.warning;

        SensorType? type;
        // Use contains/endsWidth for more flexible matching
        if (topic.contains('temperature')) type = SensorType.temperature;
        else if (topic.contains('humidity')) type = SensorType.humidity;
        else if (topic.contains('pressure')) type = SensorType.pressure;
        else if (topic.contains('motion')) type = SensorType.motion;

        if (type != null) {
          final existingData = _currentData[type];
          List<double> newHistory = existingData != null ? List.from(existingData.history) : [];
          newHistory.add(value);
          if (newHistory.length > 24) {
            newHistory.removeAt(0);
          }

          final newData = SensorData(
            type: type,
            value: value,
            unit: unit,
            status: status,
            timestamp: DateTime.now(),
            history: newHistory,
          );
          
          _currentData[type] = newData;
          debugPrint('MQTT UPDATED: $type set to $value');
          _sensorDataController.add(Map.from(_currentData));
        } else {
          debugPrint('MQTT WARN: Could not determine sensor type for topic: $topic');
        }
      } catch (e) {
        debugPrint('MQTT PARSE ERROR: $e | Payload was: $payload');
      }
    }
  }

  void disconnect() {
    _client?.disconnect();
  }
}
