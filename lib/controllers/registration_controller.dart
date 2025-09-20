import 'package:auth_test/services/auth_service.dart';
import 'package:flutter/material.dart';

/// {@template registration_controller}
/// Контроллер для управления процессом регистрации пользователя.
/// Обеспечивает валидацию данных, управление состоянием и обработку ошибок.
/// {@endtemplate}
class RegistrationController with ChangeNotifier {
  /// Сервис аутентификации для выполнения операций регистрации
  final AuthService _authService;

  /// Флаг состояния загрузки при регистрации
  bool isLoading = false;

  /// Общее сообщение об ошибке при регистрации
  String? errorMassage;

  /// Ошибка валидации имени пользователя
  String? usernameError;

  /// Ошибка валидации пароля
  String? passwordError;

  /// Ошибка валидации подтверждения пароля
  String? confirmPasswordError;

  /// Флаг отображения/скрытия пароля
  bool obscurePassword = true;

  /// Флаг отображения/скрытия подтверждения пароля
  bool obscureConfirmPassword = true;

  /// {@macro registration_controller}
  RegistrationController(this._authService);

  /// Переключение видимости пароля
  void togglePasswordVisibility() {
    obscurePassword = !obscurePassword;
    notifyListeners();
  }

  /// Переключение видимости подтверждения пароля
  void toggleConfirmPasswordVisibility() {
    obscureConfirmPassword = !obscureConfirmPassword;
    notifyListeners();
  }

  /// Очистка всех ошибок валидации
  void clearErrors() {
    errorMassage = null;
    usernameError = null;
    passwordError = null;
    confirmPasswordError = null;
    notifyListeners();
  }

  /// Валидация имени пользователя
  /// Принимает:
  /// - [value] - значение имени пользователя для валидации
  /// Возвращает:
  /// - текст ошибки или null если валидация успешна
  String? validateUsername(String? value) {
    if (value == null || value.isEmpty) {
      return 'Введите имя пользователя';
    }
    if (value.length < 3) {
      return 'Имя пользователя должно быть не менее 3 символов';
    }
    return null;
  }

  /// Валидация пароля
  /// Принимает:
  /// - [value] - значение пароля для валидации
  /// Возвращает:
  /// - текст ошибки или null если валидация успешна
  String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Введите пароль';
    }
    if (value.length < 8) {
      return 'Пароль должен быть не менее 8 символов';
    }
    if (!value.contains(RegExp(r'[A-Z]'))) {
      return 'Добавьте заглавную букву (A-Z)';
    }
    if (!value.contains(RegExp(r'[a-z]'))) {
      return 'Добавьте строчную букву (a-z)';
    }
    if (!value.contains(RegExp(r'[0-9]'))) {
      return 'Добавьте цифру (0-9)';
    }
    if (!value.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) {
      return 'Добавьте специальный символ';
    }
    return null;
  }

  /// Валидация подтверждения пароля
  /// Принимает:
  /// - [value] - значение подтверждения пароля
  /// - [password] - оригинальный пароль для сравнения
  /// Возвращает:
  /// - текст ошибки или null если валидация успешна
  String? validateConfirmPassword(String? value, String password) {
    final passwordError = validatePassword(value);
    if (passwordError != null) return passwordError;
    if (value != password) {
      return 'Пароли не совпадают';
    }
    return null;
  }

  /// Обработка регистрации пользователя
  /// Принимает:
  /// - [username] - имя пользователя
  /// - [password] - пароль пользователя
  /// - [confirmPassword] - подтверждение пароля
  /// Возвращает:
  /// - true если регистрация успешна, false при ошибке
  /// Выбрасывает исключение:
  /// - при ошибках сети, сервера или валидации данных
  Future<bool> register(String username, String password, String confirmPassword) async {
    clearErrors();
    try {
      usernameError = validateUsername(username);
      passwordError = validatePassword(password);
      confirmPasswordError = validateConfirmPassword(confirmPassword, password);

      if (usernameError != null || passwordError != null || confirmPasswordError != null) {
        notifyListeners();
        return false;
      }

      isLoading = true;
      notifyListeners();

      await _authService.register(username, password);
      errorMassage = null;
      return true;
    } catch (e) {
      errorMassage = e.toString();
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}