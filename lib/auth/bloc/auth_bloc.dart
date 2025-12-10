import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import '../../core/services/auth_service.dart';

part 'auth_event.dart';
part 'auth_state.dart';

/// BLoC для управления процессом аутентификации пользователя
/// Обрабатывает вход в систему и управление состоянием авторизации
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthService authService;

  AuthBloc({required this.authService}) : super(AuthInitial()) {
    on<LoginEvent>(_onLogin); 
  }

  /// Обработка события входа в систему
  /// Принимает:
  /// - [event] - событие входа с данными пользователя
  /// - [emit] - функция для эмиттинга состояния
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