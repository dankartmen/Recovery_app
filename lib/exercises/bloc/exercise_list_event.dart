part of 'exercise_list_bloc.dart';

abstract class ExerciseListEvent extends Equatable {
  const ExerciseListEvent();

  @override
  List<Object?> get props => [];
}

/// {@template load_exercises}
/// Событие загрузки упражнений.
/// {@endtemplate}
class LoadExercises extends ExerciseListEvent {
  final String? injuryType;
  final int? minPainLevel;

  const LoadExercises({this.injuryType, this.minPainLevel});

  @override
  List<Object?> get props => [injuryType, minPainLevel];
}

/// {@template update_search_query}
/// Событие обновления поискового запроса.
/// {@endtemplate}
class UpdateSearchQuery extends ExerciseListEvent {
  final String query;

  const UpdateSearchQuery(this.query);

  @override
  List<Object?> get props => [query];
}