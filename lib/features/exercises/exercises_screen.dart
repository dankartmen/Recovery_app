import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/models/models.dart';
import '../../services/auth_service.dart';
import '../../styles/style.dart';
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
  String _searchQuery = '';

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
      final authService = Provider.of<AuthService>(context, listen: false);
      final exerciseService = ExerciseService(authService: authService);
      final exercises = await exerciseService.getExercises(
        injuryType: widget.recoveryData.specificInjury,
      );

      // Фильтрация по уровню боли
      final filtered =
          exercises.where((exercise) {
            return exercise.maxPainLevel >= widget.recoveryData.painLevel;
          }).toList();

      setState(() {
        _exercises = filtered;
      });
    } catch (e) {
      setState(() {
        _error =
            'Не удалось загрузить упражнения. Проверьте подключение к интернету.';
      });
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

  List<Exercise> get _filteredExercises {
    if (_searchQuery.isEmpty) return _exercises;
    return _exercises.where((exercise) {
      return exercise.title.toLowerCase().contains(
            _searchQuery.toLowerCase(),
          ) ||
          exercise.generalDescription.toLowerCase().contains(
            _searchQuery.toLowerCase(),
          );
    }).toList();
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
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              onChanged: (value) => setState(() => _searchQuery = value),
              decoration: InputDecoration(
                hintText: 'Поиск упражнений...',
                prefixIcon: const Icon(
                  Icons.search,
                  color: healthSecondaryColor,
                ),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
        ),
      ),
      body: Container(color: healthBackgroundColor, child: _buildBody()),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(color: healthPrimaryColor),
            const SizedBox(height: 20),
            Text(
              'Подбираем подходящие упражнения...',
              style: TextStyle(fontSize: 16, color: healthSecondaryTextColor),
            ),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 20),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: healthTextColor),
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
                  'Попробовать снова',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_filteredExercises.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.fitness_center,
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
        ),
      );
    }

    return Column(
      children: [
        // Статистика
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              _buildStatCard(
                'Всего упражнений',
                _exercises.length.toString(),
                healthPrimaryColor,
              ),
              const SizedBox(width: 12),
              _buildStatCard(
                'Показано',
                _filteredExercises.length.toString(),
                healthSecondaryColor,
              ),
            ],
          ),
        ),

        // Список упражнений
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.only(bottom: 20),
            itemCount: _filteredExercises.length,
            itemBuilder: (context, index) {
              final exercise = _filteredExercises[index];
              return ExerciseTile(
                exercise: exercise,
                onTap: () => _navigateToDetail(context, exercise),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(fontSize: 14, color: healthSecondaryTextColor),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
