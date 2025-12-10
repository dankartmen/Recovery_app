part of 'training_bloc.dart';

abstract class TrainingEvent extends Equatable {
  const TrainingEvent();

  @override
  List<Object?> get props => [];
}

/// {@template load_training_schedule}
/// Событие загрузки расписания тренировок.
/// {@endtemplate}
class LoadTrainingSchedule extends TrainingEvent {
  final int userId;

  const LoadTrainingSchedule({required this.userId});

  @override
  List<Object?> get props => [userId];
}

/// {@template generate_training_schedule}
/// Событие генерации нового расписания.
/// {@endtemplate}
class GenerateTrainingSchedule extends TrainingEvent {
  final int questionnaireId;

  const GenerateTrainingSchedule({required this.questionnaireId});

  @override
  List<Object?> get props => [questionnaireId];
}

/// {@template add_training}
/// Событие добавления новой тренировки.
/// {@endtemplate}
class AddTraining extends TrainingEvent {
  final Training training;

  const AddTraining({required this.training});

  @override
  List<Object?> get props => [training];
}

/// {@template update_training}
/// Событие обновления тренировки.
/// {@endtemplate}
class UpdateTraining extends TrainingEvent {
  final Training oldTraining;
  final Training updatedTraining;

  const UpdateTraining({
    required this.oldTraining,
    required this.updatedTraining,
  });

  @override
  List<Object?> get props => [oldTraining, updatedTraining];
}

/// {@template delete_training}
/// Событие удаления тренировки.
/// {@endtemplate}
class DeleteTraining extends TrainingEvent {
  final Training training;

  const DeleteTraining({required this.training});

  @override
  List<Object?> get props => [training];
}

/// {@template update_training_status}
/// Событие обновления статуса выполнения тренировки.
/// {@endtemplate}
class UpdateTrainingStatus extends TrainingEvent {
  final Training training;
  final bool isCompleted;

  const UpdateTrainingStatus({
    required this.training,
    required this.isCompleted,
  });

  @override
  List<Object?> get props => [training, isCompleted];
}

/// {@template get_trainings_for_day}
/// Событие получения тренировок на день.
/// {@endtemplate}
class GetTrainingsForDay extends TrainingEvent {
  final DateTime day;

  const GetTrainingsForDay({required this.day});

  @override
  List<Object?> get props => [day];
}

/// {@template refresh_history}
/// Событие обновления истории для проверки выполнения.
/// {@endtemplate}
class RefreshHistory extends TrainingEvent {}