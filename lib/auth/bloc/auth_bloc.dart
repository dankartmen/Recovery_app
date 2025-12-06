import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';  // Для сравнения состояний/events
import 'package:flutter/material.dart';
import '../../services/auth_service.dart';

// Events
part 'auth_event.dart';

// States
part 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthService authService;

  AuthBloc({required this.authService}) : super(AuthInitial()) {
    on<LoginEvent>(_onLogin);  // Регистрация обработчика
  }

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