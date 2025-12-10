part of 'training_bloc.dart';

abstract class TrainingState extends Equatable {
  const TrainingState();

  @override
  List<Object?> get props => [];
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

  const TrainingLoaded({
    required this.schedule,
    this.dayTrainings,
  });

  TrainingLoaded copyWith({
    TrainingSchedule? schedule,
    List<Training>? dayTrainings,
  }) {
    return TrainingLoaded(
      schedule: schedule ?? this.schedule,
      dayTrainings: dayTrainings ?? this.dayTrainings,
    );
  }

  @override
  List<Object?> get props => [schedule, dayTrainings];
}

/// {@template training_error}
/// Состояние ошибки тренировок.
/// {@endtemplate}
class TrainingError extends TrainingState {
  final String message;

  const TrainingError({required this.message});

  @override
  List<Object?> get props => [message];
}