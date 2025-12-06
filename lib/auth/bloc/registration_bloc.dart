import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../services/auth_service.dart';

part 'registration_event.dart';
part 'registration_state.dart';

class RegistrationBloc extends Bloc<RegistrationEvent, RegistrationState> {
  final AuthService authService;

  RegistrationBloc({required this.authService}) : super(RegistrationInitial()) {
    on<UpdateUsername>(_onUpdateUsername);
    on<UpdatePassword>(_onUpdatePassword);
    on<UpdateConfirmPassword>(_onUpdateConfirmPassword);
    on<TogglePasswordVisibility>(_onTogglePasswordVisibility);
    on<ToggleConfirmPasswordVisibility>(_onToggleConfirmPasswordVisibility);
    on<ValidateForm>(_onValidateForm);
    on<RegisterUser>(_onRegisterUser);
    on<ClearErrors>(_onClearErrors);
  }

  void _onUpdateUsername(UpdateUsername event, Emitter<RegistrationState> emit) {
    emit(state.copyWith(
      username: event.value,
      usernameError: _validateUsername(event.value),
    ));
  }

  void _onUpdatePassword(UpdatePassword event, Emitter<RegistrationState> emit) {
    emit(state.copyWith(
      password: event.value,
      passwordError: _validatePassword(event.value),
    ));
  }

  void _onUpdateConfirmPassword(UpdateConfirmPassword event, Emitter<RegistrationState> emit) {
    emit(state.copyWith(
      confirmPassword: event.value,
      confirmPasswordError: _validateConfirmPassword(event.value, state.password),
    ));
  }

  void _onTogglePasswordVisibility(TogglePasswordVisibility event, Emitter<RegistrationState> emit) {
    emit(state.copyWith(obscurePassword: !state.obscurePassword));
  }

  void _onToggleConfirmPasswordVisibility(ToggleConfirmPasswordVisibility event, Emitter<RegistrationState> emit) {
    emit(state.copyWith(obscureConfirmPassword: !state.obscureConfirmPassword));
  }

  void _onClearErrors(ClearErrors event, Emitter<RegistrationState> emit) {
    emit(state.copyWith(
      usernameError: null,
      passwordError: null,
      confirmPasswordError: null,
      errorMessage: null,
    ));
  }

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
      add(RegisterUser()); // Автоматически регистрируем, если валидно
    }
  }

  Future<void> _onRegisterUser(RegisterUser event, Emitter<RegistrationState> emit) async {
    emit(state.copyWith(isLoading: true, errorMessage: null));

    try {
      await authService.register(state.username, state.password);
      emit(state.copyWith(isLoading: false, isSuccess: true));
    } catch (e) {
      emit(state.copyWith(isLoading: false, errorMessage: e.toString(), isSuccess: false));
    }
  }

  // Валидационные методы (перенесены из контроллера)
  String? _validateUsername(String value) {
    if (value.isEmpty) return 'Введите имя пользователя';
    if (value.length < 3) return 'Имя пользователя должно быть не менее 3 символов';
    return null;
  }

  String? _validatePassword(String value) {
    if (value.isEmpty) return 'Введите пароль';
    if (value.length < 4) return 'Пароль должен быть не менее 4 символов';
    if (!RegExp(r'[A-Z]').hasMatch(value)) return 'Добавьте заглавную букву (A-Z)';
    if (!RegExp(r'[a-z]').hasMatch(value)) return 'Добавьте строчную букву (a-z)';
    if (!RegExp(r'[0-9]').hasMatch(value)) return 'Добавьте цифру (0-9)';
    if (!RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(value)) return 'Добавьте специальный символ';
    return null;
  }

  String? _validateConfirmPassword(String value, String password) {
    final passwordError = _validatePassword(value);
    if (passwordError != null) return passwordError;
    if (value != password) return 'Пароли не совпадают';
    return null;
  }
}