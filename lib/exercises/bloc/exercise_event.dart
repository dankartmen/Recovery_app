part of 'exercise_bloc.dart';

abstract class ExerciseExecutionEvent extends Equatable {
  const ExerciseExecutionEvent();

  @override
  List<Object?> get props => [];
}

/// {@template start_set}
/// Событие запуска подхода упражнения.
/// {@endtemplate}
class StartSet extends ExerciseExecutionEvent {
  final int duration;
  final int sets;

  const StartSet({required this.duration, required this.sets});

  @override
  List<Object?> get props => [duration, sets];
}

/// {@template update_pain_level}
/// Событие обновления уровня боли.
/// {@endtemplate}
class UpdatePainLevel extends ExerciseExecutionEvent {
  final int level;

  const UpdatePainLevel({required this.level});

  @override
  List<Object?> get props => [level];
}

/// {@template complete_exercise}
/// Событие завершения упражнения.
/// {@endtemplate}
class CompleteExercise extends ExerciseExecutionEvent {
  final String? notes;
  final int? painLevel;

  const CompleteExercise({this.notes, this.painLevel});

  @override
  List<Object?> get props => [notes, painLevel];
}

/// {@template skip_exercise}
/// Событие пропуска упражнения.
/// {@endtemplate}
class SkipExercise extends ExerciseExecutionEvent {}

/// {@template set_duration}
/// Событие установки длительности подхода.
/// {@endtemplate}
class SetDuration extends ExerciseExecutionEvent {
  final int duration;

  const SetDuration({required this.duration});

  @override
  List<Object?> get props => [duration];
}

/// {@template toggle_sound}
/// Событие переключения звука.
/// {@endtemplate}
class ToggleSound extends ExerciseExecutionEvent {
  final Sound? sound;

  const ToggleSound({this.sound});

  @override
  List<Object?> get props => [sound];
}