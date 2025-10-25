import 'package:flutter/material.dart';
import 'training_calendar_model.dart';
import 'training_schedule.dart'; // Импорт новой модели

class HomeScreenModel extends ChangeNotifier {
  final TrainingCalendarModel _trainingCalendarModel; // Зависимость от модели календаря

  TrainingSchedule? _localSchedule;

  // Используем публичный геттер TrainingCalendarModel.currentSchedule
  TrainingSchedule? get schedule => _localSchedule ?? _trainingCalendarModel.currentSchedule; // Геттер для расписания

  HomeScreenModel(this._trainingCalendarModel) {
    // Подписка на изменения в модели календаря
    _trainingCalendarModel.addListener(_onScheduleChanged);
    // Инициализация: загрузка текущего расписания
    _trainingCalendarModel.loadCurrentSchedule();
  }

  void _onScheduleChanged() {
    // Синхронизируем локальный кэш, если модель календаря обновила расписание
    _localSchedule = _trainingCalendarModel.currentSchedule;
    notifyListeners(); // Уведомление об изменениях расписания
  }

  /// Обновить расписание извне (например, после сохранения в Hive)
  void updateSchedule(TrainingSchedule schedule) {
    _localSchedule = schedule;
    notifyListeners();
  }

  @override
  void dispose() {
    _trainingCalendarModel.removeListener(_onScheduleChanged);
    super.dispose();
  }

}