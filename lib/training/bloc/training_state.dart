part of 'training_bloc.dart';

abstract class TrainingState extends Equatable {
  const TrainingState();

  @override
  List<Object> get props => [];
}

/// {@template training_initial}
/// Начальное состояние тренировок.
/// {@endtemplate}
class TrainingInitial extends TrainingState {}

/// {@template training_loading}
/// Состояние загрузки тренировок.
/// {@endtemplate}
class TrainingLoading extends TrainingState {}

/// {@template training_loaded}
/// Состояние загруженных тренировок.
/// {@endtemplate}
class TrainingLoaded extends TrainingState {
  final TrainingSchedule schedule;
  final List<Training>? dayTrainings;
  final DateTime? selectedDay;

  const TrainingLoaded({
    required this.schedule,
    this.dayTrainings,
    this.selectedDay,
  });

  TrainingLoaded copyWith({
    TrainingSchedule? schedule,
    List<Training>? dayTrainings,
    DateTime? selectedDay,
  }) {
    return TrainingLoaded(
      schedule: schedule ?? this.schedule,
      dayTrainings: dayTrainings ?? this.dayTrainings,
      selectedDay: selectedDay ?? this.selectedDay,
    );
  }

  @override
  List<Object> get props => [schedule, dayTrainings ?? [], selectedDay ?? DateTime.now()];
}

class TrainingDayLoaded extends TrainingState {
  final DateTime day;
  final List<Training> trainings;
  final List<bool> isTrainingCompleted;

  const TrainingDayLoaded({
    required this.day,
    required this.trainings,
    required this.isTrainingCompleted,
  });

  @override
  List<Object> get props => [day, trainings, isTrainingCompleted];
}

/// {@template training_error}
/// Состояние ошибки тренировок.
/// {@endtemplate}
class TrainingError extends TrainingState {
  final String message;

  const TrainingError({required this.message});

  @override
  List<Object> get props => [message];
}