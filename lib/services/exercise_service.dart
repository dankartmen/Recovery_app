import 'dart:convert';
import '../exercises/models/exercise.dart';
import 'auth_service.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

/// {@template exercise_service}
/// Сервис для работы с упражнениями.
/// Обеспечивает загрузку упражнений с сервера с возможностью фильтрации по типу травмы.
/// {@endtemplate}
class ExerciseService {
  /// Сервис аутентификации для получения заголовков авторизации
  final AuthService authService;

  /// Базовый URL сервера для API упражнений
  static const String _baseUrl = 'http://195.225.111.85:8000/exercises';

  /// {@macro exercise_service}
  ExerciseService({required this.authService});

  /// Получение списка упражнений с сервера
  /// Принимает:
  /// - [injuryType] - опциональный параметр для фильтрации упражнений по типу травмы
  /// Возвращает:
  /// - список упражнений
  /// Выбрасывает исключение:
  /// - при ошибках сети, сервера или аутентификации
  Future<List<Exercise>> getExercises({String? injuryType}) async {
    try {
      // Формируем параметры запроса
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
      if (e.toString().contains('SocketException')) {
        throw Exception('Ошибка соединения с сервером. Проверьте интернет.');
      }
      rethrow;
    }
  }
}
