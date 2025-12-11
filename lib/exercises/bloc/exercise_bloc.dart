import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/exercise_history.dart';
import '../../data/models/sound.dart';
import '../../data/repositories/history_repository.dart';
import '../../features/sounds/sound_service.dart';
import '../models/exercise.dart';

part 'exercise_event.dart';
part 'exercise_state.dart';

/// {@template exercise_execution_bloc}
/// BLoC для выполнения упражнения.
/// Управляет таймером, прогрессом, уровнем боли и сохранением истории.
/// {@endtemplate}
class ExerciseExecutionBloc extends Bloc<ExerciseExecutionEvent, ExerciseState> {
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
    
    // Приводим state к ExerciseExecutionState
    final currentState = state as ExerciseExecutionState;
    
    final newState = currentState.copyWith(
      remainingSeconds: event.duration,
      isRunning: true,
      currentSetDuration: event.duration,
    );
    emit(newState);

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (currentState.remainingSeconds > 0) {
        final updated = currentState.copyWith(
          remainingSeconds: currentState.remainingSeconds - 1,
          totalDurationSeconds: currentState.totalDurationSeconds + 1,
          progress: (currentState.completedSets + (1 - (currentState.remainingSeconds / currentState.currentSetDuration))) / (event.sets + 1),
        );
        emit(updated);
      } else {
        timer.cancel();
        final completed = currentState.copyWith(
          isRunning: false,
          completedSets: currentState.completedSets + 1,
          remainingSeconds: 0,
        );
        emit(completed);
        if (completed.completedSets >= event.sets) {
          add(const CompleteExercise());
        }
      }
    });
  }

  void _onUpdatePainLevel(UpdatePainLevel event, Emitter<ExerciseState> emit) {
    final currentState = state as ExerciseExecutionState;
    emit(currentState.copyWith(painLevel: event.level));
  }

  Future<void> _onCompleteExercise(CompleteExercise event, Emitter<ExerciseState> emit) async {
    try {
      final currentState = state as ExerciseExecutionState;
      
      final newHistory = ExerciseHistory(
        exerciseName: exercise.title,
        dateTime: DateTime.now(),
        duration: Duration(seconds: currentState.totalDurationSeconds),
        sets: currentState.completedSets,
        notes: event.notes ?? notesController.text,
        painLevel: event.painLevel ?? currentState.painLevel,
      );
      
      final result = await historyRepository.addHistory(newHistory);
      if (result > 0) {
        emit(currentState.copyWith(isExerciseCompleted: true));
      } else {
        emit(ExerciseErrorState(message: 'Ошибка сохранения истории'));
      }
    } catch (e) {
      emit(ExerciseErrorState(message: 'Ошибка завершения упражнения: $e'));
    }
    _resetExercise();
  }

  void _onSkipExercise(SkipExercise event, Emitter<ExerciseState> emit) {
    _resetExercise();
    emit(ExerciseExecutionState.initial());
  }

  void _onSetDuration(SetDuration event, Emitter<ExerciseState> emit) {
    final currentState = state as ExerciseExecutionState;
    emit(currentState.copyWith(currentSetDuration: event.duration));
  }

  Future<void> _onToggleSound(ToggleSound event, Emitter<ExerciseState> emit) async {
    if (event.sound != null) {
      _selectedSound = event.sound;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('selected_sound_path', event.sound!.path);
      await SoundService.previewSound(_selectedSound!);
    }
  }

  void _resetExercise() {
    _timer?.cancel();
    notesController.clear();
  }

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