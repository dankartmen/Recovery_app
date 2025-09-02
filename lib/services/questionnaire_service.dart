import 'dart:convert';

import 'package:http/http.dart' as http;

/// {@template questionnaire_service}
/// Сервис для работы с анкетами пользователя.
/// Обеспечивает сохранение и загрузку анкет с сервера.
/// {@endtemplate}
class QuestionnaireService {
  /// Базовый URL сервера для API анкет
  final String _baseUrl = 'http://176.114.91.241:8000';

  /// {@macro questionnaire_service}
  QuestionnaireService();

  /// Сохранение анкеты пользователя на сервере
  /// Принимает:
  /// - [data] - данные анкеты для сохранения
  /// - [token] - токен аутентификации пользователя
  /// - [userId] - идентификатор пользователя
  /// Возвращает:
  /// - HTTP ответ от сервера
  Future<http.Response> saveQuestionnaire(
    Map<String, dynamic> data,
    String token,
    int userId,
  ) async {
    return await http.post(
      Uri.parse('$_baseUrl/questionnaires?user_id=$userId'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(data),
    );
  }

  /// Получение анкеты пользователя с сервера
  /// Принимает:
  /// - [userId] - идентификатор пользователя
  /// - [token] - токен аутентификации пользователя
  /// Возвращает:
  /// - данные анкеты в формате Map или пустой Map при ошибке
  Future<Map<String, dynamic>> getQuestionnaire(
    int userId,
    String token,
  ) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/users/$userId/questionnaire'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    return {};
  }
}
