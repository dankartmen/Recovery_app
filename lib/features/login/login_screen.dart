import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/repositories/questionnaire_repository.dart';
import '../../services/auth_service.dart';
import '../../style.dart';
import '../register/register_screen.dart';

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
  bool _autoLoginAttempted =
      false; // Флаг для отслеживания автоматического входа

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

    // Если сервис еще не инициализирован - инициализируем
    if (!authService.isInitialized) {
      await authService.initialize();
      debugPrint('AuthService инициализирован');
    }

    // Если пользователь уже аутентифицирован - переходим на главный экран
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
    // Запускаем автоматический вход при инициализации экрана
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

    // Если идет автоматический вход, показываем индикатор
    if (authService.isLoading || _autoLoginAttempted) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: buildAppBar('Вход'),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (authService.errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: Text(
                    authService.errorMessage!,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              TextFormField(
                controller: _usernameController,
                decoration: const InputDecoration(
                  labelText: 'Имя пользователя',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Введите имя пользователя';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Пароль',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Введите пароль';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : () => _login(authService),
                  child:
                      _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text('Войти'),
                ),
              ),
              TextButton(
                onPressed:
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const RegisterScreen(),
                      ),
                    ),
                child: const Text('Ещё нет аккаунта? Зарегистрируйтесь'),
              ),
            ],
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
