import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../services/auth_service.dart';
import '../repositories/history_repository.dart';
import 'exercise_history.dart';
import 'training.dart';

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
}
