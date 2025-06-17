import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/models/models.dart';
import '../../services/auth_service.dart';
import '../../style.dart';
import 'exercise_detail_screen.dart';
import 'exercise_tile.dart';
import '../../services/exercise_service.dart';

class ExercisesScreen extends StatefulWidget {
  final RecoveryData recoveryData;

  const ExercisesScreen({Key? key, required this.recoveryData})
    : super(key: key);

  @override
  _ExercisesScreenState createState() => _ExercisesScreenState();
}

class _ExercisesScreenState extends State<ExercisesScreen> {
  List<Exercise> _exercises = [];
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadExercises();
    });
  }

  Future<void> _loadExercises() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      debugPrint(
        'Загрузка упражнений для травмы: '
        '${widget.recoveryData.specificInjury} и уровня боли: '
        '${widget.recoveryData.painLevel}',
      );
      final authService = Provider.of<AuthService>(context, listen: false);
      final exerciseService = ExerciseService(authService: authService);
      final exercises = await exerciseService.getExercises(
        injuryType: widget.recoveryData.specificInjury,
      );

      // Фильтрация по уровню боли
      final filtered =
          exercises.where((exercise) {
            final bool matches =
                exercise.maxPainLevel >= widget.recoveryData.painLevel;
            if (!matches) {
              debugPrint(
                'Упражнение "${exercise.title}" не подходит по боли: '
                'Требуется: >= ${exercise.maxPainLevel}, '
                'У пользователя: ${widget.recoveryData.painLevel}',
              );
            }
            return matches;
          }).toList();

      debugPrint('После фильтрации осталось: ${filtered.length} упражнений');

      setState(() {
        _exercises = filtered;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
      debugPrint('Ошибка загрузки упражнений: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _navigateToDetail(BuildContext context, Exercise exercise) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ExerciseDetailScreen(exercise: exercise),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(appBar: buildAppBar('Упражнения'), body: _buildBody());
  }

  Widget _buildBody() {
    if (_isLoading) {
      return Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Text(
            'Ошибка: $_error\n\nПопробуйте снова',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    if (_exercises.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.fitness_center, size: 64, color: Colors.grey),
            SizedBox(height: 20),
            Text('Нет подходящих упражнений', style: TextStyle(fontSize: 18)),
            SizedBox(height: 10),
            Text(
              'Попробуйте изменить параметры восстановления',
              style: TextStyle(color: Colors.grey),
            ),
            SizedBox(height: 20),
            primaryButton(onPressed: _loadExercises, text: 'Повторить попытку'),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: _exercises.length,
      itemBuilder: (context, index) {
        final exercise = _exercises[index];
        return ExerciseTile(
          exercise: exercise,
          onTap: () => _navigateToDetail(context, exercise),
        );
      },
    );
  }
}
