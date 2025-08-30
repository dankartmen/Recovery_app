import 'dart:async';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/models/history_model.dart';
import '../../data/models/models.dart';
import '../../data/models/training_calendar_model.dart';
import '../../services/auth_service.dart';
import '../../styles/style.dart';
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
  Timer? _timer;
  bool _isRunning = false;
  int _completedSets = 0;
  int _painLevel = 0;
  int _totalDurationSeconds = 0;
  bool _isExerciseCompleted = false;
  Sound? _selectedSound;
  final AudioPlayer _timerPlayer = AudioPlayer();
  late HistoryRepository _historyRepo;
  final TextEditingController _notesController = TextEditingController();
  double _progress = 0.0;
  int _currentSetDuration = 0;

  @override
  void initState() {
    super.initState();
    _loadSoundSettings(); // Загружаем настройки звука пользователя
    _timerPlayer.setReleaseMode(ReleaseMode.stop); // Останавливаем звук после проигрывания
    final authService = Provider.of<AuthService>(context, listen: false);
    _historyRepo = HistoryRepository(authService); // Инициализируем репозиторий истории
  }

  @override
  void dispose() {
    _timer?.cancel(); // Останавливаем таймер при выходе
    _timerPlayer.dispose(); // Освобождаем ресурсы аудиоплеера
    SoundService.previewPlayer.stop(); // Останавливаем превью мелодии
    _notesController.dispose(); // Освобождаем контроллер заметок
    super.dispose();
  }

  // Загружаем выбранную пользователем мелодию для таймера
  Future<void> _loadSoundSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final soundPath = prefs.getString('selectedSound');

    // Поиск мелодии в списке доступных
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

  // Запуск таймера для подхода
  void _startSet(int duration) {
    _timer?.cancel();
    setState(() {
      _currentSetDuration = duration;
      _remainingSeconds = duration;
      _isRunning = true;
      _progress = 0.0;
    });

    // Основной таймер подхода
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
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
          _completedSets++;
          _playCompletionSound(); // Воспроизводим звук окончания подхода
          _completeSet(); // Обновляем состояние после завершения подхода
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Подход $_completedSets завершен!'),
              duration: const Duration(seconds: 2),
              backgroundColor: healthPrimaryColor,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        }
      });
    });
  }

  // Обработка завершения одного подхода
  void _completeSet() {
    setState(() {
      _totalDurationSeconds += _currentSetDuration;
      _isRunning = false;
      _remainingSeconds = 0;
    });
  }

  // Завершение всего упражнения и сохранение результата
  void _completeExercise() async {
    // Диалог для ввода заметок и оценки боли
    final notes = await showDialog<String>(
      context: context,
      builder: (context) {
        int localPainLevel = _painLevel;
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text(
                "Упражнение завершено!",
                style: TextStyle(color: healthTextColor),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Поле для заметок
                    TextField(
                      controller: _notesController,
                      decoration: InputDecoration(
                        labelText: 'Добавить заметки',
                        hintText: 'Опишите ваше состояние...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.grey.shade50,
                      ),
                      maxLines: 3,
                      autofocus: true,
                    ),
                    const SizedBox(height: 20),
                    // Оценка болевых ощущений
                    Text(
                      "Оцените болевые ощущения:",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: healthTextColor,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: List.generate(
                        5,
                        (index) => IconButton(
                          icon: Icon(
                            Icons.favorite,
                            color:
                                index < localPainLevel
                                    ? healthPrimaryColor
                                    : Colors.grey.shade300,
                            size: 32,
                          ),
                          onPressed:
                              () => setDialogState(
                                () => localPainLevel = index + 1,
                              ),
                        ),
                      ),
                    ),
                    // Предупреждение при высокой боли
                    if (localPainLevel >= 4)
                      Container(
                        margin: const EdgeInsets.only(top: 16),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          "Прекратите упражнение и проконсультируйтесь с врачом!",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              actions: [
                // Кнопка пропуска сохранения заметки
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    'Пропустить',
                    style: TextStyle(color: healthSecondaryTextColor),
                  ),
                ),
                // Кнопка сохранения результата
                ElevatedButton(
                  onPressed: () {
                    setState(() => _painLevel = localPainLevel);
                    Navigator.pop(context, _notesController.text);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: healthPrimaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Сохранить',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            );
          },
        );
      },
    );

    // Формируем объект истории упражнения
    final newHistory = ExerciseHistory(
      exerciseName: widget.exercise.title,
      dateTime: DateTime.now(),
      duration: Duration(seconds: _totalDurationSeconds),
      sets: _completedSets,
      notes: notes,
      painLevel: _painLevel,
    );

    // Сохраняем историю в репозиторий и обновляем модели
    final result = await _historyRepo.addHistory(newHistory);
    if (result > 0) {
      Provider.of<HistoryModel>(
        context,
        listen: false,
      ).addHistoryItem(newHistory);
      Provider.of<TrainingCalendarModel>(
        context,
        listen: false,
      ).refreshTrainingStatus();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("Упражнение сохранено в истории"),
          backgroundColor: healthPrimaryColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
    _resetExercise();
  }

  // Сброс состояния после завершения упражнения
  void _resetExercise() {
    setState(() {
      _completedSets = 0;
      _totalDurationSeconds = 0;
      _isExerciseCompleted = false;
      _isRunning = false;
      _remainingSeconds = 0;
    });
  }

  // Воспроизведение выбранного звука при завершении подхода
  void _playCompletionSound() async {
    if (_selectedSound != null) {
      try {
        await SoundService.playSound(_selectedSound!);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Ошибка воспроизведения звука")),
        );
      }
    }
  }

  // Форматирование времени для таймера
  String _formatTime(int seconds) {
    int minutes = (seconds / 60).floor();
    int remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  // Открытие экрана выбора времени для подхода
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

  // Открытие диалога выбора мелодии
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.exercise.title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: healthPrimaryColor,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.music_note),
            onPressed: _selectSound,
            tooltip: 'Выбор мелодии',
          ),
        ],
      ),
      body: Container(
        color: healthBackgroundColor,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              // Основной контент упражнения
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Общее описание упражнения
                    Text(
                      widget.exercise.generalDescription,
                      style: const TextStyle(
                        fontSize: 16,
                        color: healthTextColor,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Специфическая информация для типа травмы
                    if (widget.exercise.injurySpecificInfo.isNotEmpty)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Рекомендации для вашего случая:',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: healthPrimaryColor,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: healthPrimaryColor.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: healthPrimaryColor.withOpacity(0.2),
                              ),
                            ),
                            child: Text(
                              widget.exercise.injurySpecificInfo.values.first,
                              style: const TextStyle(fontSize: 16),
                            ),
                          ),
                          const SizedBox(height: 20),
                        ],
                      ),

                    // Шаги выполнения упражнения
                    Text(
                      'Шаги выполнения:',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: healthPrimaryColor,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...widget.exercise.steps.map(
                      (step) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 28,
                              height: 28,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: healthPrimaryColor,
                                shape: BoxShape.circle,
                              ),
                              child: Text(
                                '${widget.exercise.steps.indexOf(step) + 1}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                step,
                                style: const TextStyle(fontSize: 16),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Изображение упражнения, если есть
                    if (widget.exercise.imageUrl != null)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.network(
                          widget.exercise.imageUrl!,
                          fit: BoxFit.cover,
                          height: 200,
                          width: double.infinity,
                        ),
                      ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
              // Панель управления подходами и таймером
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(24),
                  ),
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
                    // Отображение количества завершённых подходов
                    Text(
                      'Подходы: $_completedSets',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: healthTextColor,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Таймер подхода
                    Text(
                      _formatTime(_remainingSeconds),
                      style: TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        color:
                            _isRunning
                                ? healthPrimaryColor
                                : healthSecondaryColor,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Индикатор прогресса подхода
                    LinearProgressIndicator(
                      value: _progress,
                      minHeight: 10,
                      backgroundColor: Colors.grey[300],
                      color: healthPrimaryColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    const SizedBox(height: 20),

                    // Кнопки управления таймером (старт/пауза/стоп)
                    if (_isRunning || _remainingSeconds > 0)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Кнопка паузы/старта таймера
                          ElevatedButton(
                            onPressed: () {
                              if (_isRunning) {
                                _timer?.cancel();
                              } else {
                                _startSet(_remainingSeconds);
                              }
                              setState(() => _isRunning = !_isRunning);
                            },
                            style: ElevatedButton.styleFrom(
                              shape: const CircleBorder(),
                              padding: const EdgeInsets.all(16),
                              backgroundColor: healthPrimaryColor,
                            ),
                            child: Icon(
                              _isRunning ? Icons.pause : Icons.play_arrow,
                              color: Colors.white,
                              size: 32,
                            ),
                          ),
                          const SizedBox(width: 20),
                          // Кнопка остановки таймера
                          ElevatedButton(
                            onPressed: () {
                              _timer?.cancel();
                              setState(() {
                                _isRunning = false;
                                _remainingSeconds = 0;
                                _progress = 0.0;
                              });
                            },
                            style: ElevatedButton.styleFrom(
                              shape: const CircleBorder(),
                              padding: const EdgeInsets.all(16),
                              backgroundColor: Colors.red,
                            ),
                            child: const Icon(
                              Icons.stop,
                              color: Colors.white,
                              size: 32,
                            ),
                          ),
                        ],
                      ),

                    // Кнопки управления подходами
                    const SizedBox(height: 20),

                    // Кнопка начала упражнения (отображается только до первого подхода)
                    if (_completedSets == 0 && _remainingSeconds == 0)
                      Center(
                        child: SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _openTimerPicker,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: healthSecondaryColor,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              'Начать упражнение',
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ),
                      )
                    else
                      Row(
                        children: [
                          // Кнопка завершения упражнения
                          if (_completedSets > 0 && !_isRunning)
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: _openTimerPicker,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: healthSecondaryColor,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                icon: const Icon(
                                  Icons.add,
                                  color: Colors.white,
                                ),
                                label: const Text(
                                  'Добавить подход',
                                  style: TextStyle(color: Colors.white),
                                ),
                              ),
                            ),
                          const SizedBox(width: 16),
                          if (_completedSets > 0 && !_isRunning)
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed:
                                    _isExerciseCompleted
                                        ? null
                                        : _completeExercise,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: healthPrimaryColor,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                icon: const Icon(
                                  Icons.check,
                                  color: Colors.white,
                                ),
                                label: const Text(
                                  'Завершить',
                                  style: TextStyle(color: Colors.white),
                                ),
                              ),
                            ),
                        ],
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
