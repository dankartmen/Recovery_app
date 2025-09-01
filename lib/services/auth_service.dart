import 'dart:convert';
import 'package:auth_test/data/models/models.dart';
import 'package:auth_test/data/repositories/questionnaire_repository.dart';
import 'package:auth_test/data/models/user_model.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../data/models/training_schedule.dart';

class AuthService with ChangeNotifier {
  // Ключ для хранения сессии пользователя в SharedPreferences
  static const String _prefKey = 'user_session';

  // Данные пользователя и состояния авторизации
  String? _username;
  String? _password;
  User? _currentUser;
  static const String _baseUrl = 'http://176.114.91.241:8000';
  bool _isLoading = false;
  String? _errorMessage;
  bool _isInitialized = false;

  // Геттеры для доступа к состоянию
  bool get isInitialized => _isInitialized;
  User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Инициализация сервиса и попытка автоматического входа
  Future<void> initialize() async {
    if (_isInitialized) return; // Защита от повторной инициализации
    _isInitialized = true;

    setLoading(true);

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
      setLoading(false);
      notifyListeners(); // Уведомляем слушателей о завершении инициализации
    }
  }

  // Автоматический вход по сохранённым данным
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
        await _saveSession();
        notifyListeners(); // Только уведомляем слушателей!
      }
    } catch (e) {
      debugPrint('Ошибка автоматического входа: $e');
      await _clearSession();
      notifyListeners();
    }
  }

  // Сохраняем сессию пользователя в SharedPreferences
  Future<void> _saveSession() async {
    if (_username == null || _password == null) return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _prefKey,
      jsonEncode({'username': _username, 'password': _password}),
    );
  }

  // Очищаем сессию пользователя
  Future<void> _clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefKey);
    _username = null;
    _password = null;
    _currentUser = null;
  }

  // Формируем заголовок авторизации для запросов
  String getBasicAuthHeader() {
    if (_username == null || _password == null) {
      throw Exception('Пользователь не аутентифицирован');
    }

    final credentials = base64Encode(utf8.encode('${_username}:${_password}'));
    return 'Basic $credentials';
  }

  // Регистрация нового пользователя
  Future<User?> register(String username, String password) async {
    setLoading(true);
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'username': username, 'password': password}),
      );

      if (response.statusCode == 200) {
        final user = await login(username, password);
        return user;
      }
    } catch (e) {
      setError(e.toString());
      rethrow;
    } finally {
      setLoading(false);
    }
    return null;
  }

  // Вход пользователя
  Future<User?> login(String username, String password) async {
    setLoading(true);
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
      setError(e.toString());
      rethrow; // Проброс исключения для обработки в UI
    } finally {
      setLoading(false);
    }
  }

  // Сброс пароля пользователя
  Future<void> resetPassword(String username, String newPassword) async {
    setLoading(true);
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
      setLoading(false);
    }
  }

  // Выход пользователя и очистка локальных данных
  Future<void> logout() async {
    await _clearSession();
    _errorMessage = null;
    notifyListeners();

    // Очищаем локальные данные анкеты и расписания
    final questionnaireRepo = QuestionnaireRepository();
    await questionnaireRepo.clearLocalData();

    final scheduleBox = await Hive.openBox<TrainingSchedule>(
      'training_schedule',
    );
    await scheduleBox.clear();
  }

  // Получение анкеты пользователя с сервера
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

  // Управление состоянием загрузки и ошибок
  void setLoading(bool value) {
    _isLoading = value;
  }

  void setError(String message) {
    _errorMessage = message;
  }

  void clearError() {
    _errorMessage = null;
  }
}
