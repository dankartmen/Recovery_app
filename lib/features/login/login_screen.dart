import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/repositories/questionnaire_repository.dart';
import '../../services/auth_service.dart';
import '../../styles/style.dart';
import '../register/register_screen.dart';
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
  bool _isLoading = false;
  bool _autoLoginAttempted = false;
  bool _obscurePassword = true;

  Future<void> _navigateAfterLogin(AuthService authService) async {
    final questionnaireRepo = Provider.of<QuestionnaireRepository>(
      context,
      listen: false,
    );
    final questionnaire = await authService.fetchQuestionnaire();

    if (questionnaire != null) {
      await questionnaireRepo.saveQuestionnaire(questionnaire);
      Navigator.pushReplacementNamed(
        context,
        '/home',
        arguments: questionnaire,
      );
    } else {
      Navigator.pushReplacementNamed(context, '/questionnaire');
    }
  }

  Future<void> _attemptAutoLogin() async {
    final authService = Provider.of<AuthService>(context, listen: false);

    if (!authService.isInitialized) {
      await authService.initialize();
      debugPrint('AuthService инициализирован');
    }

    if (authService.currentUser != null && !_autoLoginAttempted) {
      debugPrint('Автоматический вход: ${authService.currentUser?.username}');
      setState(() => _autoLoginAttempted = true);
      await _navigateAfterLogin(authService);
    } else {
      debugPrint('Автоматический вход не выполнен');
    }
  }

  @override
  void initState() {
    super.initState();
    _attemptAutoLogin();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);

    if (authService.isLoading || _autoLoginAttempted) {
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

                            // Сообщение об ошибке
                            if (authService.errorMessage != null)
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.red.shade50,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Column(
                                  children: [
                                    Row(
                                      children: [
                                        const Icon(
                                          Icons.error,
                                          color: Colors.red,
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Text(
                                            authService.errorMessage!,
                                            style: const TextStyle(
                                              color: Colors.red,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    if (authService.errorMessage!.contains(
                                      'пароль',
                                    ))
                                      const SizedBox(height: 8),
                                    const Text(
                                      'Проверьте требования к паролю',
                                      style: TextStyle(
                                        color: Colors.red,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            if (authService.errorMessage != null)
                              const SizedBox(height: 16),

                            // Поле имени пользователя
                            TextFormField(
                              controller: _usernameController,
                              decoration: buildHealthInputDecoration(
                                'Имя пользователя',
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
                                    _isLoading
                                        ? null
                                        : () => _login(authService),
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
                                    _isLoading
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

  Future<void> _login(AuthService authService) async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await authService.login(
        _usernameController.text,
        _passwordController.text,
      );
      await _navigateAfterLogin(authService);
    } finally {
      setState(() => _isLoading = false);
    }
  }
}
