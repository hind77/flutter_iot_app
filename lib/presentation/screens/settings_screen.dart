import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
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
            const Divider(color: AppColors.cardBorder),
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
            const Divider(color: AppColors.cardBorder),
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
            
            // Sign Out Button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () {},
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
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            fillColor: AppColors.cardBackground,
            filled: true,
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.cardBorder),
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
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
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

  Widget _buildDeviceCard(String name, String id, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.all(Radius.circular(12)),
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
