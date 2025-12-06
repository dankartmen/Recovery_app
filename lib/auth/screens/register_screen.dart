import 'package:auth_test/auth/bloc/registration_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';

import '../../services/auth_service.dart';
import '../../styles/style.dart';

/// {@template register_screen}
/// Экран регистрации нового пользователя.
/// Предоставляет форму для создания учетной записи с валидацией данных.
/// {@endtemplate}
class RegisterScreen extends StatefulWidget {
  /// {@macro register_screen}
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  /// 
  final _formKey = GlobalKey<FormState>(); 

  /// Контроллер для поля ввода имени пользователя
  final _usernameController = TextEditingController();

  /// Контроллер для поля ввода пароля
  final _passwordController = TextEditingController();

  /// Контроллер для поля подтверждения пароля
  final _confirmPasswordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _usernameController.addListener(() {
      context.read<RegistrationBloc>().add(UpdateUsername(_usernameController.text));
    });
    _passwordController.addListener((){
      context.read<RegistrationBloc>().add(UpdatePassword(_passwordController.text));
    });
    _confirmPasswordController.addListener(() {
      context.read<RegistrationBloc>().add(UpdateConfirmPassword(_confirmPasswordController.text));
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<RegistrationBloc, RegistrationState>(
      listener: (context, state) {
        if (state.isSuccess) {
          final authService = RepositoryProvider.of<AuthService>(context); // Или Provider.of
          authService.handlePostLoginNavigation(context); 
        }
      },
      child: BlocBuilder<RegistrationBloc, RegistrationState>(
        builder: (context, state) {
          return Scaffold(
            appBar: buildAppBar('Регистрация'),
            body: Container(
              color: healthBackgroundColor,
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Center(
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Логотип и заголовок
                        const Icon(
                          Icons.health_and_safety,
                          size: 64,
                          color: healthPrimaryColor,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Создайте аккаунт',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: healthTextColor,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Начните путь к восстановлению',
                          style: TextStyle(
                            fontSize: 16,
                            color: healthSecondaryTextColor,
                          ),
                        ),
                        const SizedBox(height: 32),

                        // Карточка с формой
                        Card(
                          elevation: 4,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Form(
                              child: Column(
                                children: [
                                  // Поле имени пользователя
                                  TextFormField(
                                    controller: _usernameController,
                                    decoration: buildHealthInputDecoration(
                                      'Имя пользователя',
                                      state.usernameError,
                                      icon: Icons.person_outline,
                                    ),
                                  ),
                                  const SizedBox(height: 20),

                                  // Поле пароля
                                  TextFormField(
                                    controller: _passwordController,
                                    obscureText: state.obscurePassword,
                                    decoration: buildHealthInputDecoration(
                                      'Пароль',
                                      state.passwordError,
                                      icon: Icons.lock_outline,
                                    ).copyWith(
                                      suffixIcon: IconButton(
                                        icon: Icon(
                                          state.obscurePassword
                                              ? Icons.visibility_off
                                              : Icons.visibility,
                                          color: healthSecondaryColor,
                                        ),
                                        onPressed: () => context.read<RegistrationBloc>().add(TogglePasswordVisibility()),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 20),

                                  // Подтверждение пароля
                                  TextFormField(
                                    controller: _confirmPasswordController,
                                    obscureText: state.obscureConfirmPassword,
                                    decoration: buildHealthInputDecoration(
                                      'Подтвердите пароль',
                                      state.confirmPasswordError,
                                      icon: Icons.lock_reset,
                                    ).copyWith(
                                      suffixIcon: IconButton(
                                        icon: Icon(
                                          state.obscureConfirmPassword
                                              ? Icons.visibility_off
                                              : Icons.visibility,
                                          color: healthSecondaryColor,
                                        ),
                                        onPressed: () => context.read<RegistrationBloc>().add(TogglePasswordVisibility()),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 30),

                                  // Кнопка регистрации
                                  SizedBox(
                                    width: double.infinity,
                                    height: 50,
                                    child: ElevatedButton(
                                      onPressed:
                                          state.isLoading ? null : () async { 
                                            final success = await state.register(_usernameController.text, _passwordController.text, _confirmPasswordController.text);
                                            if (success && context.mounted){
                                              Navigator.pushReplacementNamed(context, '/questionnaire');
                                            }
                                          },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: healthPrimaryColor,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 14,
                                        ),
                                      ),
                                      child:
                                          state.isLoading
                                              ? const CircularProgressIndicator(
                                                color: Colors.white,
                                                strokeWidth: 3,
                                              )
                                              : const Text(
                                                'Зарегистрироваться',
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.white,
                                                ),
                                              ),
                                    ),
                                  ),
                                  if(state.errorMessage != null)
                                    Text(state.errorMessage!, style: TextStyle(color: Colors.red),)

                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        }
      )
    );
  }
}
