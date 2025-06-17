// questionnaire_service.dart
import 'dart:convert';

import 'package:http/http.dart' as http;

class QuestionnaireService {
  final String _baseUrl = 'http://178.130.49.215:8000';

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
