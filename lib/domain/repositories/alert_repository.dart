import '../entities/alert_entity.dart';

abstract class AlertRepository {
  Future<List<AlertEntity>> getAlerts();
  Future<void> saveAlert(AlertEntity alert);
  Future<void> resolveAlert(String id);
  Future<void> dismissAlert(String id);
  Future<void> deleteAllAlerts();
}
