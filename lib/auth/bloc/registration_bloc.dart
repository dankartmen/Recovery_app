import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import '../../core/services/auth_service.dart';

part 'registration_event.dart';
part 'registration_state.dart';

/// {@template registration_bloc}
/// BLoC для управления процессом регистрации пользователя.
/// Обеспечивает валидацию данных, управление состоянием и обработку ошибок.
/// {@endtemplate}
class RegistrationBloc extends Bloc<RegistrationEvent, RegistrationState> {
  /// Сервис аутентификации для выполнения операций регистрации.
  final AuthService authService;

  /// {@macro registration_bloc}
  RegistrationBloc({required this.authService}) : super(RegistrationInitial()) {
    on<UpdateUsername>(_onUpdateUsername);
    on<UpdatePassword>(_onUpdatePassword);
    on<UpdateConfirmPassword>(_onUpdateConfirmPassword);
    on<TogglePasswordVisibility>(_onTogglePasswordVisibility);
    on<ToggleConfirmPasswordVisibility>(_onToggleConfirmPasswordVisibility);
    on<ClearErrors>(_onClearErrors);
    on<ValidateForm>(_onValidateForm);
    on<RegisterUser>(_onRegisterUser);
  }

  /// Метод для обработки обновления имени пользователя.
  /// Принимает:
  /// - [event] - событие с новым значением имени пользователя.
  /// - [emit] - функция для эмиттинга нового состояния.
  /// Выполняет валидацию имени пользователя и обновляет состояние.
  void _onUpdateUsername(UpdateUsername event, Emitter<RegistrationState> emit) {
    emit(state.copyWith(
      username: event.value,
      usernameError: _validateUsername(event.value),
    ));
  }

  /// Метод для обработки обновления пароля.
  /// Принимает:
  /// - [event] - событие с новым значением пароля.
  /// - [emit] - функция для эмиттинга нового состояния.
  /// Выполняет валидацию пароля и обновляет состояние.
  void _onUpdatePassword(UpdatePassword event, Emitter<RegistrationState> emit) {
    emit(state.copyWith(
      password: event.value,
      passwordError: _validatePassword(event.value),
    ));
  }

  /// Метод для обработки обновления подтверждения пароля.
  /// Принимает:
  /// - [event] - событие с новым значением подтверждения пароля.
  /// - [emit] - функция для эмиттинга нового состояния.
  /// Выполняет валидацию подтверждения пароля и обновляет состояние.
  void _onUpdateConfirmPassword(UpdateConfirmPassword event, Emitter<RegistrationState> emit) {
    emit(state.copyWith(
      confirmPassword: event.value,
      confirmPasswordError: _validateConfirmPassword(event.value, state.password),
    ));
  }

  /// Метод для переключения видимости пароля.
  /// Принимает:
  /// - [event] - событие переключения видимости пароля.
  /// - [emit] - функция для эмиттинга нового состояния.
  /// Переключает флаг видимости пароля.
  void _onTogglePasswordVisibility(TogglePasswordVisibility event, Emitter<RegistrationState> emit) {
    emit(state.copyWith(obscurePassword: !state.obscurePassword));
  }

  /// Метод для переключения видимости подтверждения пароля.
  /// Принимает:
  /// - [event] - событие переключения видимости подтверждения пароля.
  /// - [emit] - функция для эмиттинга нового состояния.
  /// Переключает флаг видимости подтверждения пароля.
  void _onToggleConfirmPasswordVisibility(ToggleConfirmPasswordVisibility event, Emitter<RegistrationState> emit) {
    emit(state.copyWith(obscureConfirmPassword: !state.obscureConfirmPassword));
  }

  /// Метод для очистки всех ошибок в форме.
  /// Принимает:
  /// - [event] - событие очистки ошибок.
  /// - [emit] - функция для эмиттинга нового состояния.
  /// Очищает все ошибки валидации и сообщения об ошибках.
  void _onClearErrors(ClearErrors event, Emitter<RegistrationState> emit) {
    emit(state.copyWith(
      usernameError: null,
      passwordError: null,
      confirmPasswordError: null,
      errorMessage: null,
    ));
  }

  /// Метод для валидации всей формы регистрации.
  /// Принимает:
  /// - [event] - событие валидации формы.
  /// - [emit] - функция для эмиттинга нового состояния.
  /// Возвращает:
  /// - Future<void> для асинхронной обработки.
  /// При успешной валидации запускает процесс регистрации.
  /// При наличии ошибок валидации обновляет состояние с сообщениями об ошибках.
  Future<void> _onValidateForm(ValidateForm event, Emitter<RegistrationState> emit) async {
    final usernameError = _validateUsername(state.username);
    final passwordError = _validatePassword(state.password);
    final confirmPasswordError = _validateConfirmPassword(state.confirmPassword, state.password);

    emit(state.copyWith(
      usernameError: usernameError,
      passwordError: passwordError,
      confirmPasswordError: confirmPasswordError,
    ));

    if (usernameError == null && passwordError == null && confirmPasswordError == null) {
      add(RegisterUser());
    }
  }

  /// Метод для выполнения регистрации пользователя.
  /// Принимает:
  /// - [event] - событие регистрации пользователя.
  /// - [emit] - функция для эмиттинга нового состояния.
  /// Возвращает:
  /// - Future<void> для асинхронной обработки.
  /// При успешной регистрации устанавливает [isSuccess] в true.
  /// При ошибке регистрации устанавливает [errorMessage] с описанием ошибки.
  Future<void> _onRegisterUser(RegisterUser event, Emitter<RegistrationState> emit) async {
    emit(state.copyWith(isLoading: true, errorMessage: null));

    try {
      await authService.register(state.username, state.password);
      emit(state.copyWith(isLoading: false, isSuccess: true));
    } catch (e) {
      emit(state.copyWith(isLoading: false, errorMessage: e.toString(), isSuccess: false));
    }
  }

  /// Метод для валидации имени пользователя.
  /// Принимает:
  /// - [value] - значение имени пользователя для валидации.
  /// Возвращает:
  /// - String? - сообщение об ошибке или null если валидация успешна.
  String? _validateUsername(String value) {
    if (value.isEmpty) return 'Введите имя пользователя';
    if (value.length < 3) return 'Имя пользователя должно быть не менее 3 символов';
    return null;
  }

  /// Метод для валидации пароля.
  /// Принимает:
  /// - [value] - значение пароля для валидации.
  /// Возвращает:
  /// - String? - сообщение об ошибке или null если валидация успешна.
  /// Проверяет:
  /// - минимальную длину (4 символа)
  /// - наличие заглавных букв
  /// - наличие строчных букв
  /// - наличие цифр
  /// - наличие специальных символов
  String? _validatePassword(String value) {
    if (value.isEmpty) return 'Введите пароль';
    if (value.length < 4) return 'Пароль должен быть не менее 4 символов';
    if (!RegExp(r'[A-Z]').hasMatch(value)) return 'Добавьте заглавную букву (A-Z)';
    if (!RegExp(r'[a-z]').hasMatch(value)) return 'Добавьте строчную букву (a-z)';
    if (!RegExp(r'[0-9]').hasMatch(value)) return 'Добавьте цифру (0-9)';
    if (!RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(value)) return 'Добавьте специальный символ';
    return null;
  }

  /// Метод для валидации подтверждения пароля.
  /// Принимает:
  /// - [value] - значение подтверждения пароля для валидации.
  /// - [password] - оригинальный пароль для сравнения.
  /// Возвращает:
  /// - String? - сообщение об ошибке или null если валидация успешна.
  /// Проверяет соответствие подтверждения пароля оригинальному паролю.
  String? _validateConfirmPassword(String value, String password) {
    final passwordError = _validatePassword(value);
    if (passwordError != null) return passwordError;
    if (value != password) return 'Пароли не совпадают';
    return null;
  }
}