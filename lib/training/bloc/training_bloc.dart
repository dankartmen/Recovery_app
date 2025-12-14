import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import '../../core/services/auth_service.dart';
import '../../data/repositories/exercise_history_repository.dart';
import '../../exercises/models/exercise_history.dart';
import '../models/training.dart';
import '../models/training_schedule.dart';
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
  final ExerciseHistoryRepository historyRepository;
  final AuthService authService;

  TrainingSchedule? _currentSchedule;
  List<ExerciseHistory> _history = [];
  StreamSubscription? _historySubscription;

  TrainingBloc({
    required this.trainingService,
    required this.historyRepository,
    required this.authService,
  }) : super(TrainingInitial()) {
    on<LoadTrainingSchedule>(_onLoadTrainingSchedule);
    on<GenerateTrainingSchedule>(_onGenerateTrainingSchedule);
    on<AddTraining>(_onAddTraining);
    on<UpdateTraining>(_onUpdateTraining);
    on<DeleteTraining>(_onDeleteTraining);
    on<UpdateTrainingStatus>(_onUpdateTrainingStatus);
    on<GetTrainingsForDay>(_onGetTrainingsForDay);
    on<RefreshTrainingHistory>(_onRefreshHistory);
    on<LoadCurrentSchedule>(_onLoadCurrentSchedule); // Новое событие

    // Загружаем историю выполнения упражнений
    _loadHistory();
  }

  Future<void> _onLoadTrainingSchedule(LoadTrainingSchedule event, Emitter<TrainingState> emit) async {
    emit(TrainingLoading());
    try {
      final schedules = await trainingService.getSchedules(event.userId);
      _currentSchedule = schedules.isNotEmpty 
          ? schedules.firstWhere((s) => s.isActive, orElse: () => schedules.first) 
          : TrainingSchedule.empty();
      
      // Загружаем тренировки для расписания
      if (_currentSchedule!.id != 0) {
        final allTrainings = await trainingService.getTrainingsForSchedule(_currentSchedule!.id);
        _currentSchedule = _groupTrainingsIntoSchedule(_currentSchedule!, allTrainings);
      }
      
      emit(TrainingLoaded(schedule: _currentSchedule!));
    } catch (e) {
      debugPrint('Ошибка загрузки расписания: $e');
      _currentSchedule = TrainingSchedule.empty();
      emit(TrainingLoaded(schedule: _currentSchedule!));
    }
  }

  Future<void> _onLoadCurrentSchedule(LoadCurrentSchedule event, Emitter<TrainingState> emit) async {
    emit(TrainingLoading());
    try {
      final userId = authService.currentUser?.id;
      if (userId == null) {
        emit(TrainingError(message: 'Пользователь не аутентифицирован'));
        return;
      }

      final schedules = await trainingService.getSchedules(userId);
      _currentSchedule = schedules.isNotEmpty 
          ? schedules.firstWhere((s) => s.isActive, orElse: () => schedules.first) 
          : TrainingSchedule.empty();
      
      // Загружаем тренировки для расписания
      if (_currentSchedule!.id != 0) {
        final allTrainings = await trainingService.getTrainingsForSchedule(_currentSchedule!.id);
        _currentSchedule = _groupTrainingsIntoSchedule(_currentSchedule!, allTrainings);
      }
      
      emit(TrainingLoaded(schedule: _currentSchedule!));
    } catch (e) {
      debugPrint('Ошибка загрузки текущего расписания: $e');
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
    if (_currentSchedule == null || _currentSchedule!.id == 0) {
      emit(TrainingError(message: 'Нет активного расписания'));
      return;
    }
    try {
      final createdTraining = await trainingService.addTraining(_currentSchedule!.id, event.training);
      _currentSchedule = _addTrainingToSchedule(_currentSchedule!, createdTraining);
      emit(TrainingLoaded(schedule: _currentSchedule!));
    } catch (e) {
      emit(TrainingError(message: 'Ошибка добавления тренировки: $e'));
    }
  }

  Future<void> _onUpdateTraining(UpdateTraining event, Emitter<TrainingState> emit) async {
    if (_currentSchedule == null || _currentSchedule!.id == 0) {
      emit(TrainingError(message: 'Нет активного расписания'));
      return;
    }
    try {
      final updatedTraining = await trainingService.updateTraining(
        _currentSchedule!.id, 
        event.oldTraining.id, 
        event.updatedTraining
      );
      _currentSchedule = _updateTrainingInSchedule(_currentSchedule!, updatedTraining);
      emit(TrainingLoaded(schedule: _currentSchedule!));
    } catch (e) {
      emit(TrainingError(message: 'Ошибка обновления тренировки: $e'));
    }
  }

  Future<void> _onDeleteTraining(DeleteTraining event, Emitter<TrainingState> emit) async {
    if (_currentSchedule == null || _currentSchedule!.id == 0) {
      emit(TrainingError(message: 'Нет активного расписания'));
      return;
    }
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

  Future<void> _onGetTrainingsForDay(GetTrainingsForDay event, Emitter<TrainingState> emit) async {
    if (_currentSchedule == null) {
      // Пытаемся загрузить расписание
      add(LoadCurrentSchedule());
      return;
    }
    
    final dayTrainings = _getTrainingsForDay(event.day);
    final listofCompletedTrainings = dayTrainings.map((t) => isTrainingCompleted(t)).toList();
    
    emit(TrainingDayLoaded(
      day: event.day,
      trainings: dayTrainings,
      isTrainingCompleted: listofCompletedTrainings,
    ));
  }

  Future<void> _onRefreshHistory(RefreshTrainingHistory event, Emitter<TrainingState> emit) async {
    await _loadHistory();
    if (_currentSchedule != null) {
      emit(TrainingLoaded(schedule: _currentSchedule!));
    }
  }

  // Вспомогательные методы из старой реализации
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

  
  bool isTrainingCompleted(Training training) {
    return _history.any((h) =>
      h.exerciseName == training.title && _isSameDay(h.dateTime, training.date)
    );
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  // Геттер для получения текущего расписания
  TrainingSchedule? get currentSchedule => _currentSchedule;

  @override
  Future<void> close() {
    _historySubscription?.cancel();
    return super.close();
  }
}