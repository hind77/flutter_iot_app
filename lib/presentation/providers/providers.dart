import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import '../../data/services/sqlite_helper.dart';
import '../../data/services/mqtt_service.dart';
import '../../data/repositories/alert_repository_impl.dart';
import '../../data/repositories/sensor_repository_impl.dart';
import '../../domain/entities/sensor_data.dart';
import '../../domain/entities/alert_entity.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Services
final sqliteHelperProvider = Provider<SqliteHelper>((ref) => SqliteHelper());
final mqttServiceProvider = Provider<MqttService>((ref) => MqttService());
final sharedPrefsProvider = FutureProvider<SharedPreferences>((ref) => SharedPreferences.getInstance());

// Connection State
final mqttConnectionStatusProvider = StateProvider<bool>((ref) => false);

final mqttManagerProvider = Provider((ref) {
  final repo = ref.watch(sensorRepositoryProvider);
  return MqttManager(repo, ref);
});

class MqttManager {
  final SensorRepositoryImpl _repo;
  final Ref _ref;
  MqttManager(this._repo, this._ref);

  Future<void> connectDefault() async {
    try {
      final prefs = await _ref.read(sharedPrefsProvider.future);
      final host = prefs.getString('mqtt_host') ?? 'broker.emqx.io';
      final port = int.tryParse(prefs.getString('mqtt_port') ?? '1883') ?? 1883;
      final topic = prefs.getString('mqtt_topic') ?? 'flutter_iot_demo/sensors';
      
      await _repo.connect(host, port, topic);
      _ref.read(mqttConnectionStatusProvider.notifier).state = true;
    } catch (e) {
      debugPrint('MQTT Default Connect failed: $e');
    }
  }

  Future<void> connectCustom(String host, int port, String topic) async {
    try {
      _ref.read(mqttConnectionStatusProvider.notifier).state = false;
      await _repo.disconnect();
      await _repo.connect(host, port, topic);
      _ref.read(mqttConnectionStatusProvider.notifier).state = true;
    } catch (e) {
      debugPrint('MQTT Custom Connect failed: $e');
    }
  }
}

// Repositories
final alertRepositoryProvider = Provider<AlertRepositoryImpl>((ref) {
  return AlertRepositoryImpl(ref.watch(sqliteHelperProvider));
});

final sensorRepositoryProvider = Provider<SensorRepositoryImpl>((ref) {
  return SensorRepositoryImpl(ref.watch(mqttServiceProvider));
});

// Streams
final sensorDataStreamProvider = StreamProvider<Map<SensorType, SensorData>>((ref) {
  final repo = ref.watch(sensorRepositoryProvider);
  return repo.sensorDataStream;
});

// Alert State
class AlertNotifier extends StateNotifier<AsyncValue<List<AlertEntity>>> {
  final AlertRepositoryImpl _repository;

  AlertNotifier(this._repository) : super(const AsyncValue.loading()) {
    init();
  }

  Future<void> init() async {
    if (kIsWeb) {
      await loadDummyData();
    } else {
      await loadAlerts();
    }
  }

  Future<void> loadAlerts() async {
    try {
      final alerts = await _repository.getAlerts();
      if (alerts.isEmpty && !kIsWeb) {
        // First run on mobile - pre-fill some dummy alerts for testing
        await _repository.saveAlert(AlertEntity(
          id: '1', title: 'High Temp - Kitchen', description: 'Immediate attention required',
          severity: AlertSeverity.critical, timestamp: DateTime.now(),
        ));
        final updated = await _repository.getAlerts();
        state = AsyncValue.data(updated);
      } else {
        state = AsyncValue.data(alerts);
      }
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> resolveAlert(String id) async {
    await _repository.resolveAlert(id);
    await loadAlerts();
  }

  Future<void> dismissAlert(String id) async {
    await _repository.dismissAlert(id);
    await loadAlerts();
  }
  
  // Dummy data generator for UI
  Future<void> loadDummyData() async {
    final List<AlertEntity> dummyAlerts = [
      AlertEntity(
        id: '1',
        title: 'High Temperature - Kitchen',
        description: 'Temperature exceeded 28°C threshold',
        severity: AlertSeverity.critical,
        timestamp: DateTime.now().subtract(const Duration(hours: 1)),
      ),
      AlertEntity(
        id: '2',
        title: 'Low Humidity - Office',
        description: 'Humidity dropped below 30%',
        severity: AlertSeverity.warning,
        timestamp: DateTime.now().subtract(const Duration(hours: 2, minutes: 15)),
      ),
      AlertEntity(
        id: '3',
        title: 'Battery Low - Hallway Sensor',
        description: 'Sensor node battery at 10%',
        severity: AlertSeverity.system,
        timestamp: DateTime.now().subtract(const Duration(hours: 3, minutes: 30)),
      ),
    ];
    state = AsyncValue.data(dummyAlerts);
  }
}

final alertProvider = StateNotifierProvider<AlertNotifier, AsyncValue<List<AlertEntity>>>((ref) {
  return AlertNotifier(ref.watch(alertRepositoryProvider));
});

// Simulated current sensor data for UI when not connected (to match screenshots)
final dummySensorProvider = Provider<Map<SensorType, SensorData>>((ref) {
  return {
    SensorType.temperature: SensorData(
      type: SensorType.temperature,
      value: 24.0,
      unit: '°C',
      status: SensorStatus.normal,
      timestamp: DateTime.now(),
      history: [22, 23, 23.5, 24, 25, 24.5, 24],
    ),
    SensorType.humidity: SensorData(
      type: SensorType.humidity,
      value: 45,
      unit: '%',
      status: SensorStatus.normal,
      timestamp: DateTime.now(),
      history: [40, 42, 44, 45, 46, 45],
    ),
    SensorType.pressure: SensorData(
      type: SensorType.pressure,
      value: 1013,
      unit: 'hPa',
      status: SensorStatus.normal,
      timestamp: DateTime.now(),
      history: [1010, 1011, 1012, 1013, 1013, 1013],
    ),
    SensorType.motion: SensorData(
      type: SensorType.motion,
      value: 0,
      unit: 'None',
      status: SensorStatus.normal,
      timestamp: DateTime.now(),
      history: [0, 0, 0, 0, 0, 0],
    ),
  };
});

// Provide live data with dummy fallback
final liveSensorProvider = Provider<Map<SensorType, SensorData>>((ref) {
  final realData = ref.watch(sensorDataStreamProvider).value ?? {};
  final dummyData = ref.watch(dummySensorProvider);
  
  // Merge real data over dummy data to ensure all keys exist
  final Map<SensorType, SensorData> merged = Map.from(dummyData);
  merged.addAll(realData);
  return merged;
});
