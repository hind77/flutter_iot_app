import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class SqliteHelper {
  static const _databaseName = "IotAlerts.db";
  static const _databaseVersion = 1;

  static const tableAlerts = 'alerts';

  static const columnId = 'id';
  static const columnTitle = 'title';
  static const columnDescription = 'description';
  static const columnSeverity = 'severity';
  static const columnTimestamp = 'timestamp';
  static const columnIsResolved = 'isResolved';

  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), _databaseName);
    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
    );
  }

  Future _onCreate(Database db, int version) async {
    await db.execute('''
          CREATE TABLE $tableAlerts (
            $columnId TEXT PRIMARY KEY,
            $columnTitle TEXT NOT NULL,
            $columnDescription TEXT NOT NULL,
            $columnSeverity INTEGER NOT NULL,
            $columnTimestamp TEXT NOT NULL,
            $columnIsResolved INTEGER NOT NULL
          )
          ''');
  }

  Future<void> insertAlert(Map<String, dynamic> row) async {
    Database db = await database;
    await db.insert(tableAlerts, row, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Map<String, dynamic>>> queryAllAlerts() async {
    Database db = await database;
    return await db.query(tableAlerts, orderBy: '$columnTimestamp DESC');
  }

  Future<void> updateAlertStatus(String id, bool isResolved) async {
    Database db = await database;
    await db.update(
      tableAlerts,
      {columnIsResolved: isResolved ? 1 : 0},
      where: '$columnId = ?',
      whereArgs: [id],
    );
  }

  Future<void> deleteAlert(String id) async {
    Database db = await database;
    await db.delete(
      tableAlerts,
      where: '$columnId = ?',
      whereArgs: [id],
    );
  }
}
