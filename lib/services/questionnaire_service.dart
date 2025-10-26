import 'dart:convert';

import 'package:http/http.dart' as http;

import '../data/models/models.dart';

/// {@template questionnaire_service}
/// Сервис для работы с анкетами пользователя.
/// Обеспечивает сохранение и загрузку анкет с сервера.
/// {@endtemplate}
class QuestionnaireService { 
  /// Базовый URL сервера для API анкет
  final String _baseUrl = 'http://195.225.111.85:8000/questionnaires';

  
  /// {@macro questionnaire_service}
  QuestionnaireService();

  // Метод получения анкеты с сервера
  Future<Map<String,dynamic>> getQuestionnaire(String basicAuth, int userId) async {

      final response = await http.get(
        Uri.parse('$_baseUrl/users/$userId/questionnaire'),
        headers: {'Authorization': basicAuth},
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return {};
  }

  // Метод сохранения на сервер
  Future<http.Response> saveQuestionnaire(
    RecoveryData data,
    String basicAuth,
    int userId,
  ) async {
      return await http.post(
        Uri.parse('$_baseUrl/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': basicAuth,
        },
        body: jsonEncode({...data.toJson(), 'user_id': userId}),
      );
  }
}
