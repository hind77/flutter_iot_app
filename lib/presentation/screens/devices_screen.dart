import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class DevicesScreen extends StatelessWidget {
  const DevicesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
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
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Devices',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              letterSpacing: -0.5,
            ),
          ),
          const CircleAvatar(
            backgroundColor: AppColors.cardBackground,
            child: Icon(Icons.add, color: AppColors.accentCyan),
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
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.cardBorder),
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
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.cardBorder),
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
