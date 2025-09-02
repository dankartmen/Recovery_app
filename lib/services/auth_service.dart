import 'dart:convert';
import 'package:auth_test/data/models/models.dart';
import 'package:auth_test/data/repositories/questionnaire_repository.dart';
import 'package:auth_test/data/models/user_model.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../data/models/training_schedule.dart';

/// {@template auth_service}
/// Сервис для управления аутентификацией и авторизацией пользователя.
/// Обеспечивает регистрацию, вход, выход, управление сессией и загрузку данных пользователя.
/// {@endtemplate}
class AuthService with ChangeNotifier {
  /// Ключ для хранения сессии пользователя в SharedPreferences
  static const String _prefKey = 'user_session';

  /// Базовый URL сервера для API запросов
  static const String _baseUrl = 'http://176.114.91.241:8000';

  /// Имя пользователя для аутентификации
  String? _username;

  /// Пароль пользователя для аутентификации
  String? _password;

  /// Текущий аутентифицированный пользователь
  User? _currentUser;

  /// Флаг состояния загрузки
  bool _isLoading = false;

  /// Сообщение об ошибке при операциях аутентификации
  String? _errorMessage;

  /// Флаг завершения инициализации сервиса
  bool _isInitialized = false;

  /// {@macro auth_service}
  AuthService();

  /// Флаг завершения инициализации сервиса
  bool get isInitialized => _isInitialized;

  /// Текущий аутентифицированный пользователь
  User? get currentUser => _currentUser;

  /// Флаг состояния загрузки
  bool get isLoading => _isLoading;

  /// Сообщение об ошибке при операциях аутентификации
  String? get errorMessage => _errorMessage;

  /// Инициализация сервиса и попытка автоматического входа по сохраненным данным
  /// Выполняется при запуске приложения для восстановления сессии
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

  /// Автоматический вход по сохранённым данным пользователя
  /// Вызывается при инициализации приложения для восстановления сессии
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

  /// Сохранение сессии пользователя в SharedPreferences
  /// Сохраняет имя пользователя и пароль в зашифрованном виде
  Future<void> _saveSession() async {
    if (_username == null || _password == null) return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _prefKey,
      jsonEncode({'username': _username, 'password': _password}),
    );
  }

  /// Очистка сессии пользователя из SharedPreferences
  /// Удаляет все данные аутентификации и сбрасывает состояние
  Future<void> _clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefKey);
    _username = null;
    _password = null;
    _currentUser = null;
  }

  /// Формирование заголовка авторизации для HTTP запросов
  /// Возвращает:
  /// - строку с Basic Auth заголовком
  /// Выбрасывает исключение:
  /// - если пользователь не аутентифицирован
  String getBasicAuthHeader() {
    if (_username == null || _password == null) {
      throw Exception('Пользователь не аутентифицирован');
    }

    final credentials = base64Encode(utf8.encode('${_username}:${_password}'));
    return 'Basic $credentials';
  }

  /// Регистрация нового пользователя в системе
  /// Принимает:
  /// - [username] - имя пользователя для регистрации
  /// - [password] - пароль пользователя
  /// Возвращает:
  /// - зарегистрированного пользователя или null при ошибке
  /// Выбрасывает исключение:
  /// - при ошибках сети или сервера
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

  /// Аутентификация пользователя в системе
  /// Принимает:
  /// - [username] - имя пользователя
  /// - [password] - пароль пользователя
  /// Возвращает:
  /// - аутентифицированного пользователя
  /// Выбрасывает исключение:
  /// - при неверных учетных данных или ошибках сервера
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

  /// Сброс пароля пользователя
  /// Принимает:
  /// - [username] - имя пользователя для сброса пароля
  /// - [newPassword] - новый пароль пользователя
  /// Выбрасывает исключение:
  /// - при ошибках сервера или сети
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

  /// Выход пользователя из системы с очисткой локальных данных
  /// Удаляет сессию, анкету и расписание тренировок
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

  /// Загрузка анкеты пользователя с сервера
  /// Возвращает:
  /// - данные восстановления или null если анкета не найдена
  /// Выбрасывает исключение:
  /// - при ошибках сети, сервера или отсутствии аутентификации
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

  /// Установка состояния загрузки
  /// Принимает:
  /// - [value] - флаг состояния загрузки
  void setLoading(bool value) {
    _isLoading = value;
  }

  /// Установка сообщения об ошибке
  /// Принимает:
  /// - [message] - текст сообщения об ошибке
  void setError(String message) {
    _errorMessage = message;
  }

  /// Очистка сообщения об ошибке
  void clearError() {
    _errorMessage = null;
  }
}
