import 'dart:convert';
import 'package:auth_test/data/models/models.dart';
import 'package:auth_test/data/repositories/questionnaire_repository.dart';
import 'package:auth_test/data/models/user_model.dart';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../data/models/training_calendar_model.dart';
import '../data/models/training_schedule.dart';
import '../data/repositories/history_repository.dart';

class AuthService with ChangeNotifier {
  static const String _prefKey = 'user_session';
  String? _username;
  String? _password;
  User? _currentUser;
  static const String _baseUrl = 'http://176.114.91.241:8000';
  bool _isLoading = false;
  String? _errorMessage;
  bool _isInitialized = false;

  bool get isInitialized => _isInitialized;
  User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> initialize() async {
    if (_isInitialized) return; // Защита от повторной инициализации
    _isInitialized = true;

    setState(() => _isLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final sessionJson = prefs.getString(_prefKey);

      if (sessionJson != null) {
        final session = jsonDecode(sessionJson) as Map<String, dynamic>;
        _username = session['username'];
        _password = session['password'];

        // Пытаемся автоматически войти
        await _silentLogin();
      }
    } catch (e) {
      debugPrint('Ошибка инициализации сессии: $e');
    } finally {
      setState(() => _isLoading = false);
      notifyListeners(); // Уведомляем слушателей о завершении инициализации
    }
  }

  Future<void> _silentLogin() async {
    if (_username == null || _password == null) return;

    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/login'),
        headers: {
          'Authorization':
              'Basic ${base64Encode(utf8.encode('$_username:$_password'))}',
        },
      );

      if (response.statusCode == 200) {
        _currentUser = User.fromJson(jsonDecode(response.body));
        debugPrint('Автоматический вход успешен');
      }
    } catch (e) {
      debugPrint('Ошибка автоматического входа: $e');
      await _clearSession();
    }
  }

  Future<void> _saveSession() async {
    if (_username == null || _password == null) return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _prefKey,
      jsonEncode({'username': _username, 'password': _password}),
    );
  }

  Future<void> _clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefKey);
    _username = null;
    _password = null;
    _currentUser = null;
  }

  String getBasicAuthHeader() {
    if (_username == null || _password == null) {
      throw Exception('Пользователь не аутентифицирован');
    }

    final credentials = base64Encode(utf8.encode('${_username}:${_password}'));
    return 'Basic $credentials';
  }

  Future<User?> register(String username, String password) async {
    setState(() => _isLoading = true);
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'username': username, 'password': password}),
      );

      if (response.statusCode == 200) {
        final user = await login(username, password);

        // После успешной регистрации и входа
        if (user != null) {
          final questionnaire = await fetchQuestionnaire();
          if (questionnaire != null) {
            final calendarModel = TrainingCalendarModel(
              this,
              HistoryRepository(this),
            );
            await calendarModel.generateAndSaveSchedule(questionnaire);
          }
        }

        return user;
      }
    } catch (e) {
      setState(() => _errorMessage = e.toString());
      rethrow;
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<User?> login(String username, String password) async {
    setState(() => _isLoading = true);
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/login'),
        headers: {
          'Authorization':
              'Basic ${base64Encode(utf8.encode('$username:$password'))}',
        },
      );

      if (response.statusCode == 200) {
        _username = username;
        _password = password;
        _currentUser = User.fromJson(jsonDecode(response.body));
        await _saveSession();

        // Загружаем и сохраняем анкету
        final questionnaire = await fetchQuestionnaire();
        if (questionnaire != null) {
          final questionnaireRepo = QuestionnaireRepository();
          await questionnaireRepo.saveQuestionnaire(questionnaire);
        }

        return _currentUser;
      } else if (response.statusCode == 401) {
        throw Exception('Неверные учетные данные');
      } else {
        throw Exception('Ошибка сервера: ${response.statusCode}');
      }
    } catch (e) {
      setState(() => _errorMessage = e.toString());
      rethrow; // Проброс исключения для обработки в UI
    } finally {
      setState(() => _isLoading = false);
      notifyListeners();
    }
  }

  Future<void> resetPassword(String username, String newPassword) async {
    setState(() => _isLoading = true);
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/reset-password'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'username': username, 'new_password': newPassword}),
      );

      if (response.statusCode == 200) {
        debugPrint('Пароль успешно изменен');
      } else {
        throw Exception('Ошибка сброса пароля: ${response.statusCode}');
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> logout() async {
    await _clearSession();
    _errorMessage = null;
    notifyListeners();

    final questionnaireRepo = QuestionnaireRepository();
    await questionnaireRepo.clearLocalData();

    final scheduleBox = await Hive.openBox<TrainingSchedule>(
      'training_schedule',
    );
    await scheduleBox.clear();
  }

  void setState(VoidCallback fn) {
    fn();
    notifyListeners();
  }

  Future<RecoveryData?> fetchQuestionnaire() async {
    if (_currentUser == null || _username == null || _password == null) {
      debugPrint("Ошибка: Пользователь не аутентифицирован");
      return null;
    }

    try {
      debugPrint("Запрос анкеты для user_id: ${_currentUser!.id}");

      final response = await http.get(
        Uri.parse('$_baseUrl/users/${_currentUser!.id}/questionnaire'),
        headers: {'Authorization': getBasicAuthHeader()},
      );

      debugPrint("Статус ответа анкеты: ${response.statusCode}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        debugPrint("Полученные данные анкеты: $data");
        final questionnaireRepo = QuestionnaireRepository();
        questionnaireRepo.saveQuestionnaire(RecoveryData.fromJson(data));
        return RecoveryData.fromJson(data);
      } else if (response.statusCode == 404) {
        debugPrint("Анкета не найдена");
        return null; // Анкета не найдена
      } else {
        throw Exception('Ошибка сервера: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Ошибка при загрузке анкеты: $e');
      rethrow;
    }
  }

  void setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void setError(String message) {
    _errorMessage = message;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
