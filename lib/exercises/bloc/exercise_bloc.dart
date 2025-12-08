import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/models/exercise_history.dart';
import '../../data/models/sound.dart';
import '../../data/repositories/history_repository.dart';
import '../../features/sounds/sound_service.dart';
import '../models/exercise.dart';
import '../models/exercise_execution_state.dart'; // Exercise, ExerciseHistory

part 'exercise_event.dart';
part 'exercise_state.dart';

/// {@template exercise_execution_bloc}
/// BLoC для выполнения упражнения.
/// Управляет таймером, прогрессом, уровнем боли и сохранением истории.
/// {@endtemplate}
class ExerciseExecutionBloc extends Bloc<ExerciseExecutionEvent, ExerciseExecutionState> {
  final Exercise exercise;
  final HistoryRepository historyRepository;
  Timer? _timer;
  final TextEditingController notesController = TextEditingController();
  Sound? _selectedSound;

  ExerciseExecutionBloc({
    required this.exercise,
    required this.historyRepository,
  }) : super(ExerciseExecutionState.initial()) {
    on<StartSet>(_onStartSet);
    on<UpdatePainLevel>(_onUpdatePainLevel);
    on<CompleteExercise>(_onCompleteExercise);
    on<SkipExercise>(_onSkipExercise);
    on<SetDuration>(_onSetDuration);
    on<ToggleSound>(_onToggleSound);
    _loadSoundSettings(); // Загрузка звука при init
  }

  /// Загрузка настроек звука из SharedPreferences
  Future<void> _loadSoundSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final soundPath = prefs.getString('selected_sound_path');
    if (soundPath != null) {
      // Найти звук по path (из default или custom)
      _selectedSound = [...SoundService.defaultSounds, ...SoundService.customSounds]
          .firstWhere((s) => s.path == soundPath, orElse: () => SoundService.defaultSounds.first);
    } else {
      _selectedSound = SoundService.defaultSounds.first;
    }
  }

  void _onStartSet(StartSet event, Emitter<ExerciseState> emit) {
    _timer?.cancel();
    final newState = state.copyWith(
      remainingSeconds: event.duration,
      isRunning: true,
      currentSetDuration: event.duration,
    );
    emit(newState);

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (state.remainingSeconds > 0) {
        final updated = state.copyWith(
          remainingSeconds: state.remainingSeconds - 1,
          totalDurationSeconds: state.totalDurationSeconds + 1,
          progress: (state.completedSets + (1 - (state.remainingSeconds / state.currentSetDuration))) / (event.sets + 1),
        );
        emit(updated);
      } else {
        timer.cancel();
        final completed = state.copyWith(
          isRunning: false,
          completedSets: state.completedSets + 1,
          remainingSeconds: 0,
        );
        emit(completed);
        if (completed.completedSets >= event.sets) {
          add(CompleteExercise());
        }
      }
    });
  }

  void _onUpdatePainLevel(UpdatePainLevel event, Emitter<ExerciseState> emit) {
    emit(state.copyWith(painLevel: event.level));
  }

  Future<void> _onCompleteExercise(CompleteExercise event, Emitter<ExerciseState> emit) async {
    try {
      final newHistory = ExerciseHistory(
        exerciseName: exercise.title,
        dateTime: DateTime.now(),
        duration: Duration(seconds: state.totalDurationSeconds),
        sets: state.completedSets,
        notes: event.notes ?? notesController.text,
        painLevel: event.painLevel ?? state.painLevel,
      );
      final result = await historyRepository.addHistory(newHistory);
      if (result > 0) {
        emit(state.copyWith(isExerciseCompleted: true));
      } else {
        emit(ExerciseErrorState(message: 'Ошибка сохранения истории'));
      }
    } catch (e) {
      emit(ExerciseErrorState(message: 'Ошибка завершения упражнения: $e'));
    }
    _resetExercise();
  }

  void _onSkipExercise(SkipExercise event, Emitter<ExerciseExecutionState> emit) {
    _resetExercise();
    emit(ExerciseExecutionState.initial());
  }

  void _onSetDuration(SetDuration event, Emitter<ExerciseExecutionState> emit) {
    emit(state.copyWith(currentSetDuration: event.duration));
  }

  Future<void> _onToggleSound(ToggleSound event, Emitter<ExerciseExecutionState> emit) async {
    if (event.sound != null) {
      _selectedSound = event.sound;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('selected_sound_path', event.sound!.path);
      await SoundService.previewSound(event.sound!); // Предпрослушивание
    }
  }

  void _resetExercise() {
    _timer?.cancel();
    notesController.clear();
  }

  /// Форматирование времени для таймера
  /// Принимает:
  /// - [seconds] - секунды для форматирования
  /// Возвращает:
  /// - строку в формате MM:SS
  String formatTime(int seconds) {
    final minutes = (seconds / 60).floor();
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  @override
  Future<void> close() {
    _timer?.cancel();
    notesController.dispose();
    SoundService.previewPlayer.stop();
    return super.close();
  }
}