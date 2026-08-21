import 'package:sqflite_common/sqlite_api.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';

import '../models/pond_reading.dart';
import '../models/reading_history_point.dart';

class ReadingHistoryDatabase {
  Database? _database;

  Future<Database> get database async {
    return _database ??= await _open();
  }

  Future<Database> _open() async {
    final db = await databaseFactoryFfiWeb.openDatabase('ecopulse_history.db');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS sensor_readings (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        recorded_at INTEGER NOT NULL,
        temperature REAL NOT NULL,
        dissolved_oxygen REAL NOT NULL,
        green_index REAL NOT NULL
      )
    ''');
    return db;
  }

  Future<void> add(PondReading reading) async {
    final db = await database;
    await db.insert('sensor_readings', {
      'recorded_at': reading.recordedAt.millisecondsSinceEpoch,
      'temperature': reading.temperature,
      'dissolved_oxygen': reading.dissolvedOxygen,
      'green_index': reading.greenIndex,
    });
    await db.delete(
      'sensor_readings',
      where: 'recorded_at < ?',
      whereArgs: [DateTime.now().subtract(const Duration(hours: 24)).millisecondsSinceEpoch],
    );
  }

  Future<List<ReadingHistoryPoint>> recent({int limit = 24}) async {
    final db = await database;
    final rows = await db.query('sensor_readings', orderBy: 'recorded_at DESC', limit: limit);
    return rows.reversed.map((row) => ReadingHistoryPoint(
      recordedAt: DateTime.fromMillisecondsSinceEpoch(row['recorded_at']! as int),
      temperature: row['temperature']! as double,
      dissolvedOxygen: row['dissolved_oxygen']! as double,
      greenIndex: row['green_index']! as double,
    )).toList();
  }

  Future<void> close() async {
    await _database?.close();
    _database = null;
  }
}
