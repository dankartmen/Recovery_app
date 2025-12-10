
import '../../core/services/questionnaire_service.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/models.dart';

class QuestionnaireRepository {
  static const _tableName = 'questionnaires';
  static const _baseUrl = 'http://195.225.111.85:8000';
  final _questionnaireService = QuestionnaireService();
  Future<Database> getDatabase() async {
    return openDatabase(
      join(await getDatabasesPath(), 'recovery_app.db'),
      onCreate: (db, version) {
        return db.execute('''CREATE TABLE $_tableName(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT,
            gender TEXT,
            weight REAL,
            height REAL,
            mainInjuryType TEXT,
            specificInjury TEXT,
            painLevel INTEGER,
            trainingTime TEXT
          )''');
      },
      version: 1,
    );
  }

  Future<void> saveQuestionnaire(RecoveryData data) async {
    final db = await getDatabase();
    if (data.id == null) {
      await db.insert('questionnaires', data.toMap());
      debugPrint('DEBUG: local db insers OK');
    } else {
      await db.update(
        'questionnaires',
        data.toMap(),
        where: 'id = ?',
        whereArgs: [data.id],
      );
    }
  }

  Future<RecoveryData?> getLatestQuestionnaire() async {
    final db = await getDatabase();
    final maps = await db.query('questionnaires', orderBy: 'id DESC', limit: 1);

    if (maps.isNotEmpty) {
      debugPrint('Latest questionnaire found: ${maps.first}');
      return RecoveryData.fromMap(maps.first);
    }
    debugPrint('No questionnaires found');
    return null;
  }

  // Метод проверки анкеты
  Future<bool> checkQuestionnaire(
    int userId, {
    bool checkServer = false,
  }) async {
    // Проверка локальной БД
    final db = await getDatabase();
    final localResult = await db.query(
      'questionnaires',
      where: 'user_id = ?',
      whereArgs: [userId],
      limit: 1,
    );

    if (localResult.isNotEmpty) return true;

    // Дополнительная проверка на сервере
    if (checkServer) {
      try {
        final response = await http.get(
          Uri.parse('$_baseUrl/users/$userId/questionnaire'),
        );
        return response.statusCode == 200;
      } catch (e) {
        return false;
      }
    }

    return false;
  }

  // Cинхронизация данных
  Future<void> syncWithServer(String basicAuth, int userId) async {
    try {
      final serverData = await _questionnaireService.getQuestionnaire(basicAuth, userId);

      if (serverData.isNotEmpty) {
        await saveQuestionnaire(RecoveryData.fromJson(serverData));
      }
    } catch (e) {
      debugPrint('Ошибка синхронизации: $e');
    }
  }

  // Метод сохранения на сервер
  Future<void> saveToServer(
    RecoveryData data,
    String basicAuth,
    int userId,
  ) async {
    try {
      debugPrint("Сохранение анкеты на сервере: ${data.toJson()}");

      final response = await _questionnaireService.saveQuestionnaire(data, basicAuth, userId);


      if (response.statusCode != 200) {
        throw Exception('Ошибка сохранения анкеты: ${response.body}');
      }
    } catch (e) {
      debugPrint("Ошибка при сохранении анкеты: $e");
      rethrow;
    }
  }

  /// Загрузка анкеты пользователя с сервера
  /// Возвращает:
  /// - данные восстановления или null если анкета не найдена
  Future<RecoveryData?> fetchQuestionnaire(String basicAuth, int userId) async {
    try {
      debugPrint("Запрос анкеты для user_id: $userId");

      final data = await _questionnaireService.getQuestionnaire(basicAuth, userId);

      debugPrint("Полученные данные анкеты: $data");

      if (data.isNotEmpty) {
        final recoveryData = RecoveryData.fromJson(data);
        await saveQuestionnaire(recoveryData);
        return recoveryData;
      } 
      return null;
    } catch (e) {
      debugPrint('Ошибка при загрузке анкеты: $e');
      rethrow;
    }
  }

  Future<void> clearLocalData() async {
    final db = await getDatabase();
    await db.delete('questionnaires');
  }
}
