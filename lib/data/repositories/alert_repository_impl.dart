import '../../domain/entities/alert_entity.dart';
import '../../domain/repositories/alert_repository.dart';
import '../services/sqlite_helper.dart';

class AlertRepositoryImpl implements AlertRepository {
  final SqliteHelper _sqliteHelper;

  AlertRepositoryImpl(this._sqliteHelper);

  @override
  Future<List<AlertEntity>> getAlerts() async {
    final maps = await _sqliteHelper.queryAllAlerts();
    return maps.map((map) => AlertEntity.fromMap(map)).toList();
  }

  @override
  Future<void> saveAlert(AlertEntity alert) async {
    await _sqliteHelper.insertAlert(alert.toMap());
  }

  @override
  Future<void> resolveAlert(String id) async {
    await _sqliteHelper.updateAlertStatus(id, true);
  }

  @override
  Future<void> dismissAlert(String id) async {
    await _sqliteHelper.deleteAlert(id);
  }
}
