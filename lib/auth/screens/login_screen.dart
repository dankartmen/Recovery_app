import 'package:flutter_bloc/flutter_bloc.dart';

import '../../controllers/login_controller.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../core/styles/style.dart';
import 'register_screen.dart';
import '../bloc/auth_bloc.dart';
import 'forgot_password_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(  // Для навигации/эффектов
      listener: (context, state) {
        if (state is AuthSuccess) {
          final authService = Provider.of<AuthService>(context, listen: false);
          authService.handlePostLoginNavigation(context);
        }
      },
      child: BlocBuilder<AuthBloc, AuthState>(  // Для UI
        builder: (context, state) {
          bool isLoading = state is AuthLoading;
          String? error = state is AuthError ? state.errorMessage : null;

          if (isLoading) {
            return Scaffold(
              body: Container(
                decoration: const BoxDecoration(color: healthBackgroundColor),
                child: const Center(
                  child: CircularProgressIndicator(color: healthPrimaryColor),
                ),
              ),
            );
          }

          return Scaffold(
            body: Container(
              decoration: const BoxDecoration(color: healthBackgroundColor),
              child: SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: MediaQuery.of(context).size.height,
                  ),
                  child: Column(
                    children: [
                      const SizedBox(height: 80),
                      // Логотип и заголовок
                      const Icon(
                        Icons.health_and_safety,
                        size: 80,
                        color: healthPrimaryColor,
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Восстановление начинается здесь',
                        style: TextStyle(
                          color: healthTextColor,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 40),

                      // Карточка с формой
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Card(
                          elevation: 4,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          color: Colors.white,
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Form(
                              key: _formKey,
                              child: Column(
                                children: [
                                  const Text(
                                    'Вход в систему',
                                    style: TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                      color: healthTextColor,
                                    ),
                                  ),
                                  const SizedBox(height: 24),

                                  // Поле имени пользователя
                                  TextFormField(
                                    controller: _usernameController,
                                    decoration: buildHealthInputDecoration(
                                      'Имя пользователя',
                                      null,
                                      icon: Icons.person_outline,
                                    ),
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Введите имя пользователя';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 20),

                                  // Поле пароля
                                  TextFormField(
                                    controller: _passwordController,
                                    obscureText: _obscurePassword,
                                    decoration: buildHealthInputDecoration(
                                      'Пароль',
                                      null,
                                      icon: Icons.lock_outline,
                                    ).copyWith(
                                      suffixIcon: IconButton(
                                        icon: Icon(
                                          _obscurePassword
                                              ? Icons.visibility_off
                                              : Icons.visibility,
                                          color: healthSecondaryColor,
                                        ),
                                        onPressed: () {
                                          setState(() {
                                            _obscurePassword = !_obscurePassword;
                                          });
                                        },
                                      ),
                                    ),
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Введите пароль';
                                      }
                                      return null;
                                    },
                                  ),

                                  if (error != null)
                                    Text(error, style: TextStyle(color: Colors.red),),

                                  const SizedBox(height: 16),

                                  // Кнопка "Забыли пароль?"
                                  TextButton(
                                    onPressed:
                                        () => Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder:
                                                (context) =>
                                                    const ForgotPasswordScreen(),
                                          ),
                                        ),
                                    child: const Text(
                                      'Забыли пароль?',
                                      style: TextStyle(color: healthSecondaryColor),
                                    ),
                                  ),
                                  const SizedBox(height: 24),

                                  // Кнопка входа
                                  SizedBox(
                                    width: double.infinity,
                                    height: 50,
                                    child: ElevatedButton(
                                      onPressed:
                                          isLoading
                                              ? null
                                              : ()  {
                                                  if (_formKey.currentState!
                                                      .validate()) {
                                                    // Отправка события входа в Bloc
                                                    BlocProvider.of<AuthBloc>(context).add(
                                                      LoginEvent(
                                                        username: _usernameController.text,
                                                        password: _passwordController.text,
                                                      ),
                                                    );
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
                                          isLoading
                                              ? const CircularProgressIndicator(
                                                color: Colors.white,
                                                strokeWidth: 3,
                                              )
                                              : const Text(
                                                'Войти',
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                  color:
                                                      Colors
                                                          .white, // Белый текст для контраста
                                                ),
                                              ),
                                    ),
                                  ),
                                  const SizedBox(height: 24),

                                  // Разделитель
                                  Row(
                                    children: const [
                                      Expanded(
                                        child: Divider(color: healthDividerColor),
                                      ),
                                      Padding(
                                        padding: EdgeInsets.symmetric(horizontal: 12),
                                        child: Text(
                                          'ИЛИ',
                                          style: TextStyle(
                                            color: healthSecondaryColor,
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        child: Divider(color: healthDividerColor),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 24),

                                  // Кнопка регистрации
                                  OutlinedButton(
                                    onPressed:
                                        () => Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder:
                                                (context) => const RegisterScreen(),
                                          ),
                                        ),
                                    style: OutlinedButton.styleFrom(
                                      side: const BorderSide(
                                        color: healthPrimaryColor,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 14,
                                        horizontal: 24,
                                      ),
                                    ),
                                    child: const Text(
                                      'Создать аккаунт',
                                      style: TextStyle(
                                        color: healthPrimaryColor,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 40),
                    ],
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
