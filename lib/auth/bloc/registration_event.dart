part of 'registration_bloc.dart';

/// {@template registration_event}
/// Базовый абстрактный класс для всех событий регистрации.
/// {@endtemplate}
abstract class RegistrationEvent extends Equatable {
  const RegistrationEvent();

  @override
  List<Object?> get props => [];
}

/// {@template update_username_event}
/// Событие для обновления имени пользователя в форме регистрации.
/// {@endtemplate}
class UpdateUsername extends RegistrationEvent {
  /// Новое значение имени пользователя.
  final String value;

  /// {@macro update_username_event}
  const UpdateUsername(this.value);
  
  @override
  List<Object?> get props => [value];
}

/// {@template update_password_event}
/// Событие для обновления пароля в форме регистрации.
/// {@endtemplate}
class UpdatePassword extends RegistrationEvent {
  /// Новое значение пароля.
  final String value;

  /// {@macro update_password_event}
  const UpdatePassword(this.value);
  
  @override
  List<Object?> get props => [value];
}

/// {@template update_confirm_password_event}
/// Событие для обновления подтверждения пароля в форме регистрации.
/// {@endtemplate}
class UpdateConfirmPassword extends RegistrationEvent {
  /// Новое значение подтверждения пароля.
  final String value;

  /// {@macro update_confirm_password_event}
  const UpdateConfirmPassword(this.value);
  
  @override
  List<Object?> get props => [value];
}

/// {@template toggle_password_visibility_event}
/// Событие для переключения видимости пароля в форме регистрации.
/// {@endtemplate}
class TogglePasswordVisibility extends RegistrationEvent {}

/// {@template toggle_confirm_password_visibility_event}
/// Событие для переключения видимости подтверждения пароля в форме регистрации.
/// {@endtemplate}
class ToggleConfirmPasswordVisibility extends RegistrationEvent {}

/// {@template validate_form_event}
/// Событие для запуска валидации всей формы регистрации.
/// {@endtemplate}
class ValidateForm extends RegistrationEvent {}

/// {@template register_user_event}
/// Событие для выполнения регистрации пользователя после успешной валидации формы.
/// {@endtemplate}
class RegisterUser extends RegistrationEvent {}

/// {@template clear_errors_event}
/// Событие для очистки всех ошибок в форме регистрации.
/// {@endtemplate}
class ClearErrors extends RegistrationEvent {}