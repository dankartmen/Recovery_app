part of 'exercise_bloc.dart';

abstract class ExerciseState extends Equatable {
  const ExerciseState();

  @override
  List<Object> get props => [];
}

/// {@template exercise__loaded}
/// Состояние загруженного выполнения упражнения.
/// {@endtemplate}
class ExerciseLoadedState extends ExerciseState {
  final ExerciseState data;

  const ExerciseLoadedState({required this.data});

  @override
  List<Object> get props => [data];
}

/// {@template exercise__error}
/// Состояние ошибки выполнения упражнения.
/// {@endtemplate}
class ExerciseErrorState extends ExerciseState {
  final String message;

  const ExerciseErrorState({required this.message});

  @override
  List<Object> get props => [message];
}