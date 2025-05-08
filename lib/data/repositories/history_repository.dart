import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart';
import '../models/exercise_history.dart';
import 'dart:io';

class HistoryRepository {
  static const _databaseName = "ExerciseHistory.db";
  static const _databaseVersion = 1;
  static const tableName = 'history';

  HistoryRepository._privateConstructor();
  static final HistoryRepository instance =
      HistoryRepository._privateConstructor();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  static Future<Database> _initDatabase() async {
    // Инициализация FFI только для десктопных платформ
    if (!kIsWeb &&
        (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }

    final path = await getDatabasesPath();
    final dbPath = join(path, _databaseName);
    return await openDatabase(
      dbPath,
      onCreate: _onCreate,
      version: _databaseVersion,
    );
  }

  static Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $tableName (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        exerciseName TEXT NOT NULL,
        dateTime TEXT NOT NULL,
        duration INTEGER NOT NULL,
        notes TEXT
      )
    ''');
  }

  Future<int> addHistory(ExerciseHistory history) async {
    try {
      final db = await instance.database;
      return await db.insert(tableName, history.toMap());
    } catch (e) {
      print("Ошибка сохранения истории: $e");
      return -1;
    }
  }

  Future<List<ExerciseHistory>> getAllHistory() async {
    final db = await instance.database;
    final List<Map<String, dynamic>> maps = await db.query(
      tableName,
      orderBy: 'dateTime DESC',
    );
    return List.generate(maps.length, (i) => ExerciseHistory.fromMap(maps[i]));
  }

  Future<int> deleteHistory(int id) async {
    final db = await instance.database;
    return await db.delete(tableName, where: 'id = ?', whereArgs: [id]);
  }
}
