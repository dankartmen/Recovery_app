part of 'exercise_list_bloc.dart';

abstract class ExerciseListState extends Equatable {
  const ExerciseListState();

  @override
  List<Object?> get props => [];
}

class ExerciseListInitial extends ExerciseListState {
  const ExerciseListInitial();
}

class ExerciseListLoading extends ExerciseListState {
  const ExerciseListLoading();
}

class ExerciseListLoaded extends ExerciseListState {
  final List<Exercise> exercises;
  final List<Exercise> filteredExercises;

  const ExerciseListLoaded({
    required this.exercises,
    this.filteredExercises = const [],
  });

  ExerciseListLoaded copyWith({List<Exercise>? filteredExercises}) {
    return ExerciseListLoaded(
      exercises: exercises,
      filteredExercises: filteredExercises ?? this.filteredExercises,
    );
  }

  @override
  List<Object?> get props => [exercises, filteredExercises];
}

class ExerciseListError extends ExerciseListState {
  final String message;

  const ExerciseListError({required this.message});

  @override
  List<Object?> get props => [message];
}