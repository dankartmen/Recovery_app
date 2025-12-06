part of 'registration_bloc.dart';

class RegistrationState extends Equatable {
  final String username;
  final String password;
  final String confirmPassword;
  final bool obscurePassword;
  final bool obscureConfirmPassword;
  final String? usernameError;
  final String? passwordError;
  final String? confirmPasswordError;
  final String? errorMessage;
  final bool isLoading;
  final bool isSuccess;

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

class RegistrationInitial extends RegistrationState {}