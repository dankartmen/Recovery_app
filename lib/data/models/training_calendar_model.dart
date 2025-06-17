import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:path/path.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../services/auth_service.dart';
import '../../services/exercise_service.dart';
import '../repositories/history_repository.dart';
import 'exercise_history.dart';
import 'models.dart';
import 'training.dart';
import 'training_schedule.dart';

class TrainingCalendarModel extends ChangeNotifier {
  final AuthService authService;
  final HistoryRepository _historyRepository;
  List<ExerciseHistory> _history = [];

  TrainingCalendarModel(this.authService, this._historyRepository) {
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    _history = await _historyRepository.getAllHistory();
    notifyListeners();
  }

  bool isTrainingCompleted(Training training) {
    return _history.any(
      (h) =>
          h.exerciseName == training.title &&
          isSameDay(h.dateTime, training.date),
    );
  }

  void refreshTrainingStatus() {
    _loadHistory();
    notifyListeners(); // Уведомляем о необходимости перерисовки
  }

  void refresh() {
    notifyListeners();
  }

  Future<void> generateAndSaveSchedule(RecoveryData data) async {
    try {
      final exerciseService = ExerciseService(authService: authService);
      final exercises = await exerciseService.getExercises(
        injuryType: data.specificInjury,
      );

      final scheduleBox = await Hive.openBox<TrainingSchedule>(
        'training_schedule',
      );

      // Генерация расписания (адаптированный код из TrainingCalendarScreen)
      final schedule = <DateTime, List<Training>>{};
      DateTime currentDate = DateTime.now();
      final endDate = currentDate.add(const Duration(days: 84));
      currentDate = DateTime(
        currentDate.year,
        currentDate.month,
        currentDate.day,
      );
      while (currentDate.isBefore(endDate)) {
        final dayTrainings = <Training>[];

        for (final exercise in exercises) {
          final frequency = _getExerciseFrequency(exercise.title);
          if (_shouldAddTraining(currentDate, frequency)) {
            dayTrainings.add(
              Training(
                exercise: exercise,
                date: currentDate,
                title: exercise.title,
                time: TimeOfDay(hour: 9 + dayTrainings.length, minute: 0),
              ),
            );
          }
        }

        if (dayTrainings.isNotEmpty) {
          schedule[currentDate] = dayTrainings;
        }
        currentDate = currentDate.add(const Duration(days: 1));
      }

      final newSchedule = TrainingSchedule(
        trainings: schedule,
        injuryType: data.mainInjuryType,
      );

      await scheduleBox.put('schedule', newSchedule);
      notifyListeners();
    } catch (e) {
      debugPrint('Ошибка генерации расписания: $e');
    }
  }

  Map<String, dynamic> _getExerciseFrequency(String title) {
    switch (title) {
      case "Изометрическое напряжение мышц":
        return {'timesPerDay': 3, 'daysPerWeek': 7};
      case "Нейропластическая гимнастика":
        return {'timesPerDay': 2, 'daysPerWeek': 5};
      case "Пассивная разработка сустава":
        return {'timesPerDay': 2, 'daysPerWeek': 6};
      case "Дыхательная гимнастика":
        return {'timesPerDay': 5, 'daysPerWeek': 7};
      case "Тренировка мелкой моторики":
        return {'timesPerDay': 2, 'daysPerWeek': 7};
      case "Растяжка ахиллова сухожилия":
        return {'timesPerDay': 1, 'daysPerWeek': 3};
      case "Стабилизация плечевого сустава":
        return {'timesPerDay': 2, 'daysPerWeek': 4};
      case "Восстановление мышц живота":
        return {'timesPerDay': 3, 'daysPerWeek': 5};
      case "Дыхание с сопротивлением":
        return {'timesPerDay': 4, 'daysPerWeek': 7};
      case "Аквааэробика":
        return {'timesPerDay': 1, 'daysPerWeek': 3};
      case "Баланс-терапия":
        return {'timesPerDay': 2, 'daysPerWeek': 5};
      default:
        return {'timesPerDay': 1, 'daysPerWeek': 3};
    }
  }

  bool _shouldAddTraining(DateTime date, Map<String, dynamic> frequency) {
    final dayOfWeek = date.weekday;
    final timesPerDay = frequency['timesPerDay'] ?? 1;
    final daysPerWeek = frequency['daysPerWeek'] ?? 3;

    // Проверяем соответствие дню недели
    //final isTrainingDay = dayOfWeek <= daysPerWeek;

    // Для разнообразия - добавляем не все тренировки подряд
    return dayOfWeek <=
        daysPerWeek; //isTrainingDay && (date.day % (7 ~/ timesPerDay) == 0);
  }
}
