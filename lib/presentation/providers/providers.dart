import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_to_text.dart';
import '../../data/services/sqlite_helper.dart';
import '../../data/services/mqtt_service.dart';
import '../../data/services/notification_service.dart';
import '../../data/repositories/alert_repository_impl.dart';
import '../../data/repositories/sensor_repository_impl.dart';
import '../../domain/entities/sensor_data.dart';
import '../../domain/entities/alert_entity.dart';
import '../../domain/entities/threshold_entity.dart';
import '../../domain/entities/automation_rule.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'package:flutter/material.dart';

// Theme State
final themeProvider = StateNotifierProvider<ThemeNotifier, ThemeMode>((ref) {
  return ThemeNotifier(ref);
});

class ThemeNotifier extends StateNotifier<ThemeMode> {
  final Ref _ref;
  ThemeNotifier(this._ref) : super(ThemeMode.dark) {
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final prefs = await _ref.read(sharedPrefsProvider.future);
    final isLight = prefs.getBool('is_light_mode') ?? false;
    state = isLight ? ThemeMode.light : ThemeMode.dark;
  }

  Future<void> toggleTheme() async {
    final prefs = await _ref.read(sharedPrefsProvider.future);
    if (state == ThemeMode.dark) {
      state = ThemeMode.light;
      await prefs.setBool('is_light_mode', true);
    } else {
      state = ThemeMode.dark;
      await prefs.setBool('is_light_mode', false);
    }
  }
}

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
      final host = prefs.getString('mqtt_host') ?? 'broker.hivemq.com';
      final port = int.tryParse(prefs.getString('mqtt_port') ?? '1883') ?? 1883;
      final topic = prefs.getString('mqtt_topic') ?? 'hind_iot_demo/001/sensors';
      
      final success = await _repo.connect(host, port, topic);
      _ref.read(mqttConnectionStatusProvider.notifier).state = success;
      if (!success) {
        debugPrint('MQTT: Connection returned false (Check broker/network)');
      }
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

  Future<void> disconnect() async {
    try {
      await _repo.disconnect();
      _ref.read(mqttConnectionStatusProvider.notifier).state = false;
    } catch (e) {
      debugPrint('MQTT Disconnect failed: $e');
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
  final Ref _ref;
  final Set<String> _recentAlertCooldown = {};

  AlertNotifier(this._repository, this._ref) : super(const AsyncValue.loading()) {
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

  Future<void> clearAllAlerts() async {
    await _repository.deleteAllAlerts();
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

  // Monitor Incoming Data
  void checkThresholds(Map<SensorType, SensorData> data) {
    final thresholds = _ref.read(thresholdProvider);
    
    data.forEach((type, sensorData) {
      final threshold = thresholds[type];
      if (threshold == null || !threshold.isEnabled) return;

      bool isViolated = false;
      String message = "";
      AlertSeverity severity = AlertSeverity.warning;

      if (threshold.max != null && sensorData.value > threshold.max!) {
        isViolated = true;
        message = "${sensorData.type.name.toUpperCase()} exceeded ${threshold.max}${sensorData.unit}";
        severity = AlertSeverity.critical;
      } else if (threshold.min != null && sensorData.value < threshold.min!) {
        isViolated = true;
        message = "${sensorData.type.name.toUpperCase()} dropped below ${threshold.min}${sensorData.unit}";
        severity = AlertSeverity.warning;
      }

      if (isViolated) {
        _triggerAlert(
          title: "High/Low ${sensorData.type.name}",
          desc: message,
          severity: severity,
          sensorType: type,
        );
      }
    });
  }

  Future<void> _triggerAlert({
    required String title,
    required String desc,
    required AlertSeverity severity,
    required SensorType sensorType,
  }) async {
    // Basic cooldown to prevent alert spam (1 alert per sensor every 30 seconds)
    final cooldownKey = "${sensorType.name}_${severity.name}";
    if (_recentAlertCooldown.contains(cooldownKey)) return;
    
    _recentAlertCooldown.add(cooldownKey);
    Timer(const Duration(seconds: 30), () => _recentAlertCooldown.remove(cooldownKey));

    final newAlert = AlertEntity(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      description: desc,
      severity: severity,
      timestamp: DateTime.now(),
      sensorType: sensorType,
    );

    await _repository.saveAlert(newAlert);
    await loadAlerts();
    
    // Trigger real local push notification
    NotificationService.triggerAlert(title, desc);
    
    debugPrint("🔥 SMART ALERT TRIGGERED: $title - $desc");
  }
}

final alertProvider = StateNotifierProvider<AlertNotifier, AsyncValue<List<AlertEntity>>>((ref) {
  final notifier = AlertNotifier(ref.watch(alertRepositoryProvider), ref);
  
  // Watch sensor data and check against thresholds
  ref.listen(sensorDataStreamProvider, (previous, next) {
    if (next.hasValue) {
      notifier.checkThresholds(next.value!);
    }
  });
  
  return notifier;
});

// Threshold State Management
class ThresholdNotifier extends StateNotifier<Map<SensorType, ThresholdEntity>> {
  final Ref _ref;
  
  ThresholdNotifier(this._ref) : super(_defaultThresholds()) {
    _loadThresholds();
  }

  static Map<SensorType, ThresholdEntity> _defaultThresholds() {
    return {
      SensorType.temperature: const ThresholdEntity(type: SensorType.temperature, min: 10, max: 28),
      SensorType.humidity: const ThresholdEntity(type: SensorType.humidity, min: 20, max: 70),
      SensorType.pressure: const ThresholdEntity(type: SensorType.pressure, min: 900, max: 1100),
      SensorType.motion: const ThresholdEntity(type: SensorType.motion, max: 0.5), 
    };
  }

  Future<void> _loadThresholds() async {
    final prefs = await _ref.read(sharedPrefsProvider.future);
    final Map<SensorType, ThresholdEntity> loaded = {};
    
    for (var type in SensorType.values) {
      final keyMin = 'threshold_${type.name}_min';
      final keyMax = 'threshold_${type.name}_max';
      if (prefs.containsKey(keyMax)) {
        loaded[type] = ThresholdEntity(
          type: type,
          min: prefs.getDouble(keyMin),
          max: prefs.getDouble(keyMax),
        );
      }
    }
    
    if (loaded.isNotEmpty) {
      state = {...state, ...loaded};
    }
  }

  Future<void> updateThreshold(SensorType type, double? min, double? max) async {
    final prefs = await _ref.read(sharedPrefsProvider.future);
    final newThreshold = state[type]!.copyWith(min: min, max: max);
    
    state = {...state, type: newThreshold};
    
    if (min != null) await prefs.setDouble('threshold_${type.name}_min', min);
    if (max != null) await prefs.setDouble('threshold_${type.name}_max', max);
  }

  Future<void> toggleThreshold(SensorType type, bool isEnabled) async {
    final prefs = await _ref.read(sharedPrefsProvider.future);
    final newThreshold = state[type]!.copyWith(isEnabled: isEnabled);
    state = {...state, type: newThreshold};
    await prefs.setBool('threshold_${type.name}_enabled', isEnabled);
  }
}

final thresholdProvider = StateNotifierProvider<ThresholdNotifier, Map<SensorType, ThresholdEntity>>((ref) {
  return ThresholdNotifier(ref);
});

// Actuator State management
final actuatorProvider = StateNotifierProvider<ActuatorNotifier, Map<String, bool>>((ref) {
  return ActuatorNotifier(ref);
});

class ActuatorNotifier extends StateNotifier<Map<String, bool>> {
  final Ref _ref;
  ActuatorNotifier(this._ref) : super({
    'living_room_light': false,
    'kitchen_fan': false,
    'ac_unit': true,
  });

  Future<void> toggle(String id) async {
    final newValue = !state[id]!;
    state = {...state, id: newValue};
    
    // Publish to MQTT
    final repo = _ref.read(sensorRepositoryProvider);
    final prefs = await _ref.read(sharedPrefsProvider.future);
    final baseTopic = prefs.getString('mqtt_topic') ?? 'hind_iot_demo/001/sensors';
    
    // We'll use a 'commands' subtopic
    final cmdTopic = baseTopic.replaceAll('sensors', 'commands/$id');
    repo.sendCommand(cmdTopic, newValue ? 'ON' : 'OFF');
  }
}

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

// Provide live data with dummy fallback and dynamic threshold status
final liveSensorProvider = Provider<Map<SensorType, SensorData>>((ref) {
  final realData = ref.watch(sensorDataStreamProvider).value ?? {};
  final dummyData = ref.watch(dummySensorProvider);
  final thresholds = ref.watch(thresholdProvider);
  
  // Merge real data over dummy data to ensure all keys exist
  final Map<SensorType, SensorData> merged = Map.from(dummyData);
  merged.addAll(realData);

  // Apply dynamic status based on current thresholds
  final Map<SensorType, SensorData> finalized = {};
  merged.forEach((type, data) {
    var status = SensorStatus.normal;
    final threshold = thresholds[type];

    if (threshold != null && threshold.isEnabled) {
      if (threshold.max != null && data.value > threshold.max!) {
        status = SensorStatus.critical;
      } else if (threshold.min != null && data.value < threshold.min!) {
        status = SensorStatus.warning;
      }
    }
    
    finalized[type] = data.copyWith(status: status);
  });

  return finalized;
});

// Automation State Management
final automationProvider = StateNotifierProvider<AutomationNotifier, List<AutomationRule>>((ref) {
  final notifier = AutomationNotifier(ref);
  
  // Connect the engine to the sensor stream
  ref.listen(sensorDataStreamProvider, (previous, next) {
    if (next.hasValue) {
      notifier.processData(next.value!);
    }
  });
  
  return notifier;
});

class AutomationNotifier extends StateNotifier<List<AutomationRule>> {
  final Ref _ref;
  final Set<String> _triggerLock = {}; // Prevent flapping

  AutomationNotifier(this._ref) : super([
    AutomationRule(
      id: '1',
      name: 'Fan Auto-Cool',
      triggerSensor: SensorType.temperature,
      triggerValue: 27.0,
      triggerAbove: true,
      targetActuatorId: 'kitchen_fan',
      actionOn: true,
    ),
    AutomationRule(
      id: '2',
      name: 'Night Light on Motion',
      triggerSensor: SensorType.motion,
      triggerValue: 0.5,
      triggerAbove: true,
      targetActuatorId: 'living_room_light',
      actionOn: true,
    ),
  ]);

  void processData(Map<SensorType, SensorData> data) {
    for (var rule in state) {
      if (!rule.isEnabled) continue;
      
      final sensorData = data[rule.triggerSensor];
      if (sensorData == null) continue;

      bool shouldTrigger = rule.triggerAbove 
          ? sensorData.value > rule.triggerValue 
          : sensorData.value < rule.triggerValue;

      if (shouldTrigger) {
        _executeRule(rule);
      }
    }
  }

  void _executeRule(AutomationRule rule) {
    final lockKey = "${rule.id}_lock";
    if (_triggerLock.contains(lockKey)) return;

    // Apply lock for 1 minute to avoid spamming the toggle
    _triggerLock.add(lockKey);
    Timer(const Duration(minutes: 1), () => _triggerLock.remove(lockKey));

    final currentStatus = _ref.read(actuatorProvider)[rule.targetActuatorId] ?? false;

    // Only set if different from desired
    if (currentStatus != rule.actionOn) {
      _ref.read(actuatorProvider.notifier).toggle(rule.targetActuatorId);
      debugPrint("🤖 AUTOMATION: Rule '${rule.name}' triggered!");
    }
  }

  void toggleRule(String id) {
    state = [
      for (final rule in state)
        if (rule.id == id) rule.copyWith(isEnabled: !rule.isEnabled) else rule,
    ];
  }
}

// Auth State Management
class UserEntity {
  final String email;
  final String name;
  UserEntity({required this.email, required this.name});
}

final authProvider = StateNotifierProvider<AuthNotifier, UserEntity?>((ref) {
  return AuthNotifier(ref);
});

class AuthNotifier extends StateNotifier<UserEntity?> {
  final Ref _ref;
  AuthNotifier(this._ref) : super(null) {
    _loadSession();
  }

  Future<void> _loadSession() async {
    final prefs = await _ref.read(sharedPrefsProvider.future);
    final email = prefs.getString('auth_email');
    if (email != null) {
      state = UserEntity(email: email, name: email.split('@')[0]);
    }
  }

  Future<bool> login(String email, String password) async {
    await Future.delayed(const Duration(seconds: 1));
    if (email.isNotEmpty && password.length >= 6) {
      state = UserEntity(email: email, name: email.split('@')[0]);
      final prefs = await _ref.read(sharedPrefsProvider.future);
      await prefs.setString('auth_email', email);
      return true;
    }
    return false;
  }

  Future<void> logout() async {
    state = null;
    final prefs = await _ref.read(sharedPrefsProvider.future);
    await prefs.remove('auth_email');
  }
}
