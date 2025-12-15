part of 'auth_bloc.dart';

/// {@template auth_state}
/// Базовый абстрактный класс для всех состояний аутентификации.
/// {@endtemplate}
abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object> get props => [];
}

/// {@template auth_initial}
/// Начальное состояние процесса аутентификации.
/// Используется при инициализации или сбросе состояния.
/// {@endtemplate}
class AuthInitial extends AuthState {}

/// {@template auth_loading}
/// Состояние загрузки при выполнении операции аутентификации.
/// Указывает на то, что запрос на аутентификацию обрабатывается.
/// {@endtemplate}
class AuthLoading extends AuthState {}

/// {@template auth_success}
/// Состояние успешной аутентификации.
/// Указывает на то, что пользователь успешно вошел в систему.
/// {@endtemplate}
class AuthSuccess extends AuthState {}

/// {@template auth_error}
/// Состояние ошибки при аутентификации.
/// Содержит сообщение об ошибке для отображения пользователю.
/// {@endtemplate}
class AuthError extends AuthState {
  /// Сообщение об ошибке аутентификации.
  final String errorMessage;

  /// {@macro auth_error}
  const AuthError({required this.errorMessage});

  @override
  List<Object> get props => [errorMessage];
}