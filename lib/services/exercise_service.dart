import 'dart:convert';
import 'package:auth_test/data/models/models.dart';
import 'package:auth_test/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class ExerciseService {
  final AuthService authService;

  ExerciseService({required this.authService});

  static const String _baseUrl = 'http://178.130.49.215:8000/exercises';

  Future<List<Exercise>> getExercises({String? injuryType}) async {
    try {
      // Явное указание типа Map<String, String>
      final Map<String, String> queryParams = {};
      if (injuryType != null) {
        queryParams['injury_type'] = injuryType;
      }

      final uri = Uri.parse(_baseUrl).replace(queryParameters: queryParams);
      debugPrint('Запрос упражнений: $uri');

      final response = await http.get(
        uri,
        headers: {'Authorization': authService.getBasicAuthHeader()},
      );

      debugPrint('Статус ответа: ${response.statusCode}');
      debugPrint('Тело ответа: ${response.body}');

      if (response.statusCode == 200) {
        // Проверка на пустой ответ
        if (response.body.isEmpty) {
          debugPrint('Получен пустой ответ от сервера');
          return [];
        }

        try {
          final List<dynamic> data = jsonDecode(response.body);
          return data.map((e) => Exercise.fromJson(e)).toList();
        } catch (e) {
          debugPrint('Ошибка парсинга JSON: $e');
          return [];
        }
      } else {
        throw Exception('Ошибка загрузки: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Ошибка в getExercises: $e');
      rethrow;
    }
  }
}
