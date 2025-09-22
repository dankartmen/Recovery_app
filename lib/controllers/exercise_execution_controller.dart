import 'dart:async';

import 'package:flutter/material.dart';

import '../data/models/exercise_history.dart';
import '../data/models/models.dart';
import '../data/models/sound.dart';
import '../data/repositories/history_repository.dart';
import '../features/exercises/exercise_execution_state.dart';
import '../features/sounds/sound_service.dart';

class ExerciseExecutionController with ChangeNotifier{
  final Exercise exercise;
  final HistoryRepository historyRepository;

  Timer? _timer;
  final TextEditingController notesController = TextEditingController();

  ExerciseExecutionState _state = ExerciseExecutionState.initial();
  Sound? _selectedSound;

  bool _isLoading = false;
  String? _errorMessage;

  ExerciseExecutionController({
    required this.exercise,
    required this.historyRepository,
  });

  ExerciseExecutionState get state => _state;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  Sound? get selectedSound => _selectedSound;
  // Проверка, можно ли завершить упражнение
  bool get canCompleteExercise => _state.completedSets > 0 && !_state.isRunning;

  int get remainingSeconds => _state.remainingSeconds;
  bool get isRunning => _state.isRunning;
  int get completedSets => _state.completedSets;
  int get painLevel => _state.painLevel;
  int get totalDurationSeconds => _state.totalDurationSeconds;
  bool get isExerciseCompleted => _state.isExerciseCompleted;
  double get progress => _state.progress;
  int get currentSetDuration => _state.currentSetDuration;
  String get notes => notesController.text;

  // Обновление уровня боли
  void updatePainLevel(int level) {
    _updateState(_state.copyWith(painLevel: level));
  }

  // Запуск таймера для подхода
  void startSet(int duration) {
    _timer?.cancel();
    
    _updateState(_state.copyWith(
      currentSetDuration: duration,
      remainingSeconds: duration,
      isRunning: true,
      progress: 0.0,
    ));

    // Основной таймер подхода
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_state.remainingSeconds > 0) {
        final newRemainingSeconds = _state.remainingSeconds - 1;
        final newProgress = 1 - (newRemainingSeconds / _state.currentSetDuration);
        
        _updateState(_state.copyWith(
          remainingSeconds: newRemainingSeconds,
          progress: newProgress,
        ));
      } else {
        timer.cancel();
        _completeSet();
      }
    });
  }

  // Пауза/возобновление таймера
  void toggleTimer() {
    if (_state.isRunning) {
      _timer?.cancel();
      _updateState(_state.copyWith(isRunning: false));
    } else {
      startSet(_state.remainingSeconds);
    }
  }

  // Остановка таймера
  void stopTimer() {
    _timer?.cancel();
    _updateState(_state.copyWith(
      isRunning: false,
      remainingSeconds: 0,
      progress: 0.0,
    ));
  }

  // Завершение подхода
  void _completeSet() {
    _updateState(_state.copyWith(
      isRunning: false,
      completedSets: _state.completedSets + 1,
      totalDurationSeconds: _state.totalDurationSeconds + _state.currentSetDuration,
    ));

    _playCompletionSound();
  }

  void _updateState(ExerciseExecutionState newState) {
    _state = newState;
    notifyListeners();
  }

  // Загрузка настроек звука
  Future<void> loadSoundSettings() async {
    try {
      final allSounds = await SoundService.getAllSounds();
      // Здесь можно загрузить сохраненные настройки из SharedPreferences
      // Пока просто берем первый звук по умолчанию
      _selectedSound = allSounds.first;
      notifyListeners();
    } catch (e) {
      _errorMessage = "Ошибка загрузки звуков: $e";
      notifyListeners();
    }
  }

  // Выбор звука
  void selectSound(Sound sound) {
    _selectedSound = sound;
    notifyListeners();
  }

  // Предпросмотр звука
  Future<void> previewSound(Sound sound) async {
    try {
      await SoundService.previewSound(sound);
    } catch (e) {
      _errorMessage = "Ошибка воспроизведения звука: $e";
      notifyListeners();
    }
  }

  // Воспроизведение звука завершения
  void _playCompletionSound() async {
    if (_selectedSound != null) {
      try {
        await SoundService.playSound(_selectedSound!);
      } catch (e) {
        _errorMessage = "Ошибка воспроизведения звука завершения: $e";
        notifyListeners();
      }
    }
  }

  // Завершение всего упражнения
  Future<bool> completeExercise({String? notes, int? painLevel}) async {
    _isLoading = true;
    notifyListeners();

    try {
      final newHistory = ExerciseHistory(
        exerciseName: exercise.title,
        dateTime: DateTime.now(),
        duration: Duration(seconds: _state.totalDurationSeconds),
        sets: _state.completedSets,
        notes: notes ?? notesController.text,
        painLevel: painLevel ?? _state.painLevel,
      );

      final result = await historyRepository.addHistory(newHistory);

      if (result > 0) {
        _updateState(_state.copyWith(isExerciseCompleted: true));
        _resetExercise();
        return true;
      } else {
        _errorMessage = "Ошибка сохранения истории";
        return false;
      }
    } catch (e) {
      _errorMessage = "Ошибка завершения упражнения: $e";
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Сброс состояния упражнения
  void _resetExercise() {
    _timer?.cancel();
    notesController.clear();
    
    _updateState(ExerciseExecutionState.initial());
  }

  // Пропуск сохранения (только сброс)
  void skipExercise() {
    _resetExercise();
  }

  

  // Форматирование времени для таймера
  String formatTime(int seconds) {
    int minutes = (seconds / 60).floor();
    int remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  // Очистка ошибок
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _timer?.cancel();
    notesController.dispose();
    SoundService.previewPlayer.stop();
    super.dispose();
  }
  
}