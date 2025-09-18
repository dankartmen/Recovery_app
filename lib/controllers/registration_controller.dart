import 'package:auth_test/services/auth_service.dart';
import 'package:flutter/material.dart';

class RegistrationController with ChangeNotifier{
  final AuthService _authService;
  bool isLoading = false;
  String? errorMassage;
  String? usernameError;
  String? passwordError;
  String? confirmPasswordError;
  bool obscurePassword = true;
  bool obscureConfirmPassword = true;

  RegistrationController(this._authService);

  void togglePasswordVisibility() {
    obscurePassword = !obscurePassword;
    notifyListeners();
  }

  void toggleConfirmPasswordVisibility() {
    obscureConfirmPassword = !obscureConfirmPassword;
    notifyListeners();
  }

  void clearErrors() {
    errorMassage = null;
    usernameError = null;
    passwordError = null;
    confirmPasswordError = null;
    notifyListeners();
  }

  // Validation
  String? validateUsername(String? value) {
    if (value == null || value.isEmpty) {
      return 'Введите имя пользователя';
    }
    if (value.length < 3) {
      return 'Имя пользователя должно быть не менее 3 символов';
    }
    return null;
  }

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

  String? validateConfirmPassword(String? value, String password) {
    final passwordError = validatePassword(value);
    if (passwordError != null) return passwordError;
    if (value != password) {
      return 'Пароли не совпадают';
    }
    return null;
  }
  /// Обработка регистрации пользователя
  /// Выполняет валидацию формы, отправку данных на сервер и инициализацию данных пользователя
  /// Выбрасывает исключение:
  /// - при ошибках сети, сервера или валидации данных
  Future<bool> register(String username, String password, String confirmPassword) async {
    clearErrors();
    try {
      usernameError = validateUsername(username);
      passwordError = validatePassword(password);
      confirmPasswordError = validateConfirmPassword(confirmPassword, password);

      if (usernameError != null || passwordError != null || confirmPasswordError != null){
        notifyListeners();
        return false;
      }

      isLoading = true;
      notifyListeners();

      await _authService.register(
        username,password
      );
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