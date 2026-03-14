import 'package:flutter_riverpod/flutter_riverpod.dart';

class WeatherData {
  final double temperature;
  final String condition;
  final String icon;

  WeatherData({required this.temperature, required this.condition, required this.icon});
}

// Simulated Contextual Weather API Provider
final weatherProvider = FutureProvider<WeatherData>((ref) async {
  // Simulate network delay to an external API (e.g., OpenWeather)
  await Future.delayed(const Duration(seconds: 1));
  
  // Return mock data for the MVP presentation
  return WeatherData(
    temperature: 35.0,
    condition: 'Sunny',
    icon: '☀️',
  );
});
