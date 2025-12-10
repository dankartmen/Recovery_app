import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../data/models/training_schedule.dart';
import '../../training/models/training.dart';
import 'auth_service.dart';

class TrainingService {
  static const String baseUrl = 'http://195.225.111.85:8000/schedules';
  final AuthService authService;

  TrainingService(this.authService);

  String get _authHeader => authService.getBasicAuthHeader();

  Future<TrainingSchedule> generateSchedule(int questionnaireId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/schedules'),
      headers: {
        'Authorization': _authHeader,
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'questionnaire_id': questionnaireId}),
    );

    if (response.statusCode == 201) {
      return TrainingSchedule.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to generate schedule: ${response.statusCode}');
    }
  }

  Future<List<TrainingSchedule>> getSchedules(int userId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/users/$userId/schedules'),
      headers: {'Authorization': _authHeader},
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => TrainingSchedule.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load schedules: ${response.statusCode}');
    }
  }

  Future<Training> updateTrainingStatus(int scheduleId, int trainingId, bool completed) async {
    final response = await http.put(
      Uri.parse('$baseUrl/schedules/$scheduleId/trainings/$trainingId'),
      headers: {
        'Authorization': _authHeader,
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'is_completed': completed}),
    );

    if (response.statusCode == 200) {
      return Training.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to update training: ${response.statusCode}');
    }
  }

  Future<List<Training>> getTrainingsForSchedule(int scheduleId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/$scheduleId/trainings'),
      headers: {'Authorization': _authHeader},
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => Training.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load trainings: ${response.statusCode}');
    }
  }


  /// Добавление новой тренировки в расписание
  Future<Training> addTraining(int scheduleId, Training newTraining) async {
    final response = await http.post(
      Uri.parse('$baseUrl/schedules/$scheduleId/trainings'),
      headers: {
        'Authorization': _authHeader,
        'Content-Type': 'application/json',
      },
      body: jsonEncode(newTraining.toJson()..remove('id')), // Убираем id для создания
    );

    if (response.statusCode == 201) {
      final updatedTraining = Training.fromJson(jsonDecode(response.body));
      return updatedTraining;
    } else {
      throw Exception('Failed to add training: ${response.statusCode}');
    }
  }

  /// Полное обновление тренировки (включая время, дату, статус)
  Future<Training> updateTraining(int scheduleId, int trainingId, Training updatedTraining) async {
    final response = await http.put(
      Uri.parse('$baseUrl/schedules/$scheduleId/trainings/$trainingId'),
      headers: {
        'Authorization': _authHeader,
        'Content-Type': 'application/json',
      },
      body: jsonEncode(updatedTraining.toJson()),
    );

    if (response.statusCode == 200) {
      final updated = Training.fromJson(jsonDecode(response.body));
      // Обновляем локальный кэш
      return updated;
    } else {
      throw Exception('Failed to update training: ${response.statusCode}');
    }
  }

  /// Удаление тренировки из расписания
  Future<void> deleteTraining(int scheduleId, int trainingId) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/schedules/$scheduleId/trainings/$trainingId'),
      headers: {'Authorization': _authHeader},
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to delete training: ${response.statusCode}');
    }
  }
}