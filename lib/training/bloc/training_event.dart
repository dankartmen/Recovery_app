part of 'training_bloc.dart';

abstract class TrainingEvent extends Equatable {
  const TrainingEvent();

  @override
  List<Object> get props => [];
}

/// Событие загрузки расписания тренировок
class LoadTrainingSchedule extends TrainingEvent {
  final int userId;

  const LoadTrainingSchedule({required this.userId});

  @override
  List<Object> get props => [userId];
}

/// Событие добавления новой тренировки
class AddTraining extends TrainingEvent {
  final Training training;

  const AddTraining({required this.training});

  @override
  List<Object> get props => [training];
}

/// Событие обновления тренировки
class UpdateTraining extends TrainingEvent {
  final int scheduleId;
  final Training oldTraining;
  final Training updatedTraining;

  const UpdateTraining({
    required this.scheduleId,
    required this.oldTraining,
    required this.updatedTraining,
  });

  @override
  List<Object> get props => [scheduleId, oldTraining, updatedTraining];
}

/// Событие удаления тренировки
class DeleteTraining extends TrainingEvent {
  final Training training;

  const DeleteTraining({required this.training});

  @override
  List<Object> get props => [training];
}

/// Событие обновления статуса выполнения тренировки
class UpdateTrainingStatus extends TrainingEvent {
  final Training training;
  final bool isCompleted;

  const UpdateTrainingStatus({
    required this.training,
    required this.isCompleted,
  });

  @override
  List<Object> get props => [training, isCompleted];
}

/// Событие генерации нового расписания
class GenerateTrainingSchedule extends TrainingEvent {
  final int questionnaireId;

  const GenerateTrainingSchedule({required this.questionnaireId});

  @override
  List<Object> get props => [questionnaireId];
}

/// Событие получения тренировок на день
class GetTrainingsForDay extends TrainingEvent {
  final DateTime day;

  const GetTrainingsForDay({required this.day});

  @override
  List<Object> get props => [day];
}