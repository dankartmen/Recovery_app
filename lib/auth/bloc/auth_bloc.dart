import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import '../../core/services/auth_service.dart';

part 'auth_event.dart';
part 'auth_state.dart';

/// {@template auth_bloc}
/// BLoC для управления процессом аутентификации пользователя.
/// Обрабатывает вход в систему и управление состоянием авторизации.
/// {@endtemplate}
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  /// Сервис аутентификации для выполнения операций входа.
  final AuthService authService;

  /// {@macro auth_bloc}
  AuthBloc({required this.authService}) : super(AuthInitial()) {
    on<LoginEvent>(_onLogin); 
  }

  /// Метод для обработки события входа в систему.
  /// Принимает:
  /// - [event] - событие входа с данными пользователя.
  /// - [emit] - функция для эмиттинга нового состояния.
  /// Возвращает:
  /// При успешной аутентификации эмитит [AuthSuccess].
  /// При ошибке аутентификации эмитит [AuthError] с сообщением об ошибке.
  Future<void> _onLogin(LoginEvent event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      await authService.login(event.username, event.password);
      emit(AuthSuccess());
    } catch (e) {
      emit(AuthError(errorMessage: e.toString()));
    }
  }
}