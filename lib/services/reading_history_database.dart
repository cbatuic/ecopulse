import 'dart:math';

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
        green_index REAL NOT NULL,
        aerator_on INTEGER NOT NULL DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS bantai_reference (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        recorded_at INTEGER NOT NULL,
        temperature REAL NOT NULL,
        dissolved_oxygen REAL NOT NULL,
        green_index REAL NOT NULL,
        aerator_on INTEGER NOT NULL DEFAULT 0
      )
    ''');

    try {
      await db.execute('ALTER TABLE sensor_readings ADD COLUMN aerator_on INTEGER NOT NULL DEFAULT 0');
    } catch (_) {
      // Existing databases already have the column.
    }

    final referenceRows = await _queryRows(
      db,
      tableName: 'bantai_reference',
      columns: ['id'],
      limit: 1,
    );

    if (referenceRows.isEmpty) {
      await _seedReferenceData(db);
    }

    return db;
  }

  Future<Database> get referenceDatabase async {
    return database;
  }

  Future<void> _seedReferenceData(Database db) async {
    final start = DateTime(2026, 7, 1);
    final end = DateTime(2026, 8, 28, 18);
    var index = 0;
    for (var timestamp = start; !timestamp.isAfter(end); timestamp = timestamp.add(const Duration(hours: 6))) {
      final day = timestamp.difference(start).inHours / 24;
      final dailyCycle = sin(index * 0.55);
      final temperature = 26.4 + (day * 0.018) + dailyCycle * 1.3;
      final dissolvedOxygen = 6.8 - (day * 0.006) + dailyCycle * 0.35;
      final greenIndex = (0.28 + day * 0.0012 + (dailyCycle + 1) * 0.018).clamp(0.18, 0.52);
      final aeratorOn = dissolvedOxygen < 6.25 || index % 11 == 0;
      await db.insert('bantai_reference', {
        'recorded_at': timestamp.millisecondsSinceEpoch,
        'temperature': double.parse(temperature.toStringAsFixed(3)),
        'dissolved_oxygen': double.parse(dissolvedOxygen.toStringAsFixed(3)),
        'green_index': double.parse(greenIndex.toStringAsFixed(3)),
        'aerator_on': aeratorOn ? 1 : 0,
      });
      index++;
    }
  }

  Future<void> add(PondReading reading) async {
    final db = await database;
    await db.insert('sensor_readings', {
      'recorded_at': reading.recordedAt.millisecondsSinceEpoch,
      'temperature': reading.temperature,
      'dissolved_oxygen': reading.dissolvedOxygen,
      'green_index': reading.greenIndex,
      'aerator_on': reading.aeratorOn ? 1 : 0,
    });
  }

  Future<List<ReadingHistoryPoint>> all({int limit = 5000}) async {
    final db = await database;
    final rows = await _queryRows(db, tableName: 'sensor_readings', orderBy: 'recorded_at ASC', limit: limit);
    return rows.map(_fromRow).toList();
  }

  Future<List<ReadingHistoryPoint>> recent({int limit = 24}) async {
    final db = await database;
    final rows = await _queryRows(db, tableName: 'sensor_readings', orderBy: 'recorded_at DESC', limit: limit);
    return rows.reversed.map(_fromRow).toList();
  }

  Future<List<ReadingHistoryPoint>> range({
    required DateTime start,
    required DateTime end,
    int limit = 500,
  }) async {
    final db = await database;
    final rows = await _queryRows(
      db,
      tableName: 'sensor_readings',
      where: 'recorded_at >= ? AND recorded_at <= ?',
      whereArgs: [start.millisecondsSinceEpoch, end.millisecondsSinceEpoch],
      orderBy: 'recorded_at ASC',
      limit: limit,
    );

    return rows.map(_fromRow).toList();
  }

  Future<List<ReadingHistoryPoint>> referenceRange({
    required DateTime start,
    required DateTime end,
    int limit = 5000,
  }) async {
    final db = await database;
    final rows = await _queryRows(
      db,
      tableName: 'bantai_reference',
      where: 'recorded_at >= ? AND recorded_at <= ?',
      whereArgs: [start.millisecondsSinceEpoch, end.millisecondsSinceEpoch],
      orderBy: 'recorded_at ASC',
      limit: limit,
    );
    return rows.map(_fromRow).toList();
  }

  ReadingHistoryPoint _fromRow(Map<String, Object?> row) => ReadingHistoryPoint(
        recordedAt: DateTime.fromMillisecondsSinceEpoch(row['recorded_at']! as int),
        temperature: (row['temperature']! as num).toDouble(),
        dissolvedOxygen: (row['dissolved_oxygen']! as num).toDouble(),
        greenIndex: (row['green_index']! as num).toDouble(),
        aeratorOn: ((row['aerator_on'] ?? 0) as int) == 1,
      );

  Future<List<Map<String, Object?>>> _queryRows(
    Database db, {
    required String tableName,
    List<String>? columns,
    String? where,
    List<Object?>? whereArgs,
    String? orderBy,
    int? limit,
  }) async {
    final dynamic result = await db.query(
      tableName,
      columns: columns,
      where: where,
      whereArgs: whereArgs,
      orderBy: orderBy,
      limit: limit,
    );
    if (result is! List) return const <Map<String, Object?>>[];
    return result.whereType<Map>().map((row) => Map<String, Object?>.from(row)).toList();
  }

  Future<void> close() async {
    await _database?.close();
    _database = null;
  }
}
