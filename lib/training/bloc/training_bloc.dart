import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import '../../data/models/exercise_history.dart';
import '../../data/models/training.dart';
import '../../data/models/training_schedule.dart';
import '../../services/training_service.dart';


part 'training_event.dart';
part 'training_state.dart';

/// {@template training_bloc}
/// BLoC для управления тренировками и расписанием.
/// Обеспечивает загрузку, создание, обновление и удаление тренировок.
/// {@endtemplate}
class TrainingBloc extends Bloc<TrainingEvent, TrainingState> {
  final TrainingService trainingService;
  StreamSubscription? _historySubscription;
  List<ExerciseHistory> _history = [];

  TrainingBloc({required this.trainingService}) : super(TrainingInitial()) {
    on<LoadTrainingSchedule>(_onLoadTrainingSchedule);
    on<AddTraining>(_onAddTraining);
    on<UpdateTraining>(_onUpdateTraining);
    on<DeleteTraining>(_onDeleteTraining);
    on<UpdateTrainingStatus>(_onUpdateTrainingStatus);
    on<GenerateTrainingSchedule>(_onGenerateTrainingSchedule);
    on<GetTrainingsForDay>(_onGetTrainingsForDay);
  }

  /// Загрузка расписания тренировок
  Future<void> _onLoadTrainingSchedule(
    LoadTrainingSchedule event,
    Emitter<TrainingState> emit,
  ) async {
    emit(TrainingLoading());
    try {
      final schedules = await trainingService.getSchedules(event.userId);
      final activeSchedule = schedules.firstWhere(
        (s) => s.isActive,
        orElse: () => TrainingSchedule.empty(),
      );

      if (activeSchedule.id != 0) {
        final trainings = await trainingService.getTrainingsForSchedule(
          activeSchedule.id,
        );
        final schedule = _groupTrainingsIntoSchedule(activeSchedule, trainings);
        emit(TrainingLoaded(schedule: schedule));
      } else {
        emit(TrainingLoaded(schedule: TrainingSchedule.empty()));
      }
    } catch (e) {
      debugPrint('Ошибка загрузки расписания: $e');
      emit(TrainingError(message: 'Не удалось загрузить расписание тренировок'));
    }
  }

  /// Добавление новой тренировки
  Future<void> _onAddTraining(
    AddTraining event,
    Emitter<TrainingState> emit,
  ) async {
    try {
      if (state is! TrainingLoaded) return;

      final currentState = state as TrainingLoaded;
      final scheduleId = currentState.schedule.id;

      if (scheduleId == 0) {
        throw Exception('Нет активного расписания');
      }

      // Создание тренировки через сервис
      final createdTraining = await trainingService.addTraining(
        scheduleId,
        event.training,
      );

      // Обновление локального расписания
      final updatedSchedule = _addTrainingToSchedule(
        currentState.schedule,
        createdTraining,
      );

      emit(currentState.copyWith(schedule: updatedSchedule));
    } catch (e) {
      debugPrint('Ошибка добавления тренировки: $e');
      emit(TrainingError(message: 'Не удалось добавить тренировку: $e'));
    }
  }

  /// Обновление тренировки
  Future<void> _onUpdateTraining(
    UpdateTraining event,
    Emitter<TrainingState> emit,
  ) async {
    try {
      if (state is! TrainingLoaded) return;

      final currentState = state as TrainingLoaded;
      
      final updatedTraining = await trainingService.updateTraining(
        event.scheduleId,
        event.oldTraining.id,
        event.updatedTraining,
      );

      // Обновление локального расписания
      final updatedSchedule = _updateTrainingInSchedule(
        currentState.schedule,
        updatedTraining,
      );

      emit(currentState.copyWith(schedule: updatedSchedule));
    } catch (e) {
      debugPrint('Ошибка обновления тренировки: $e');
      emit(TrainingError(message: 'Не удалось обновить тренировку: $e'));
    }
  }

  /// Удаление тренировки
  Future<void> _onDeleteTraining(
    DeleteTraining event,
    Emitter<TrainingState> emit,
  ) async {
    try {
      if (state is! TrainingLoaded) return;

      final currentState = state as TrainingLoaded;
      final scheduleId = currentState.schedule.id;

      await trainingService.deleteTraining(scheduleId, event.training.id);

      // Обновление локального расписания
      final updatedSchedule = _removeTrainingFromSchedule(
        currentState.schedule,
        event.training,
      );

      emit(currentState.copyWith(schedule: updatedSchedule));
    } catch (e) {
      debugPrint('Ошибка удаления тренировки: $e');
      emit(TrainingError(message: 'Не удалось удалить тренировку: $e'));
    }
  }

  /// Обновление статуса выполнения тренировки
  Future<void> _onUpdateTrainingStatus(
    UpdateTrainingStatus event,
    Emitter<TrainingState> emit,
  ) async {
    try {
      if (state is! TrainingLoaded) return;

      final currentState = state as TrainingLoaded;
      final scheduleId = currentState.schedule.id;

      final updatedTraining = event.training.copyWith(
        isCompleted: event.isCompleted,
        completedAt: event.isCompleted ? DateTime.now() : null,
      );

      await trainingService.updateTraining(
        scheduleId,
        event.training.id,
        updatedTraining,
      );

      // Обновление локального расписания
      final updatedSchedule = _updateTrainingInSchedule(
        currentState.schedule,
        updatedTraining,
      );

      emit(currentState.copyWith(schedule: updatedSchedule));
    } catch (e) {
      debugPrint('Ошибка обновления статуса: $e');
      emit(TrainingError(message: 'Не удалось обновить статус тренировки: $e'));
    }
  }

  /// Генерация нового расписания
  Future<void> _onGenerateTrainingSchedule(
    GenerateTrainingSchedule event,
    Emitter<TrainingState> emit,
  ) async {
    emit(TrainingLoading());
    try {
      final newSchedule = await trainingService.generateSchedule(
        event.questionnaireId,
      );

      if (newSchedule.id != 0) {
        final trainings = await trainingService.getTrainingsForSchedule(
          newSchedule.id,
        );
        final schedule = _groupTrainingsIntoSchedule(newSchedule, trainings);
        emit(TrainingLoaded(schedule: schedule));
      } else {
        emit(TrainingError(message: 'Не удалось сгенерировать расписание'));
      }
    } catch (e) {
      debugPrint('Ошибка генерации расписания: $e');
      emit(TrainingError(message: 'Не удалось сгенерировать расписание: $e'));
    }
  }

  /// Получение тренировок на конкретный день
  Future<void> _onGetTrainingsForDay(
    GetTrainingsForDay event,
    Emitter<TrainingState> emit,
  ) async {
    try {
      if (state is! TrainingLoaded) return;

      final currentState = state as TrainingLoaded;
      final normalizedDay = DateTime(
        event.day.year,
        event.day.month,
        event.day.day,
      );
      
      final dayTrainings = currentState.schedule.trainings[normalizedDay] ?? [];

      emit(currentState.copyWith(dayTrainings: dayTrainings));
    } catch (e) {
      debugPrint('Ошибка получения тренировок на день: $e');
      // Не эмитим ошибку, просто оставляем пустой список
      if (state is TrainingLoaded) {
        final currentState = state as TrainingLoaded;
        emit(currentState.copyWith(dayTrainings: []));
      }
    }
  }

  // --- Вспомогательные методы ---

  /// Группировка тренировок по датам
  TrainingSchedule _groupTrainingsIntoSchedule(
    TrainingSchedule schedule,
    List<Training> allTrainings,
  ) {
    final trainingsMap = <DateTime, List<Training>>{};
    
    for (final training in allTrainings) {
      final normalizedDate = DateTime(
        training.date.year,
        training.date.month,
        training.date.day,
      );
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

  /// Добавление тренировки в расписание
  TrainingSchedule _addTrainingToSchedule(
    TrainingSchedule schedule,
    Training training,
  ) {
    final updatedTrainings = Map<DateTime, List<Training>>.from(schedule.trainings);
    final normalizedDate = DateTime(
      training.date.year,
      training.date.month,
      training.date.day,
    );

    updatedTrainings.putIfAbsent(normalizedDate, () => <Training>[]).add(training);

    return schedule.copyWith(trainings: updatedTrainings);
  }

  /// Обновление тренировки в расписании
  TrainingSchedule _updateTrainingInSchedule(
    TrainingSchedule schedule,
    Training updatedTraining,
  ) {
    final updatedTrainings = Map<DateTime, List<Training>>.from(schedule.trainings);
    final normalizedDate = DateTime(
      updatedTraining.date.year,
      updatedTraining.date.month,
      updatedTraining.date.day,
    );

    if (updatedTrainings.containsKey(normalizedDate)) {
      final index = updatedTrainings[normalizedDate]!
          .indexWhere((t) => t.id == updatedTraining.id);
      if (index != -1) {
        updatedTrainings[normalizedDate]![index] = updatedTraining;
      }
    }

    return schedule.copyWith(trainings: updatedTrainings);
  }

  /// Удаление тренировки из расписания
  TrainingSchedule _removeTrainingFromSchedule(
    TrainingSchedule schedule,
    Training training,
  ) {
    final updatedTrainings = Map<DateTime, List<Training>>.from(schedule.trainings);
    final normalizedDate = DateTime(
      training.date.year,
      training.date.month,
      training.date.day,
    );

    if (updatedTrainings.containsKey(normalizedDate)) {
      updatedTrainings[normalizedDate]!
          .removeWhere((t) => t.id == training.id);
      
      if (updatedTrainings[normalizedDate]!.isEmpty) {
        updatedTrainings.remove(normalizedDate);
      }
    }

    return schedule.copyWith(trainings: updatedTrainings);
  }

  /// Проверка совпадения дат
  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  /// Проверка выполнения тренировки
  bool isTrainingCompleted(Training training) {
    return _history.any((h) => 
      h.exerciseName == training.title && _isSameDay(h.dateTime, training.date)
    );
  }

  /// Установка истории для проверки выполнения
  void setHistory(List<ExerciseHistory> history) {
    _history = history;
  }

  @override
  Future<void> close() {
    _historySubscription?.cancel();
    return super.close();
  }
}