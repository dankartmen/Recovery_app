part of 'registration_bloc.dart';

/// {@template registration_state}
/// Состояние процесса регистрации пользователя.
/// {@endtemplate}
class RegistrationState extends Equatable {
  /// Текущее значение имени пользователя в форме.
  final String username;

  /// Текущее значение пароля в форме.
  final String password;

  /// Текущее значение подтверждения пароля в форме.
  /// Должно совпадать с [password].
  final String confirmPassword;

  /// Флаг видимости пароля в поле ввода.
  /// Когда true - пароль скрыт, когда false - пароль отображается.
  final bool obscurePassword;

  /// Флаг видимости подтверждения пароля в поле ввода.
  /// Когда true - пароль скрыт, когда false - пароль отображается.
  final bool obscureConfirmPassword;

  /// Ошибка валидации имени пользователя.
  /// null если ошибки нет.
  final String? usernameError;

  /// Ошибка валидации пароля.
  /// null если ошибки нет.
  final String? passwordError;

  /// Ошибка валидации подтверждения пароля.
  /// null если ошибки нет.
  final String? confirmPasswordError;

  /// Общее сообщение об ошибке регистрации.
  /// null если ошибки нет.
  final String? errorMessage;

  /// Флаг загрузки при выполнении регистрации.
  /// true когда регистрация выполняется.
  final bool isLoading;

  /// Флаг успешного завершения регистрации.
  /// true когда регистрация завершена успешно.
  final bool isSuccess;

  /// {@macro registration_state}
  const RegistrationState({
    this.username = '',
    this.password = '',
    this.confirmPassword = '',
    this.obscurePassword = true,
    this.obscureConfirmPassword = true,
    this.usernameError,
    this.passwordError,
    this.confirmPasswordError,
    this.errorMessage,
    this.isLoading = false,
    this.isSuccess = false,
  });

  /// Метод для создания копии состояния с обновленными значениями.
  RegistrationState copyWith({
    String? username,
    String? password,
    String? confirmPassword,
    bool? obscurePassword,
    bool? obscureConfirmPassword,
    String? usernameError,
    String? passwordError,
    String? confirmPasswordError,
    String? errorMessage,
    bool? isLoading,
    bool? isSuccess,
  }) {
    return RegistrationState(
      username: username ?? this.username,
      password: password ?? this.password,
      confirmPassword: confirmPassword ?? this.confirmPassword,
      obscurePassword: obscurePassword ?? this.obscurePassword,
      obscureConfirmPassword: obscureConfirmPassword ?? this.obscureConfirmPassword,
      usernameError: usernameError,
      passwordError: passwordError,
      confirmPasswordError: confirmPasswordError,
      errorMessage: errorMessage,
      isLoading: isLoading ?? this.isLoading,
      isSuccess: isSuccess ?? this.isSuccess,
    );
  }

  @override
  List<Object?> get props => [
        username,
        password,
        confirmPassword,
        obscurePassword,
        obscureConfirmPassword,
        usernameError,
        passwordError,
        confirmPasswordError,
        errorMessage,
        isLoading,
        isSuccess,
      ];
}

/// {@template registration_initial}
/// Начальное состояние процесса регистрации.
/// Используется при инициализации или сбросе состояния.
/// {@endtemplate}
class RegistrationInitial extends RegistrationState {}