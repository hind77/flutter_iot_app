# Flutter IoT App

A complete, beautifully designed Flutter mobile application for tracking and alerting sensor data in real-time. Built specifically by AI using the design mockups provided.

## Features Included
- **Clean Architecture:** Divided into Domain, Data, and Presentation layers.
- **Provider/Riverpod State Management:** Fully reactive architecture for updating sensor values and alerts.
- **MQTT Integration:** Pre-built `MqttService` for connecting to brokers and parsing JSON payloads.
- **Alert Engine:** Logic to trigger local/push notifications based on configurable threshold boundaries (Critical, Warning, System).
- **Local Storage:** SQLite implementation for persisting the log history of alerts locally.
- **Dynamic Charts:** Built using `fl_chart` to display historical sensor data spanning 24-hour periods.

## Screens Implemented
1. **Dashboard:** Status summaries, a 2x2 grid of specific sensors with micro sparklines and status indicators, and recent event logs.
2. **Alert Center:** Critical banners, searchable recent alerts separated by severity, quick-solve action components.
3. **Sensor Detail:** Enormous real-time status values, robust 24-hour line charts, statistical aggregations (min, max, avg), configurable threshold limits.
4. **Settings:** MQTT Broker Configuration, Notification toggles, listing of connected nodes/devices.

## Setup Instructions

1. Clone or copy this repository content to your local development environment.
2. Make sure Flutter is installed and functional: `flutter doctor`.
3. In the project root, run:
   ```bash
   flutter pub get
   ```
4. By default, the app uses dummy data modeled as providers for instantaneous visualization. To consume live MQTT events, modify `lib/presentation/providers/providers.dart` to rely solely on the stream emitted by `sensorDataStreamProvider` instead of `dummySensorProvider`.
5. Run the application:
   ```bash
   flutter run
   ```

## Requirements
- Flutter SDK >=3.2.0
- Dart SDK >=3.2.0

## License
MIT
