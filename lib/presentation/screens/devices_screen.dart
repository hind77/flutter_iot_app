import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/providers.dart';
import '../../domain/entities/automation_rule.dart';
import '../widgets/floor_plan_view.dart';

class DevicesScreen extends ConsumerWidget {
  const DevicesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Home Controller'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Floor Plan'),
              Tab(text: 'Devices'),
              Tab(text: 'Automations'),
            ],
            indicatorColor: AppColors.accentCyan,
            labelColor: AppColors.accentCyan,
          ),
        ),
        body: TabBarView(
          children: [
            const FloorPlanView(),
            _buildDevicesTab(context),
            _buildAutomationsTab(context, ref),
          ],
        ),
      ),
    );
  }

  Widget _buildDevicesTab(BuildContext context) {
    return Column(
      children: [
        _buildSearchBar(context),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            children: [
              _buildDeviceCard(
                context,
                title: 'Main Gateway',
                subtitle: 'Firmware: v2.3.1',
                icon: Icons.router_rounded,
                isOnline: true,
              ),
              _buildDeviceCard(
                context,
                title: 'Living Room Node',
                subtitle: 'Temp: 22°C | Humidity: 45%',
                icon: Icons.sensors_rounded,
                isOnline: true,
              ),
              _buildDeviceCard(
                context,
                title: 'Outdoor Camera',
                subtitle: 'Last Seen: 14 mins ago',
                icon: Icons.videocam_rounded,
                isOnline: false,
              ),
              _buildDeviceCard(
                context,
                title: 'Smart HVAC',
                subtitle: 'Current: 21°C | Mode: Auto',
                icon: Icons.air_rounded,
                isOnline: true,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAutomationsTab(BuildContext context, WidgetRef ref) {
    final rules = ref.watch(automationProvider);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(24.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Active Scenes', style: Theme.of(context).textTheme.titleLarge),
              const Icon(Icons.add_circle_outline, color: AppColors.accentCyan),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            itemCount: rules.length,
            itemBuilder: (context, index) {
              final rule = rules[index];
              return _buildAutomationCard(context, ref, rule);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildAutomationCard(BuildContext context, WidgetRef ref, AutomationRule rule) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.accentCyan.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.auto_fix_high, color: AppColors.accentCyan),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(rule.name, style: Theme.of(context).textTheme.titleMedium),
                    Text(
                      'IF ${rule.triggerSensor.name} ${rule.triggerAbove ? ">" : "<"} ${rule.triggerValue} THEN ${rule.targetActuatorId} ON',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              Switch(
                value: rule.isEnabled,
                onChanged: (val) => ref.read(automationProvider.notifier).toggleRule(rule.id),
                activeColor: AppColors.accentCyan,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardTheme.color,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Theme.of(context).dividerColor),
        ),
        child: TextField(
          decoration: InputDecoration(
            hintText: 'Search devices...',
            hintStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
            border: InputBorder.none,
            icon: const Icon(Icons.search, color: AppColors.textSecondary),
          ),
        ),
      ),
    );
  }

  Widget _buildDeviceCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isOnline,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
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
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Theme.of(context).dividerColor),
            ),
            child: Icon(icon, color: isOnline ? AppColors.accentCyan : AppColors.textSecondary),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 4),
                Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                isOnline ? 'Online' : 'Offline',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: isOnline ? AppColors.healthyGreen : AppColors.criticalRed,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: isOnline ? AppColors.healthyGreen : AppColors.criticalRed,
                  shape: BoxShape.circle,
                  boxShadow: [
                    if (isOnline)
                      BoxShadow(
                        color: AppColors.healthyGreen.withOpacity(0.5),
                        blurRadius: 4,
                        spreadRadius: 2,
                      ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
