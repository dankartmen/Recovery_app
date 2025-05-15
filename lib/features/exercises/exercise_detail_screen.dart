import 'dart:async';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:recovery_app/features/exercises/timer_picker_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/models/models.dart';
import '../sounds/sound_service.dart';
import '../sounds/sound_selection_dialog.dart';
import '../../data/models/exercise_history.dart';
import '../../data/repositories/history_repository.dart';
import '../../data/models/sound.dart';

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
  bool _isCompleted = false;
  Sound? _selectedSound;
  final AudioPlayer _timerPlayer = AudioPlayer();
  final HistoryRepository _historyRepo = HistoryRepository.instance;
  final TextEditingController _notesController = TextEditingController();
  late StreamSubscription<void> _timerPlayerCompleteSubscription;

  double _progress = 0.0;

  @override
  void initState() {
    super.initState();
    _loadSoundSettings();
    _timerPlayer.setReleaseMode(ReleaseMode.stop);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _timerPlayerCompleteSubscription.cancel();
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
          orElse: () => SoundService.sounds.first,
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
          _isCompleted = true;
          _playCompletionSound();
          _showCompletionDialog();
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

  void _showCompletionDialog() async {
    final notes = await showDialog<String>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text("Упражнение завершено!"),
            content: TextField(
              controller: _notesController,
              decoration: InputDecoration(
                labelText: 'Добавить заметки',
                hintText: 'Опишите ваше состояние...',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
              autofocus: true,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Пропустить'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, _notesController.text),
                child: Text('Сохранить'),
              ),
            ],
          ),
    );

    final newHistory = ExerciseHistory(
      exerciseName: widget.exercise.title,
      dateTime: DateTime.now(),
      duration: Duration(seconds: _totalDuration),
      notes: notes,
    );

    await _historyRepo.addHistory(newHistory);
    _notesController.clear();

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text("Упражнение завершено!"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_selectedSound != null)
                  Text('Использована мелодия: ${_selectedSound!.name}'),
                SizedBox(height: 10),
                Text('Длительность: ${_formatTime(_totalDuration)}'),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  _timerPlayer.stop();
                  Navigator.pop(context);
                },
                child: Text("OK"),
              ),
            ],
          ),
    );
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
      _startTimer(selectedTime);
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

            // Таймер
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
                  Text(
                    _formatTime(_remainingSeconds),
                    style: TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: _isRunning ? Colors.red : Colors.blue,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (!_isRunning && _remainingSeconds == 0)
                    ElevatedButton(
                      onPressed: _openTimerPicker,
                      child: const Text('Начать упражнение'),
                    ),
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
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
