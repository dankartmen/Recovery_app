import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/models.dart';

class QuestionnaireRepository {
  static const _tableName = 'questionnaires';
  static const _baseUrl = 'http://176.114.91.241:8000';
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
      final response = await http.get(
        Uri.parse('$_baseUrl/users/$userId}/questionnaire'),
        headers: {'Authorization': basicAuth},
      );

      if (response.statusCode == 200) {
        final serverData = RecoveryData.fromJson(jsonDecode(response.body));
        await saveQuestionnaire(serverData);
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

      final response = await http.post(
        Uri.parse('$_baseUrl/questionnaires'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': basicAuth,
        },
        body: jsonEncode({...data.toJson(), 'user_id': userId}),
      );

      debugPrint("Статус ответа сервера: ${response.statusCode}");
      debugPrint("Тело ответа: ${response.body}");

      if (response.statusCode != 200) {
        throw Exception('Ошибка сохранения анкеты: ${response.body}');
      }
    } catch (e) {
      debugPrint("Ошибка при сохранении анкеты: $e");
      rethrow;
    }
  }

  Future<void> clearLocalData() async {
    final db = await getDatabase();
    await db.delete('questionnaires');
  }
}
