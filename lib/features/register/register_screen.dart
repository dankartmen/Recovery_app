import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../controllers/registration_controller.dart';
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
  /// Ключ для валидации формы регистрации

  /// Контроллер для поля ввода имени пользователя
  final _usernameController = TextEditingController();

  /// Контроллер для поля ввода пароля
  final _passwordController = TextEditingController();

  /// Контроллер для поля подтверждения пароля
  final _confirmPasswordController = TextEditingController();


  @override
  Widget build(BuildContext context) {
    final registrationController = Provider.of<RegistrationController>(context);
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
                                registrationController.usernameError,
                                icon: Icons.person_outline,
                              ),
                              onChanged: (value) => registrationController.clearErrors(),
                            ),
                            const SizedBox(height: 20),

                            // Поле пароля
                            TextFormField(
                              controller: _passwordController,
                              obscureText: registrationController.obscurePassword,
                              decoration: buildHealthInputDecoration(
                                'Пароль',
                                registrationController.passwordError,
                                icon: Icons.lock_outline,
                              ).copyWith(
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    registrationController.obscurePassword
                                        ? Icons.visibility_off
                                        : Icons.visibility,
                                    color: healthSecondaryColor,
                                  ),
                                  onPressed: () => registrationController.togglePasswordVisibility()
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),

                            // Подтверждение пароля
                            TextFormField(
                              controller: _confirmPasswordController,
                              obscureText: registrationController.obscureConfirmPassword,
                              decoration: buildHealthInputDecoration(
                                'Подтвердите пароль',
                                registrationController.confirmPasswordError,
                                icon: Icons.lock_reset,
                              ).copyWith(
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    registrationController.obscureConfirmPassword
                                        ? Icons.visibility_off
                                        : Icons.visibility,
                                    color: healthSecondaryColor,
                                  ),
                                  onPressed: () => registrationController.toggleConfirmPasswordVisibility()
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
                                    registrationController.isLoading ? null : () async { 
                                      final success = await registrationController.register(_usernameController.text, _passwordController.text, _confirmPasswordController.text);
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
                                    registrationController.isLoading
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
                            if(registrationController.errorMassage != null)
                              Text(registrationController.errorMassage!, style: TextStyle(color: Colors.red),)

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
}
