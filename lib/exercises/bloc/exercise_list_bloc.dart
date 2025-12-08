import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../services/exercise_service.dart';
import '../models/exercise.dart'; // Exercise

part 'exercise_list_event.dart';
part 'exercise_list_state.dart';

/// {@template exercise_list_bloc}
/// BLoC для управления списком упражнений.
/// Обеспечивает загрузку, фильтрацию и поиск упражнений.
/// {@endtemplate}
class ExerciseListBloc extends Bloc<ExerciseListEvent, ExerciseListState> {
  final ExerciseService exerciseService;

  ExerciseListBloc({required this.exerciseService}) : super(const ExerciseListInitial()) {
    on<LoadExercises>(_onLoadExercises);
    on<UpdateSearchQuery>(_onUpdateSearchQuery);
  }

  Future<void> _onLoadExercises(LoadExercises event, Emitter<ExerciseListState> emit) async {
    emit(const ExerciseListLoading());
    try {
      final exercises = await exerciseService.getExercises(injuryType: event.injuryType);
      final filtered = event.minPainLevel != null
          ? exercises.where((e) => e.maxPainLevel >= event.minPainLevel!).toList()
          : exercises;
      emit(ExerciseListLoaded(exercises: filtered));
    } catch (e) {
      emit(ExerciseListError(message: 'Не удалось загрузить упражнения: $e'));
    }
  }

  void _onUpdateSearchQuery(UpdateSearchQuery event, Emitter<ExerciseListState> emit) {
    if (state is ExerciseListLoaded) {
      final current = state as ExerciseListLoaded;
      final query = event.query.toLowerCase();
      final filtered = current.exercises
          .where((exercise) =>
              exercise.title.toLowerCase().contains(query) ||
              exercise.generalDescription.toLowerCase().contains(query) ||
              exercise.tags.any((tag) => tag.toLowerCase().contains(query)))
          .toList();
      emit(current.copyWith(filteredExercises: filtered));
    }
  }
}
