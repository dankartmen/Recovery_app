import 'package:flutter/material.dart';
import 'reset_password_screen.dart';
import '../../styles/style.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _usernameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Восстановление пароля',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: healthPrimaryColor,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: Container(
        decoration: const BoxDecoration(color: healthBackgroundColor),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 30),
              // Иконка и заголовок
              Center(
                child: Icon(
                  Icons.lock_reset,
                  size: 80,
                  color: healthPrimaryColor.withValues(alpha: 0.8),
                ),
              ),
              const SizedBox(height: 20),
              const Center(
                child: Text(
                  'Восстановление доступа',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: healthTextColor,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Center(
                child: Text(
                  'Введите ваше имя пользователя, чтобы установить новый пароль',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: healthSecondaryTextColor,
                    height: 1.5,
                  ),
                ),
              ),
              const SizedBox(height: 40),

              // Карточка с формой
              Card(
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
                        const SizedBox(height: 30),

                        // Кнопка продолжения
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _submit,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: healthPrimaryColor,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            child:
                                _isLoading
                                    ? const CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 3,
                                    )
                                    : const Text(
                                      'Продолжить',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 30),

              // Кнопка возврата к входу
              Center(
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    'Вернуться ко входу',
                    style: TextStyle(
                      color: healthPrimaryColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    await Future.delayed(const Duration(milliseconds: 500));

    final username = _usernameController.text;

    if (!mounted) return;

    // Переходим сразу на экран установки нового пароля
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ResetPasswordScreen(username: username),
      ),
    );

    setState(() => _isLoading = false);
  }
}
