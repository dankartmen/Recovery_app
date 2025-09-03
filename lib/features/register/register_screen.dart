import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/models/exercise_list_model.dart';
import '../../data/models/history_model.dart';
import '../../data/models/training_calendar_model.dart';
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
  /// Ключ для валидации формы регистрации
  final _formKey = GlobalKey<FormState>();

  /// Контроллер для поля ввода имени пользователя
  final _usernameController = TextEditingController();

  /// Контроллер для поля ввода пароля
  final _passwordController = TextEditingController();

  /// Контроллер для поля подтверждения пароля
  final _confirmPasswordController = TextEditingController();

  /// Флаг состояния загрузки при регистрации
  bool _isLoading = false;

  /// Флаг отображения/скрытия пароля
  bool _obscurePassword = true;

  /// Флаг отображения/скрытия подтверждения пароля
  bool _obscureConfirmPassword = true;

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);

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
                        key: _formKey,
                        child: Column(
                          children: [
                            if (authService.errorMessage != null)
                              Container(
                                padding: const EdgeInsets.all(12),
                                margin: const EdgeInsets.only(bottom: 20),
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
                                        authService.errorMessage!,
                                        style: const TextStyle(
                                          color: Colors.red,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

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

                            // Подтверждение пароля
                            TextFormField(
                              controller: _confirmPasswordController,
                              obscureText: _obscureConfirmPassword,
                              decoration: buildHealthInputDecoration(
                                'Подтвердите пароль',
                                icon: Icons.lock_reset,
                              ).copyWith(
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscureConfirmPassword
                                        ? Icons.visibility_off
                                        : Icons.visibility,
                                    color: healthSecondaryColor,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _obscureConfirmPassword =
                                          !_obscureConfirmPassword;
                                    });
                                  },
                                ),
                              ),
                              validator: (value) {
                                if (value != _passwordController.text) {
                                  return 'Пароли не совпадают';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 30),

                            // Кнопка регистрации
                            SizedBox(
                              width: double.infinity,
                              height: 50,
                              child: ElevatedButton(
                                onPressed:
                                    _isLoading ? null : () => _register(),
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
                                          'Зарегистрироваться',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                              ),
                            ),
                            const SizedBox(height: 24),

                            // Ссылка на вход
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Уже есть аккаунт? ',
                                  style: TextStyle(
                                    color: healthSecondaryTextColor,
                                  ),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text(
                                    'Войти',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: healthPrimaryColor,
                                    ),
                                  ),
                                ),
                              ],
                            ),
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

  /// Обработка регистрации пользователя
  /// Выполняет валидацию формы, отправку данных на сервер и инициализацию данных пользователя
  /// Выбрасывает исключение:
  /// - при ошибках сети, сервера или валидации данных
  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final user = await authService.register(
        _usernameController.text,
        _passwordController.text,
      );

      if (user != null) {
        // Загружаем анкету пользователя
        final questionnaire = await authService.fetchQuestionnaire();
        if (!mounted) return;

        if (questionnaire != null) {
          // Инициализируем календарь тренировок
          final calendarModel = Provider.of<TrainingCalendarModel>(
            context,
            listen: false,
          );
          final historyModel = Provider.of<HistoryModel>(
            context,
            listen: false,
          );
          final exerciseListModel = Provider.of<ExerciseListModel>(
            context,
            listen: false,
          );

          calendarModel.initialize(
            authService,
            historyModel,
            exerciseListModel,
          );
          await calendarModel.generateAndSaveSchedule(questionnaire);
          if (!mounted) return;
        }

        // После успешной регистрации можно перейти на нужный экран
        Navigator.pushReplacementNamed(
          context,
          '/home',
          arguments: questionnaire,
        );
      }
    } catch (e) {
      // Обработка ошибок
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Ошибка регистрации: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}
