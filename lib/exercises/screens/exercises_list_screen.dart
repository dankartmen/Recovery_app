import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/styles/style.dart';
import '../../data/models/models.dart';
import '../bloc/exercise_list_bloc.dart';
import '../widgets/exercise_tile.dart';
import '../models/exercise.dart';
import 'exercise_detail_screen.dart';

/// {@template exercises_list_screen}
/// Экран отображения списка упражнений.
/// Показывает упражнения, отфильтрованные по данным восстановления пользователя,
/// с возможностью поиска и навигации к детальной информации.
/// {@endtemplate}
class ExercisesListScreen extends StatefulWidget {
  /// Данные восстановления пользователя для фильтрации упражнений
  final RecoveryData recoveryData;

  /// {@macro exercises_list_screen}
  const ExercisesListScreen({super.key, required this.recoveryData});

  @override
  ExercisesListScreenState createState() => ExercisesListScreenState();
}

class ExercisesListScreenState extends State<ExercisesListScreen> {
  /// Поисковый запрос для фильтрации упражнений
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    // Загрузка упражнений после построения виджета
    _loadExercises();
  }

  /// Навигация к экрану детальной информации об упражнении
  /// Принимает:
  /// - [context] - контекст построения виджета
  /// - [exercise] - упражнение для отображения детальной информации
  void _navigateToDetail(BuildContext context, Exercise exercise) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ExerciseDetailScreen(exercise: exercise),
      ),
    );
  }

  /// Метод для загрузки упражнений
  void _loadExercises() {
    context.read<ExerciseListBloc>().add(LoadExercises(
      injuryType: widget.recoveryData.specificInjury,
      minPainLevel: widget.recoveryData.painLevel,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Упражнения',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: healthPrimaryColor,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: BlocBuilder<ExerciseListBloc, ExerciseListState>(
        builder: (context, state) {
          if (state is ExerciseListLoading) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is ExerciseListError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 72,
                    color: healthSecondaryColor.withOpacity(0.5),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Ошибка загрузки',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: healthTextColor,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    state.message,
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, color: healthSecondaryTextColor),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _loadExercises,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: healthPrimaryColor,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 14,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Повторить',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            );
          }

          final loadedState = state as ExerciseListLoaded;
          final filteredExercises = _searchQuery.isEmpty
              ? loadedState.filteredExercises
              : loadedState.exercises
                  .where((exercise) =>
                      exercise.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                      exercise.generalDescription.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                      exercise.tags.any((tag) => tag.toLowerCase().contains(_searchQuery.toLowerCase())))
                  .toList();

          if (filteredExercises.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.search_off,
                    size: 72,
                    color: healthSecondaryColor.withOpacity(0.5),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    _searchQuery.isEmpty
                        ? 'Нет подходящих упражнений'
                        : 'Ничего не найдено',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: healthTextColor,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _searchQuery.isEmpty
                        ? 'Попробуйте изменить параметры восстановления'
                        : 'Попробуйте другой запрос',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, color: healthSecondaryTextColor),
                  ),
                  const SizedBox(height: 20),
                  if (_searchQuery.isEmpty)
                    ElevatedButton(
                      onPressed: _loadExercises,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: healthPrimaryColor,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 14,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Обновить список',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                ],
              ),
            );
          }

          return Column(
            children: [
              // Поле поиска
              Padding(
                padding: const EdgeInsets.all(16),
                child: TextField(
                  onChanged: (value) {
                    setState(() => _searchQuery = value);
                    context.read<ExerciseListBloc>().add(UpdateSearchQuery(value));
                  },
                  decoration: InputDecoration(
                    hintText: 'Поиск упражнений...',
                    prefixIcon: const Icon(Icons.search, color: healthSecondaryColor),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              // Список упражнений
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.only(bottom: 20),
                  itemCount: filteredExercises.length,
                  itemBuilder: (context, index) {
                    final exercise = filteredExercises[index];
                    return ExerciseTile(
                      exercise: exercise,
                      onTap: () => _navigateToDetail(context, exercise),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}