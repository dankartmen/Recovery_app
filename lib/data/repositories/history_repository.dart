import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:table_calendar/table_calendar.dart';
import '../../services/auth_service.dart';
import '../models/exercise_history.dart';

class HistoryRepository {
  static const String _baseUrl = 'http://178.130.49.215:8000';
  final AuthService authService;
  HistoryRepository(this.authService);

  Future<String?> _getAuthHeader() async {
    try {
      // Проверяем, инициализирован ли currentUser
      if (authService.currentUser == null) {
        await authService.initialize();
        debugPrint('Пользователь не аутентифицирован после инициализации');
        return null;
      }

      return authService.getBasicAuthHeader();
    } catch (e) {
      debugPrint('Ошибка получения заголовка авторизации: $e');
      return null;
    }
  }

  Future<int> addHistory(ExerciseHistory history) async {
    final authHeader = await _getAuthHeader();
    if (authHeader == null) return -1;

    final userId = authService.currentUser?.id;
    if (userId == null) return -1;

    final response = await http.post(
      Uri.parse('$_baseUrl/history'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': authHeader,
      },
      body: jsonEncode({...history.toJson(), 'user_id': userId}),
    );

    return response.statusCode == 200 ? 1 : -1;
  }

  Future<List<ExerciseHistory>> getAllHistory() async {
    await Future.delayed(Duration(seconds: 1));
    debugPrint("Запрос истории упражнений...");
    try {
      final authHeader = await _getAuthHeader();
      if (authHeader == null) {
        debugPrint("Ошибка: заголовок авторизации не получен");
        return [];
      }

      final userId = authService.currentUser?.id;
      if (userId == null) {
        debugPrint("Ошибка: ID пользователя не определен");
        return [];
      }

      debugPrint("Отправка запроса для пользователя ID: $userId");
      final response = await http.get(
        Uri.parse('$_baseUrl/users/$userId/history'),
        headers: {'Authorization': authHeader},
      );

      debugPrint("Статус ответа: ${response.statusCode}");
      debugPrint("Тело ответа: ${response.body}");

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        debugPrint("Получено записей: ${data.length}");
        return data.map((json) => ExerciseHistory.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      debugPrint("Критическая ошибка в getAllHistory: $e");
      return [];
    }
  }

  Future<List<ExerciseHistory>> getHistoryByDate(DateTime date) async {
    final allHistory = await getAllHistory();
    return allHistory.where((h) => isSameDay(h.dateTime, date)).toList();
  }

  Future<int> deleteHistory(int id) async {
    final authHeader = await _getAuthHeader();
    if (authHeader == null) return -1;

    final response = await http.delete(
      Uri.parse('$_baseUrl/history/$id'),
      headers: {'Authorization': authHeader},
    );

    return response.statusCode == 200 ? 1 : -1;
  }
}
