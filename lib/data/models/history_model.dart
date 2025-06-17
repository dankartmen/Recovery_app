import 'dart:async';

import 'package:flutter/material.dart';

import '../repositories/history_repository.dart';
import 'exercise_history.dart';

class HistoryModel extends ChangeNotifier {
  bool isLoading = true;
  final HistoryRepository repository;
  List<ExerciseHistory> _history = [];
  List<ExerciseHistory> get history => _history;
  bool isInitialized = false;

  HistoryModel(this.repository) {
    loadHistory();
  }

  Future<void> loadHistory() async {
    if (isInitialized) return;
    isLoading = true;
    notifyListeners();

    try {
      _history = await repository.getAllHistory();
    } catch (e) {
      debugPrint("Ошибка загрузки истории: $e");
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  void setHistory(List<ExerciseHistory> history) {
    _history = history;
    notifyListeners();
  }

  void addHistoryItem(ExerciseHistory item) {
    _history.add(item);
    notifyListeners();
  }

  Future<void> refreshHistory(HistoryRepository repository) async {
    final history = await repository.getAllHistory();
    setHistory(history);
  }
}
