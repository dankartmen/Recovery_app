import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../services/questionnaire_service.dart';
import '../../services/training_service.dart';
import 'exercise_history.dart';
import 'exercise_list_model.dart';
import 'history_model.dart';
import 'models.dart';
import 'training.dart';
import 'training_schedule.dart'; 

/// {@template training_calendar_model}
/// Модель для управления календарём тренировок.
/// Обеспечивает загрузку, сохранение и синхронизацию расписания тренировок
/// с сервером, а также управление статусами выполнения упражнений.
/// {@endtemplate}
class TrainingCalendarModel extends ChangeNotifier {
  /// Сервис аутентификации для выполнения авторизованных запросов
  AuthService? _authService;

  /// Модель истории тренировок для отслеживания выполненных упражнений
  HistoryModel? _historyModel;

  /// Модель списка упражнений для создания тренировок
  ExerciseListModel? _exerciseListModel;

  /// Сервис для работы с тренировками на сервере
  TrainingService? _trainingService;

  /// Сервис анкет для получения ID анкеты пользователя
  QuestionnaireService? _questionnaireService;

  /// Кэш текущего активного расписания
  TrainingSchedule? _currentSchedule;

  /// Публичный геттер для получения текущего расписания
  /// Возвращает:
  /// - текущее расписание тренировок или null, если расписание не загружено
  TrainingSchedule? get currentSchedule => _currentSchedule;

  List<ExerciseHistory> get history => _historyModel?.history ?? [];

  TrainingCalendarModel();

  // Initialize dependencies
  /// Инициализация зависимостей модели
  /// Принимает:
  /// - [authService] - сервис аутентификации
  /// - [historyModel] - модель истории тренировок
  /// - [exerciseListModel] - модель списка упражнений
  void initialize(
    AuthService authService,
    HistoryModel historyModel,
    ExerciseListModel? exerciseListModel,
  ) {
    _authService = authService;
    _historyModel = historyModel;
    _exerciseListModel = exerciseListModel;
    _trainingService = TrainingService(authService);
    _questionnaireService = QuestionnaireService();
  }

  /// Проверка выполнения тренировки
  /// Принимает:
  /// - [training] - тренировка для проверки
  /// Возвращает:
  /// - true если тренировка отмечена как выполненная или найдена в истории
  bool isTrainingCompleted(Training training) {
    return history.any(
      (h) => h.exerciseName == training.title && isSameDay(h.dateTime, training.date),
    );
  }

  /// Обновление статусов всех тренировок
  /// Перезагружает историю тренировок и уведомляет слушателей об изменениях
  void refreshTrainingStatus() {
    _historyModel?.refreshHistory(_historyModel!.repository);
    notifyListeners();
  }

  /// Принудительное обновление UI
  /// Уведомляет всех слушателей об изменении данных
  void refresh() {
    notifyListeners();
  }

  /// Генерация и сохранение расписания тренировок на основе данных анкеты
  /// Принимает:
  /// - [data] - данные анкеты пользователя для формирования расписания
  /// Выбрасывает исключение:
  /// - если зависимости не инициализированы
  /// - если пользователь не аутентифицирован
  /// - при ошибках сервера или сети
  Future<void> generateAndSaveSchedule(RecoveryData data) async {
    try {
      if (_authService == null || _trainingService == null || _questionnaireService == null) {
        debugPrint('Зависимости не инициализированы для генерации расписания');
        return;
      }

      final userId = _authService!.currentUser?.id;
      if (userId == null) {
        throw Exception('Пользователь не аутентифицирован');
      }

      // Get questionnaire ID from server
      final questionnaireJson = await _questionnaireService!.getQuestionnaire(
        _authService!.getBasicAuthHeader(),
        userId,
      );
      final questionnaireId = questionnaireJson['id'] as int?;

      if (questionnaireId == null) {
        throw Exception('Questionnaire not found');
      }

      // Load exercises if needed (using existing ExerciseService logic, but via model)
      if (_exerciseListModel!.exercises.isEmpty) {
        await _exerciseListModel!.loadExercises(injuryType: data.specificInjury);
      }

      // Generate on server
      _currentSchedule = await _trainingService!.generateSchedule(questionnaireId);


      notifyListeners();
    } catch (e) {
      debugPrint('Error generating schedule: $e');
      rethrow;
    }
  }

  /// Получение списка тренировок на конкретный день
  /// Принимает:
  /// - [day] - дата, для которой нужно получить тренировки
  /// Возвращает:
  /// - список тренировок на указанный день или пустой список, если расписание не загружено
  Future<List<Training>> getTrainingsForDay(DateTime day) async {
    if (_currentSchedule == null) {
      await loadCurrentSchedule();
    }
    if (_currentSchedule == null) return [];

    final normalizedDay = DateTime(day.year, day.month, day.day);
    return _currentSchedule!.trainings[normalizedDay] ?? [];
  }

  /// Обновление статуса выполнения тренировки
  /// Принимает:
  /// - [training] - тренировка для обновления
  /// - [completed] - новый статус выполнения
  /// Выбрасывает исключение при ошибках синхронизации с сервером
  Future<void> updateTrainingStatus(Training training, bool completed) async {
    final updated = training.copyWith(isCompleted: completed);
    await updateTraining(training, updated); // Использует полное обновление
  }

  /// Загрузка текущего активного расписания с сервера
  /// Загружает тренировки и группирует их по датам
  /// Автоматически обновляет UI после успешной загрузки
  Future<void> loadCurrentSchedule() async {
    if (_authService == null || _trainingService == null) return;

    final userId = _authService!.currentUser?.id;
    if (userId == null) return;

    try {
      final schedules = await _trainingService!.getSchedules(userId);
      _currentSchedule = schedules.firstWhere(
        (s) => s.isActive,
        orElse: () => TrainingSchedule.empty(),
      );
      if (_currentSchedule != null) {
        // Load trainings if not already grouped
        final allTrainings = await _trainingService!.getTrainingsForSchedule(_currentSchedule!.id);
        _currentSchedule = _groupTrainingsIntoSchedule(_currentSchedule!, allTrainings);
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading schedule: $e');
    }
  }

  /// Обновление одной тренировки в расписании
  /// Принимает:
  /// - [schedule] - текущее расписание
  /// - [updatedTraining] - обновлённая тренировка
  /// Возвращает:
  /// - новое расписание с обновлённой тренировкой
  TrainingSchedule _updateTrainingInSchedule(TrainingSchedule schedule, Training updatedTraining) {
    final updatedTrainings = <DateTime, List<Training>>{};
    schedule.trainings.forEach((date, trainings) {
      final updatedList = trainings.map((t) =>
        t.id == updatedTraining.id ? updatedTraining : t
      ).toList();
      updatedTrainings[date] = updatedList;
    });
    return TrainingSchedule(
      trainings: updatedTrainings,
      injuryType: schedule.injuryType,
      id: schedule.id,
      isActive: schedule.isActive,
      questionnaireId: schedule.questionnaireId,
      specificInjury: schedule.specificInjury,
    );
  }

  /// Группировка списка тренировок по датам
  /// Принимает:
  /// - [schedule] - базовое расписание с метаданными
  /// - [allTrainings] - полный список тренировок для группировки
  /// Возвращает:
  /// - новое расписание с тренировками, сгруппированными по датам
  TrainingSchedule _groupTrainingsIntoSchedule(TrainingSchedule schedule, List<Training> allTrainings) {
    final trainingsMap = <DateTime, List<Training>>{};
    for (final training in allTrainings) {
      final normalizedDate = DateTime(training.date.year, training.date.month, training.date.day);
      trainingsMap.putIfAbsent(normalizedDate, () => <Training>[]).add(training);
    }
    return TrainingSchedule(
      trainings: trainingsMap,
      injuryType: schedule.injuryType,
      id: schedule.id,
      isActive: schedule.isActive,
      questionnaireId: schedule.questionnaireId,
      specificInjury: schedule.specificInjury,
    );
  }

  /// Проверка совпадения дат без учёта времени
  /// Принимает:
  /// - [a] - первая дата для сравнения
  /// - [b] - вторая дата для сравнения
  /// Возвращает:
  /// - true если даты совпадают (без учёта времени)
  bool isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
  /// Добавление новой тренировки (с API-синхронизацией)
  Future<Training> addTraining(Training newTraining) async {
    if (_trainingService == null || _currentSchedule == null) {
      throw Exception('Service or schedule not initialized');
    }

    final scheduleId = _currentSchedule!.id;
    if (scheduleId == 0) {
      throw Exception('No active schedule');
    }

    // Вызываем API
    final createdTraining = await _trainingService!.addTraining(scheduleId, newTraining);

    // Обновляем локальный кэш: добавляем в map по дате
    final normalizedDate = DateTime(newTraining.date.year, newTraining.date.month, newTraining.date.day);
    _currentSchedule!.trainings.putIfAbsent(normalizedDate, () => <Training>[]).add(createdTraining);

    notifyListeners();
    return createdTraining;
  }

  /// Полное обновление тренировки (включая время/дату/статус)
  Future<Training> updateTraining(Training oldTraining, Training updatedTraining) async {
    if (_trainingService == null || _currentSchedule == null) {
      throw Exception('Service or schedule not initialized');
    }

    final scheduleId = _currentSchedule!.id;
    final createdTraining = await _trainingService!.updateTraining(scheduleId, oldTraining.id, updatedTraining);

    // Обновляем локальный кэш
    _currentSchedule = _updateTrainingInSchedule(_currentSchedule!, createdTraining);

    _historyModel?.refreshHistory(_historyModel!.repository);
    notifyListeners();
    return createdTraining;
  }

  /// Удаление тренировки (с API-синхронизацией)
  Future<void> deleteTraining(Training training) async {
    if (_trainingService == null || _currentSchedule == null) {
      throw Exception('Service or schedule not initialized');
    }

    final scheduleId = _currentSchedule!.id;
    await _trainingService!.deleteTraining(scheduleId, training.id);

    // Обновляем локальный кэш: удаляем из map
    final normalizedDate = DateTime(training.date.year, training.date.month, training.date.day);
    final dayTrainings = _currentSchedule!.trainings[normalizedDate] ?? [];
    dayTrainings.removeWhere((t) => t.id == training.id);
    if (dayTrainings.isEmpty) {
      _currentSchedule!.trainings.remove(normalizedDate);
    }

    notifyListeners();
  }

}