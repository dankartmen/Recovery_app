import '../services/auth_service.dart';
import 'package:flutter/material.dart';


/// {@template login_controller}
/// Контроллер для управления процессом аутентификации пользователя.
/// Обрабатывает логику входа, управление состоянием и ошибками.
/// {@endtemplate}
class AuthController with ChangeNotifier{
  /// Сервис аутентификации для выполнения операций входа
  final AuthService _authService;

  /// Флаг состояния загрузки при выполнении операций аутентификации
  bool isLoading = false;

  /// Сообщение об ошибке при операциях аутентификации
  String? errorMassage;

  AuthController(this._authService);

  /// Выполнение входа пользователя в систему
  /// Принимает:
  /// - [username] - имя пользователя
  /// - [password] - пароль пользователя
  /// - [context] - контекст построения виджета для навигации
  /// Выбрасывает исключение:
  /// - при ошибках сети, сервера или аутентификации
  Future<void> login(String username, String password, BuildContext context) async {
    isLoading = true;
    errorMassage = null;
    notifyListeners();

    try {
      await _authService.login(username,password);
      errorMassage = null;
      if(!context.mounted) return;
      await _authService.handlePostLoginNavigation(context);
    } catch (e) {
      errorMassage = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  /// Очистка сообщения об ошибке
  void cleanError(){
    errorMassage = null;
    notifyListeners();
  }
}