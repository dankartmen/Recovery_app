import 'package:flutter/material.dart';
import '../../data/models/models.dart';
import 'exercise_detail_screen.dart';
import 'exercise_tile.dart';

// Экран отображения списка упражнений с фильтрацией по данным восстановления

class ExercisesScreen extends StatefulWidget {
  final RecoveryData recoveryData;

  const ExercisesScreen({Key? key, required this.recoveryData})
    : super(key: key);

  @override
  _ExercisesScreenState createState() => _ExercisesScreenState();
}

// Состояние для ExercisesScreen
class _ExercisesScreenState extends State<ExercisesScreen> {
  late List<Exercise> _exercises; // Отложенная инициализация списка упражнений

  @override
  void initState() {
    super.initState();
    _exercises = _getFilteredExercises(); // Инициализируем список
  }

  // Обновление виджета при изменении recoveryData
  @override
  void didUpdateWidget(ExercisesScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.recoveryData != oldWidget.recoveryData) {
      // Перефильтровываем упражнения, если recoveryData изменился
      setState(() {
        _exercises = _getFilteredExercises();
      });
    }
  }

  // Навигация к детальному экрану упражнения
  void _navigateToDetail(BuildContext context, Exercise exercise) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ExerciseDetailScreen(exercise: exercise),
      ),
    );
  }

  // Построение интерфейса списка упражнений
  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: _exercises.length, // Используем _exercises
      itemBuilder: (context, index) {
        final exercise = _exercises[index]; // Используем _exercises
        return ExerciseTile(
          exercise: exercise,
          onTap:
              () => Navigator.pushNamed(
                context,
                '/exercise',
                arguments: _exercises[index], // Используем _exercises
              ),
        );
      },
    );
  }

  // Фильтрация упражнений по параметрам восстановления
  List<Exercise> _getFilteredExercises() {
    return exampleExercises.where((exercise) {
      return exercise.suitableFor.contains(
            widget.recoveryData.specificInjury,
          ) &&
          exercise.maxPainLevel >= widget.recoveryData.painLevel;
    }).toList();
  }
}
