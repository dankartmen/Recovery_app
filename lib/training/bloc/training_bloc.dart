import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import '../../exercises/models/exercise_history.dart';
import '../models/training.dart';
import '../models/training_schedule.dart';
import '../../data/repositories/history_repository.dart';
import '../../core/services/training_service.dart';

part 'training_event.dart';
part 'training_state.dart';

/// {@template training_bloc}
/// BLoC для управления календарём тренировок.
/// Обеспечивает загрузку, сохранение и синхронизацию расписания тренировок
/// с сервером, а также управление статусами выполнения упражнений.
/// {@endtemplate}
class TrainingBloc extends Bloc<TrainingEvent, TrainingState> {
  final TrainingService trainingService;
  final HistoryRepository historyRepository; // Для проверки выполнения

  TrainingSchedule? _currentSchedule;
  List<ExerciseHistory> _history = [];
  StreamSubscription? _historySubscription;

  TrainingBloc({
    required this.trainingService,
    required this.historyRepository,
  }) : super(TrainingInitial()) {
    on<LoadTrainingSchedule>(_onLoadTrainingSchedule);
    on<GenerateTrainingSchedule>(_onGenerateTrainingSchedule);
    on<AddTraining>(_onAddTraining);
    on<UpdateTraining>(_onUpdateTraining);
    on<DeleteTraining>(_onDeleteTraining);
    on<UpdateTrainingStatus>(_onUpdateTrainingStatus);
    on<GetTrainingsForDay>(_onGetTrainingsForDay);
    on<RefreshHistory>(_onRefreshHistory);

    // Загружаем историю выполнения упражнений
    _loadHistory();
  }

  Future<void> _onLoadTrainingSchedule(LoadTrainingSchedule event, Emitter<TrainingState> emit) async {
    emit(TrainingLoading());
    try {
      final schedules = await trainingService.getSchedules(event.userId);
      _currentSchedule = schedules.isNotEmpty ? schedules.first : TrainingSchedule.empty();
      final dayTrainings = _getTrainingsForDay(DateTime.now());
      emit(TrainingLoaded(schedule: _currentSchedule!, dayTrainings: dayTrainings));
    } catch (e) {
      debugPrint('Ошибка загрузки расписания: $e');
      _currentSchedule = TrainingSchedule.empty();
      emit(TrainingLoaded(schedule: _currentSchedule!));
    }
  }

  Future<void> _onGenerateTrainingSchedule(GenerateTrainingSchedule event, Emitter<TrainingState> emit) async {
    emit(TrainingLoading());
    try {
      final schedule = await trainingService.generateSchedule(event.questionnaireId);
      _currentSchedule = schedule;
      emit(TrainingLoaded(schedule: schedule));
    } catch (e) {
      emit(TrainingError(message: 'Ошибка генерации расписания: $e'));
    }
  }

  Future<void> _onAddTraining(AddTraining event, Emitter<TrainingState> emit) async {
    if (_currentSchedule == null) return;
    try {
      final createdTraining = await trainingService.addTraining(_currentSchedule!.id, event.training);
      _currentSchedule = _addTrainingToSchedule(_currentSchedule!, createdTraining);
      emit(TrainingLoaded(schedule: _currentSchedule!));
    } catch (e) {
      emit(TrainingError(message: 'Ошибка добавления тренировки: $e'));
    }
  }

  Future<void> _onUpdateTraining(UpdateTraining event, Emitter<TrainingState> emit) async {
    if (_currentSchedule == null) return;
    try {
      final updatedTraining = await trainingService.updateTraining(_currentSchedule!.id, event.oldTraining.id, event.updatedTraining);
      _currentSchedule = _updateTrainingInSchedule(_currentSchedule!, updatedTraining);
      emit(TrainingLoaded(schedule: _currentSchedule!));
    } catch (e) {
      emit(TrainingError(message: 'Ошибка обновления тренировки: $e'));
    }
  }

  Future<void> _onDeleteTraining(DeleteTraining event, Emitter<TrainingState> emit) async {
    if (_currentSchedule == null) return;
    try {
      await trainingService.deleteTraining(_currentSchedule!.id, event.training.id);
      _currentSchedule = _removeTrainingFromSchedule(_currentSchedule!, event.training);
      emit(TrainingLoaded(schedule: _currentSchedule!));
    } catch (e) {
      emit(TrainingError(message: 'Ошибка удаления тренировки: $e'));
    }
  }

  void _onUpdateTrainingStatus(UpdateTrainingStatus event, Emitter<TrainingState> emit) {
    if (_currentSchedule == null) return;
    final updatedSchedule = _currentSchedule!.copyWith(
      trainings: _currentSchedule!.trainings.map((date, trainings) {
        return MapEntry(
          date,
          trainings.map((t) {
            if (t.id == event.training.id) {
              return t.copyWith(isCompleted: event.isCompleted);
            }
            return t;
          }).toList(),
        );
      }),
    );
    _currentSchedule = updatedSchedule;
    emit(TrainingLoaded(schedule: _currentSchedule!));
  }

  void _onGetTrainingsForDay(GetTrainingsForDay event, Emitter<TrainingState> emit) {
    if (state is TrainingLoaded && _currentSchedule != null) {
      final current = state as TrainingLoaded;
      final dayTrainings = _getTrainingsForDay(event.day);
      emit(current.copyWith(dayTrainings: dayTrainings));
    }
  }

  void _onRefreshHistory(RefreshHistory event, Emitter<TrainingState> emit) {
    if (state is TrainingLoaded) {
      emit(TrainingLoaded(schedule: _currentSchedule!));
    }
  }

  TrainingSchedule _addTrainingToSchedule(TrainingSchedule schedule, Training training) {
    final updatedTrainings = Map<DateTime, List<Training>>.from(schedule.trainings);
    final normalizedDate = DateTime(training.date.year, training.date.month, training.date.day);
    updatedTrainings.putIfAbsent(normalizedDate, () => []).add(training);
    return schedule.copyWith(trainings: updatedTrainings);
  }

  TrainingSchedule _updateTrainingInSchedule(TrainingSchedule schedule, Training updatedTraining) {
    final updatedTrainings = Map<DateTime, List<Training>>.from(schedule.trainings);
    final normalizedDate = DateTime(updatedTraining.date.year, updatedTraining.date.month, updatedTraining.date.day);
    if (updatedTrainings.containsKey(normalizedDate)) {
      final index = updatedTrainings[normalizedDate]!.indexWhere((t) => t.id == updatedTraining.id);
      if (index != -1) {
        updatedTrainings[normalizedDate]![index] = updatedTraining;
      }
    }
    return schedule.copyWith(trainings: updatedTrainings);
  }

  TrainingSchedule _removeTrainingFromSchedule(TrainingSchedule schedule, Training training) {
    final updatedTrainings = Map<DateTime, List<Training>>.from(schedule.trainings);
    final normalizedDate = DateTime(training.date.year, training.date.month, training.date.day);
    if (updatedTrainings.containsKey(normalizedDate)) {
      updatedTrainings[normalizedDate]!.removeWhere((t) => t.id == training.id);
      if (updatedTrainings[normalizedDate]!.isEmpty) {
        updatedTrainings.remove(normalizedDate);
      }
    }
    return schedule.copyWith(trainings: updatedTrainings);
  }

  /// Загрузка истории упражнений
  Future<void> _loadHistory() async {
    try {
      _history = await historyRepository.getAllHistory();
    } catch (e) {
      debugPrint('Ошибка загрузки истории: $e');
    }
  }
  
  List<Training> _getTrainingsForDay(DateTime day) {
    if (_currentSchedule == null) return [];
    final normalizedDate = DateTime(day.year, day.month, day.day);
    return _currentSchedule!.trainings[normalizedDate] ?? [];
  }

  bool _isTrainingCompleted(Training training) {
    return _history.any((h) =>
      h.exerciseName == training.title && _isSameDay(h.dateTime, training.date)
    );
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  @override
  Future<void> close() {
    _historySubscription?.cancel();
    return super.close();
  }
}