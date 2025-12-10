import 'package:auth_test/auth/bloc/auth_bloc.dart';
import 'package:auth_test/core/services/auth_service.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_test/flutter_test.dart';

class MockAuthService extends Mock implements AuthService {}

void main() {  // Добавьте это!
  late MockAuthService mockAuthService;

  setUp(() {
    mockAuthService = MockAuthService();
    registerFallbackValue('');  // Для any() в mocktail
  });

  group('AuthBloc', () {
    blocTest<AuthBloc, AuthState>(
      'emits [AuthLoading, AuthSuccess] when login succeeds',
      build: () => AuthBloc(authService: mockAuthService),
      setUp: () {
        when(() => mockAuthService.login(any(), any())).thenAnswer((_) async {});
      },
      act: (bloc) => bloc.add(const LoginEvent(username: 'test', password: 'test')),
      expect: () => [AuthLoading(), AuthSuccess()],
      verify: (_) {
        verify(() => mockAuthService.login('test', 'test')).called(1);
      },
    );

    blocTest<AuthBloc, AuthState>(
      'emits [AuthLoading, AuthError] when login fails',
      build: () => AuthBloc(authService: mockAuthService),
      setUp: () {
        when(() => mockAuthService.login(any(), any())).thenThrow(Exception('Invalid credentials'));
      },
      act: (bloc) => bloc.add(const LoginEvent(username: 'test', password: 'wrong')),
      expect: () => [
        AuthLoading(),
        isA<AuthError>().having((e) => e.errorMessage, 'errorMessage', contains('Invalid credentials')),
      ],
    );
  });
}