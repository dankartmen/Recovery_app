part of 'training_bloc.dart';

abstract class TrainingState extends Equatable {
  const TrainingState();

  @override
  List<Object> get props => [];
}

class TrainingInitial extends TrainingState {}

class TrainingLoading extends TrainingState {}

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
  List<Object> get props => [schedule, dayTrainings ?? []];
}

class TrainingError extends TrainingState {
  final String message;

  const TrainingError({required this.message});

  @override
  List<Object> get props => [message];
}