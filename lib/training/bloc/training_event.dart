part of 'training_bloc.dart';

abstract class TrainingEvent extends Equatable {
  const TrainingEvent();

  @override
  List<Object> get props => [];
}

class LoadTrainingSchedule extends TrainingEvent {
  final int userId;

  const LoadTrainingSchedule(this.userId);

  @override
  List<Object> get props => [userId];
}

class LoadCurrentSchedule extends TrainingEvent {
  const LoadCurrentSchedule();
}

class GenerateTrainingSchedule extends TrainingEvent {
  final int questionnaireId;

  const GenerateTrainingSchedule(this.questionnaireId);

  @override
  List<Object> get props => [questionnaireId];
}

class AddTraining extends TrainingEvent {
  final Training training;

  const AddTraining({required this.training});

  @override
  List<Object> get props => [training];
}

class UpdateTraining extends TrainingEvent {
  final Training oldTraining;
  final Training updatedTraining;

  const UpdateTraining({
    required this.oldTraining,
    required this.updatedTraining,
  });

  @override
  List<Object> get props => [oldTraining, updatedTraining];
}

class DeleteTraining extends TrainingEvent {
  final Training training;

  const DeleteTraining({required this.training});

  @override
  List<Object> get props => [training];
}

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

class GetTrainingsForDay extends TrainingEvent {
  final DateTime day;

  const GetTrainingsForDay({required this.day});

  @override
  List<Object> get props => [day];
}

class RefreshTrainingHistory extends TrainingEvent {}