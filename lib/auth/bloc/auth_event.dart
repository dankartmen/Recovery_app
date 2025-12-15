part of 'auth_bloc.dart';

/// {@template auth_event}
/// Базовый абстрактный класс для всех событий аутентификации.
/// {@endtemplate}
abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object> get props => [];
}

/// {@template login_event}
/// Событие для выполнения входа пользователя в систему.
/// Содержит учетные данные пользователя для аутентификации.
/// {@endtemplate}
class LoginEvent extends AuthEvent {
  /// Имя пользователя для входа в систему.
  final String username;

  /// Пароль пользователя для аутентификации.
  final String password;

  /// {@macro login_event}
  const LoginEvent({required this.username, required this.password});

  @override
  List<Object> get props => [username, password];
}