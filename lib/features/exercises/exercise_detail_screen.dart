import 'dart:async';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/models/history_model.dart';
import '../../data/models/models.dart';
import '../../data/models/training_calendar_model.dart';
import '../../services/auth_service.dart';
import '../sounds/sound_service.dart';
import '../sounds/sound_selection_dialog.dart';
import '../../data/models/exercise_history.dart';
import '../../data/repositories/history_repository.dart';
import '../../data/models/sound.dart';
import 'timer_picker_screen.dart';

// Экран с конкретным упражнением
class ExerciseDetailScreen extends StatefulWidget {
  final Exercise exercise;

  const ExerciseDetailScreen({required this.exercise});

  @override
  _ExerciseDetailScreenState createState() => _ExerciseDetailScreenState();
}

class _ExerciseDetailScreenState extends State<ExerciseDetailScreen> {
  int _remainingSeconds = 0;
  int _totalDuration = 0;
  Timer? _timer;
  bool _isRunning = false;
  int _completedSets = 0;
  int _painLevel = 0;

  int _totalDurationSeconds = 0;
  bool _isExerciseCompleted = false;
  bool _isCompleted = false;
  Sound? _selectedSound;
  final AudioPlayer _timerPlayer = AudioPlayer();
  late HistoryRepository _historyRepo;
  final TextEditingController _notesController = TextEditingController();

  double _progress = 0.0;

  int _currentSetDuration = 0; // Holds the duration of the current set
  bool _isSetCompleted = false; // Indicates if the current set is completed
  @override
  void initState() {
    super.initState();
    _loadSoundSettings();
    _timerPlayer.setReleaseMode(ReleaseMode.stop);

    // Инициализация HistoryRepository через AuthService
    final authService = Provider.of<AuthService>(context, listen: false);
    _historyRepo = HistoryRepository(authService);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _timerPlayer.dispose();
    SoundService.previewPlayer.stop();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadSoundSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final soundPath = prefs.getString('selectedSound');

    // Поиск звука в списке доступных
    if (soundPath != null) {
      final allSounds = await SoundService.getAllSounds();
      setState(() {
        _selectedSound = allSounds.firstWhere(
          (s) => s.path == soundPath,
          orElse: () => SoundService.defaultSounds.first,
        );
      });
    }
  }

  // Управление таймером
  void _toggleTimer() {
    if (_isRunning) {
      _timer?.cancel();
    } else {
      _startTimer(_remainingSeconds);
    }
    setState(() => _isRunning = !_isRunning);
  }

  void _resetTimer() {
    _timer?.cancel();
    setState(() {
      _isRunning = false;
      _remainingSeconds = 0;
    });
  }

  void _startSet(int duration) {
    _timer?.cancel(); // Отменяем предыдущий таймер

    setState(() {
      _currentSetDuration = duration;
      _remainingSeconds = duration;
      _isRunning = true;
      _isSetCompleted = false;
      _progress = 0.0;
    });

    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      setState(() {
        if (_remainingSeconds > 0) {
          _remainingSeconds--;
          _progress = 1 - (_remainingSeconds / _currentSetDuration);
        } else {
          timer.cancel();
          _isRunning = false;
          _isSetCompleted = true;
          _completedSets++;
          //_totalDurationSeconds += _currentSetDuration;
          _playCompletionSound();
          _completeSet();

          // Показываем уведомление о завершении подхода
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Подход $_completedSets завершен!'),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      });
    });
  }

  void _completeSet() {
    setState(() {
      _totalDurationSeconds += _currentSetDuration;
      _isRunning = false;
      _remainingSeconds = 0;
      _isCompleted = true;
      _playCompletionSound();
    });
  }

  // Шкала оценки боли
  List<Widget> _buildPainScale() {
    return [
      const Text(
        "Оцените болевые ощущения:",
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(
          5,
          (index) => IconButton(
            icon: Icon(
              Icons.favorite,
              color: index < _painLevel ? Colors.red : Colors.grey,
            ),
            onPressed: () => setState(() => _painLevel = index + 1),
          ),
        ),
      ),
      if (_painLevel >= 4)
        const Text(
          "Прекратите упражнение и проконсультируйтесь с врачом!",
          style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
        ),
    ];
  }

  void _completeExercise() async {
    final notes = await showDialog<String>(
      context: context,
      builder: (context) {
        int localPainLevel = _painLevel;

        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text("Упражнение завершено!"),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: _notesController,
                      decoration: const InputDecoration(
                        labelText: 'Добавить заметки',
                        hintText: 'Опишите ваше состояние...',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                      autofocus: true,
                    ),
                    const SizedBox(height: 20),
                    Text(
                      "Оцените болевые ощущения:",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: List.generate(
                        5,
                        (index) => IconButton(
                          icon: Icon(
                            Icons.favorite,
                            color:
                                index < localPainLevel
                                    ? Colors.red
                                    : Colors.grey,
                          ),
                          onPressed:
                              () => setDialogState(
                                () => localPainLevel = index + 1,
                              ),
                        ),
                      ),
                    ),
                    if (localPainLevel >= 4)
                      Text(
                        "Прекратите упражнение и проконсультируйтесь с врачом!",
                        style: TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Пропустить'),
                ),
                TextButton(
                  onPressed: () {
                    setState(() => _painLevel = localPainLevel);
                    Navigator.pop(context, _notesController.text);
                  },
                  child: Text('Сохранить'),
                ),
              ],
            );
          },
        );
      },
    );

    final newHistory = ExerciseHistory(
      exerciseName: widget.exercise.title,
      dateTime: DateTime.now(),
      duration: Duration(seconds: _totalDurationSeconds),
      sets: _completedSets, // Сохраняем количество подходов
      notes: notes,
      painLevel: _painLevel,
    );

    final result = await _historyRepo.addHistory(newHistory);
    if (result > 0) {
      // Обновляем обе модели
      Provider.of<HistoryModel>(
        context,
        listen: false,
      ).addHistoryItem(newHistory);
      Provider.of<TrainingCalendarModel>(
        context,
        listen: false,
      ).refreshTrainingStatus();

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Упражнение сохранено в истории")));
    }
    _resetExercise();
  }

  void _resetExercise() {
    setState(() {
      _completedSets = 0;
      _totalDurationSeconds = 0;
      _isExerciseCompleted = false;
      _isCompleted = false;
      _isRunning = false;
      _remainingSeconds = 0;
    });
  }

  // Запуск таймера с обновлением прогресса
  void _startTimer(int duration) {
    _timer?.cancel();

    setState(() {
      _totalDuration = duration;
      _remainingSeconds = duration;
      _isRunning = true;
    });

    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      setState(() {
        if (_remainingSeconds > 0) {
          _remainingSeconds--;
          _progress = 1 - (_remainingSeconds / _totalDuration);
        } else {
          _timer?.cancel();
          _isRunning = false;
          var _isCompleted = true;
          _playCompletionSound();
        }
      });
    });
  }

  void _playCompletionSound() async {
    if (_selectedSound != null) {
      try {
        await SoundService.playSound(_selectedSound!);
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Ошибка воспроизведения звука")));
      }
    }
  }

  String _formatTime(int seconds) {
    int minutes = (seconds / 60).floor();
    int remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  Future<void> _openTimerPicker() async {
    final selectedTime = await Navigator.push<int>(
      context,
      MaterialPageRoute(
        builder: (context) => TimerPickerScreen(),
        fullscreenDialog: true,
      ),
    );

    if (selectedTime != null && selectedTime > 0) {
      _startSet(selectedTime);
    }
  }

  Future<void> _selectSound() async {
    final sound = await Navigator.push<Sound?>(
      context,
      MaterialPageRoute(
        builder:
            (context) => SoundSelectionDialog(currentSound: _selectedSound),
        settings: RouteSettings(arguments: _selectedSound),
      ),
    );

    if (sound != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('selectedSound', sound.path);
      setState(() => _selectedSound = sound);
    }
  }

  Widget _buildSafetyIndicator() {
    final safetyLevel = 10 - widget.exercise.maxPainLevel;

    return Row(
      children: [
        Icon(Icons.medical_services, color: _getSafetyColor(safetyLevel)),
        SizedBox(width: 8),
        Expanded(
          child: LinearProgressIndicator(
            value: safetyLevel / 10,
            color: _getSafetyColor(safetyLevel),
            minHeight: 10,
          ),
        ),
        SizedBox(width: 8),
        Text(
          "Безопасность: $safetyLevel/10",
          style: TextStyle(fontSize: 12, color: Colors.white),
        ),
      ],
    );
  }

  Color _getSafetyColor(int level) {
    if (level >= 8) return Colors.green;
    if (level >= 6) return Colors.greenAccent;
    if (level >= 4) return Colors.orange;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.exercise.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.music_note),
            onPressed: _selectSound,
            tooltip: 'Выбор мелодии',
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Основной контент
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  //_buildSafetyIndicator(),
                  //const SizedBox(height: 10),

                  // Общее описание
                  Text(
                    widget.exercise.generalDescription,
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 20),

                  // Специфическая информация
                  if (widget.exercise.injurySpecificInfo.isNotEmpty)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Рекомендации для вашего случая:',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          widget.exercise.injurySpecificInfo.values.first,
                          style: const TextStyle(fontSize: 16),
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),

                  // Шаги выполнения
                  const Text(
                    'Шаги выполнения:',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  ...widget.exercise.steps.map(
                    (step) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${widget.exercise.steps.indexOf(step) + 1}. ',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Expanded(child: Text(step)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Изображение
                  if (widget.exercise.imageUrl != null)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        widget.exercise.imageUrl!,
                        fit: BoxFit.cover,
                      ),
                    ),
                ],
              ),
            ),

            // Панель управления подходами
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 10,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Отображение количества подходов
                  Text(
                    'Подходы: $_completedSets',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Таймер
                  Text(
                    _formatTime(_remainingSeconds),
                    style: TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: _isRunning ? Colors.orange : Colors.blue,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Индикатор прогресса
                  LinearProgressIndicator(
                    value: _progress,
                    minHeight: 8,
                    backgroundColor: Colors.grey[300],
                    color: Colors.blue,
                  ),
                  const SizedBox(height: 16),

                  // Управление таймером
                  if (_isRunning || _remainingSeconds > 0)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          icon: Icon(
                            _isRunning ? Icons.pause : Icons.play_arrow,
                          ),
                          iconSize: 36,
                          onPressed: _toggleTimer,
                        ),
                        IconButton(
                          icon: const Icon(Icons.stop),
                          iconSize: 36,
                          onPressed: _resetTimer,
                        ),
                      ],
                    ),

                  // Кнопки управления подходами
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // Кнопка добавления подхода
                      if (!_isRunning)
                        ElevatedButton(
                          onPressed: _openTimerPicker,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 12,
                            ),
                          ),
                          child: const Text('Добавить подход'),
                        ),

                      // Кнопка завершения упражнения
                      if (_completedSets > 0)
                        ElevatedButton(
                          onPressed: _completeExercise,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 12,
                            ),
                          ),
                          child: const Text('Завершить упражнение'),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
