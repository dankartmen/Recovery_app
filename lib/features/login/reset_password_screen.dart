import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../styles/style.dart';

class ResetPasswordScreen extends StatefulWidget {
  final String username;

  const ResetPasswordScreen({super.key, required this.username});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  String? _errorMessage;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Установка нового пароля',
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
                  Icons.lock_open,
                  size: 80,
                  color: healthPrimaryColor.withValues(alpha: 0.8),
                ),
              ),
              const SizedBox(height: 20),
              const Center(
                child: Text(
                  'Создайте новый пароль',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: healthTextColor,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: Text(
                  'Для пользователя: ${widget.username}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
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
                        // Поле нового пароля
                        TextFormField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          decoration: buildHealthInputDecoration(
                            'Новый пароль',
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
                              return 'Введите новый пароль';
                            }
                            if (value.length < 8) {
                              return 'Пароль должен быть не менее 8 символов';
                            }
                            if (!value.contains(RegExp(r'[A-Z]'))) {
                              return 'Добавьте заглавную букву (A-Z)';
                            }
                            if (!value.contains(RegExp(r'[a-z]'))) {
                              return 'Добавьте строчную букву (a-z)';
                            }
                            if (!value.contains(RegExp(r'[0-9]'))) {
                              return 'Добавьте цифру (0-9)';
                            }
                            if (!value.contains(
                              RegExp(r'[!@#$%^&*(),.?":{}|<>]'),
                            )) {
                              return 'Добавьте специальный символ';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),

                        // Поле подтверждения пароля
                        TextFormField(
                          controller: _confirmController,
                          obscureText: _obscureConfirm,
                          decoration: buildHealthInputDecoration(
                            'Подтвердите пароль',
                            icon: Icons.lock_reset,
                          ).copyWith(
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscureConfirm
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                                color: healthSecondaryColor,
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscureConfirm = !_obscureConfirm;
                                });
                              },
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Подтвердите пароль';
                            }
                            if (value != _passwordController.text) {
                              return 'Пароли не совпадают';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),

                        // Сообщение об ошибке
                        if (_errorMessage != null)
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.red.shade50,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.error, color: Colors.red),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    _errorMessage!,
                                    style: const TextStyle(color: Colors.red),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        if (_errorMessage != null) const SizedBox(height: 16),

                        // Кнопка сброса пароля
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _resetPassword,
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
                                      'Установить пароль',
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

              // Подсказка о требованиях к паролю
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: healthPrimaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info, color: healthPrimaryColor, size: 20),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        '• Не менее 8 символов\n'
                        '• Заглавную букву (A-Z)\n'
                        '• Строчную букву (a-z)\n'
                        '• Цифру (0-9)\n'
                        '• Специальный символ',
                        style: TextStyle(
                          color: healthSecondaryTextColor,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _resetPassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final authService = Provider.of<AuthService>(context, listen: false);

    try {
      await authService.resetPassword(
        widget.username,
        _passwordController.text,
      );
      if (!mounted) return;

      // Возвращаемся на экран входа
      Navigator.popUntil(context, (route) => route.isFirst);

      // Показываем уведомление об успехе
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Пароль успешно изменен!'),
          backgroundColor: healthPrimaryColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    } catch (e) {
      setState(() => _errorMessage = 'Ошибка: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}
