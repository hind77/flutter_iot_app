import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../domain/entities/sensor_data.dart';
import '../../domain/entities/threshold_entity.dart';
import '../providers/providers.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _pushEnabled = true;
  bool _emailEnabled = false;
  bool _smsEnabled = true;

  final TextEditingController _hostController = TextEditingController();
  final TextEditingController _portController = TextEditingController();
  final TextEditingController _topicController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await ref.read(sharedPrefsProvider.future);
    setState(() {
      _hostController.text = prefs.getString('mqtt_host') ?? 'broker.hivemq.com';
      _portController.text = prefs.getString('mqtt_port') ?? '1883';
      _topicController.text = prefs.getString('mqtt_topic') ?? 'flutter_iot_demo/sensors';
      _pushEnabled = prefs.getBool('push_enabled') ?? true;
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await ref.read(sharedPrefsProvider.future);
    await prefs.setString('mqtt_host', _hostController.text);
    await prefs.setString('mqtt_port', _portController.text);
    await prefs.setString('mqtt_topic', _topicController.text);
    await prefs.setBool('push_enabled', _pushEnabled);
    
    // Reconnect with new settings
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Settings Saved & Reconnecting...')),
      );
    }
    
    ref.read(mqttManagerProvider).connectCustom(
      _hostController.text,
      int.tryParse(_portController.text) ?? 1883,
      _topicController.text,
    );
  }

  @override
  void dispose() {
    _hostController.dispose();
    _portController.dispose();
    _topicController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // MQTT Config Section
            Row(
              children: [
                const Icon(Icons.router_rounded, color: AppColors.accentCyan),
                const SizedBox(width: 8),
                Text('MQTT Broker Config', style: Theme.of(context).textTheme.titleLarge),
              ],
            ),
            const SizedBox(height: 16),
            _buildTextField('Host', _hostController),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(flex: 1, child: _buildTextField('Port', _portController)),
                const SizedBox(width: 16),
                Expanded(flex: 2, child: _buildTextField('Topic', _topicController)),
              ],
            ),
            
            const SizedBox(height: 32),
            Divider(color: Theme.of(context).dividerColor),
            const SizedBox(height: 32),
            
            // Notifications Section
            Row(
              children: [
                const Icon(Icons.notifications_active, color: AppColors.accentCyan),
                const SizedBox(width: 8),
                Text('Notification Preferences', style: Theme.of(context).textTheme.titleLarge),
              ],
            ),
            const SizedBox(height: 16),
            _buildPreferenceCard(
              title: 'Light Mode Rendering',
              subtitle: 'Switch between dark and light themes',
              value: ref.watch(themeProvider) == ThemeMode.light,
              onChanged: (val) => ref.read(themeProvider.notifier).toggleTheme(),
            ),
            const SizedBox(height: 12),
            _buildPreferenceCard(
              title: 'Push Notifications',
              subtitle: 'Instant alerts on your device',
              value: _pushEnabled,
              onChanged: (val) => setState(() => _pushEnabled = val),
            ),
            const SizedBox(height: 12),
            _buildPreferenceCard(
              title: 'Email Reports',
              subtitle: 'Daily summary of device activity',
              value: _emailEnabled,
              onChanged: (val) => setState(() => _emailEnabled = val),
            ),
            const SizedBox(height: 12),
            _buildPreferenceCard(
              title: 'SMS Alerts',
              subtitle: 'Critical system failure alerts',
              value: _smsEnabled,
              onChanged: (val) => setState(() => _smsEnabled = val),
            ),
            
            const SizedBox(height: 32),
            Divider(color: Theme.of(context).dividerColor),
            const SizedBox(height: 32),

            // Smart Thresholds Section
            Row(
              children: [
                const Icon(Icons.security_rounded, color: AppColors.accentCyan),
                const SizedBox(width: 8),
                Text('Smart Thresholds', style: Theme.of(context).textTheme.titleLarge),
              ],
            ),
            const SizedBox(height: 8),
            Text('Set limits to trigger automatic alerts', style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 24),
            
            // Generate cards for each sensor type
            ...SensorType.values.map((type) {
              final threshold = ref.watch(thresholdProvider)[type]!;
              return _buildThresholdCard(type, threshold);
            }),
            
            const SizedBox(height: 32),
            Divider(color: Theme.of(context).dividerColor),
            const SizedBox(height: 32),
            
            // Devices Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.devices, color: AppColors.accentCyan),
                    const SizedBox(width: 8),
                    Text('Connected Devices', style: Theme.of(context).textTheme.titleLarge),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.accentCyan.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '3 ACTIVE',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.accentCyan,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildDeviceCard('Living Room Hub', 'ID: HUB-X9202', Icons.device_thermostat),
            const SizedBox(height: 12),
            _buildDeviceCard('Master Bedroom Lights', 'ID: LGT-B1001', Icons.lightbulb),
            const SizedBox(height: 12),
            _buildDeviceCard('Front Door Cam', 'ID: CAM-V4492', Icons.videocam),
            
            const SizedBox(height: 32),
            
            // Save Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saveSettings,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accentCyan,
                  foregroundColor: AppColors.background,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Save & Apply Settings', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 16),
            
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => ref.read(authProvider.notifier).logout(),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.criticalRed,
                  side: const BorderSide(color: AppColors.criticalRed),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.logout),
                    SizedBox(width: 8),
                    Text('Sign Out from Controller', style: TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.bodyMedium),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
          decoration: InputDecoration(
            fillColor: Theme.of(context).cardTheme.color,
            filled: true,
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Theme.of(context).dividerColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.accentCyan),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
        ),
      ],
    );
  }

  Widget _buildPreferenceCard({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: SwitchListTile(
        title: Text(title, style: Theme.of(context).textTheme.titleMedium),
        subtitle: Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
        value: value,
        onChanged: onChanged,
        activeColor: Colors.white,
        activeTrackColor: AppColors.accentCyan,
        inactiveThumbColor: Colors.white,
        inactiveTrackColor: AppColors.systemGray,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
    );
  }

  Widget _buildThresholdCard(SensorType type, ThresholdEntity threshold) {
    String label = type.name[0].toUpperCase() + type.name.substring(1);
    String unit = "";
    switch(type) {
      case SensorType.temperature: unit = "°C"; break;
      case SensorType.humidity: unit = "%"; break;
      case SensorType.pressure: unit = "hPa"; break;
      default: unit = "";
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: Theme.of(context).textTheme.titleMedium),
              Switch(
                value: threshold.isEnabled, 
                onChanged: (val) {
                  ref.read(thresholdProvider.notifier).toggleThreshold(type, val);
                },
                activeColor: AppColors.accentCyan,
              ),
            ],
          ),
          if (type != SensorType.motion) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildSmallThresholdInput(
                    'Min', 
                    threshold.min?.toString() ?? '0',
                    (val) => ref.read(thresholdProvider.notifier).updateThreshold(
                      type, double.tryParse(val), threshold.max
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildSmallThresholdInput(
                    'Max', 
                    threshold.max?.toString() ?? '100',
                    (val) => ref.read(thresholdProvider.notifier).updateThreshold(
                      type, threshold.min, double.tryParse(val)
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(unit, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ] else
            Text('Alert triggered on any motion detection', style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }

  Widget _buildSmallThresholdInput(String label, String value, Function(String) onSave) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
        const SizedBox(height: 4),
        SizedBox(
          height: 40,
          child: TextField(
            keyboardType: TextInputType.number,
            style: TextStyle(fontSize: 14, color: Theme.of(context).textTheme.bodyLarge?.color),
            decoration: InputDecoration(
              isDense: true,
              hintText: value,
              hintStyle: const TextStyle(color: AppColors.textSecondary),
              fillColor: Theme.of(context).scaffoldBackgroundColor,
              filled: true,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Theme.of(context).dividerColor)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            ),
            onSubmitted: onSave,
          ),
        ),
      ],
    );
  }

  Widget _buildDeviceCard(String name, String id, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              borderRadius: const BorderRadius.all(Radius.circular(12)),
            ),
            child: Icon(icon, color: AppColors.accentCyan),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 4),
                Text(id, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: AppColors.healthyGreen,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                'ONLINE',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.healthyGreen,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
