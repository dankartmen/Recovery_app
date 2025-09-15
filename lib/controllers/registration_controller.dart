import 'package:auth_test/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/models/exercise_list_model.dart';
import '../data/models/history_model.dart';
import '../data/models/training_calendar_model.dart';

class RegistrationController with ChangeNotifier{
  final AuthService _authService;
  bool isLoading = false;
  String? errorMassage;

  RegistrationController(this._authService);

  /// Обработка регистрации пользователя
  /// Выполняет валидацию формы, отправку данных на сервер и инициализацию данных пользователя
  /// Выбрасывает исключение:
  /// - при ошибках сети, сервера или валидации данных
  Future<void> register(String username, String password, BuildContext context) async {
    isLoading = true;
    errorMassage = null;
    try {
      final user = await _authService.register(
        username,password
      );

      if (user != null) {
        // Загружаем анкету пользователя
        final questionnaire = await _authService.fetchQuestionnaire();
        if (!context.mounted) return;

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
            _authService,
            historyModel,
            exerciseListModel,
          );
          await calendarModel.generateAndSaveSchedule(questionnaire);
          if (!context.mounted) return;

          // После успешной регистрации можно перейти на нужный экран
          Navigator.pushReplacementNamed(
            context,
            '/home',
            arguments: questionnaire,
          );
        } else {
          // Если анкета не найдена, переходим на экран заполнения анкеты
          Navigator.pushReplacementNamed(context, '/questionnaire');
        }
      }
    } catch (e) {
      // Обработка ошибок
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Ошибка регистрации: $e')));
    } finally {
      isLoading = false;
      errorMassage = null;
      notifyListeners();
    }
  }
  void cleanError(){
    errorMassage = null;
    notifyListeners();
  }
}