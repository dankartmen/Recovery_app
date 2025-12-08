import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/styles/style.dart';
import '../../data/repositories/history_repository.dart';
import '../../features/sounds/sound_selection_dialog.dart';
import '../bloc/exercise_bloc.dart';
import '../models/exercise.dart';

/// {@template exercise_detail_screen}
/// Экран детальной информации об упражнении.
/// Отображает описание, шаги и запускает выполнение с таймером.
/// {@endtemplate}
class ExerciseDetailScreen extends StatelessWidget {
  final Exercise exercise;

  const ExerciseDetailScreen({super.key, required this.exercise});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => ExerciseExecutionBloc(
        exercise: exercise,
        historyRepository: context.read<HistoryRepository>(), // Предполагаем Provider в main
      ),
      child: _ExerciseDetailContent(exercise: exercise),
    );
  }
}

class _ExerciseDetailContent extends StatelessWidget {
  final Exercise exercise;

  const _ExerciseDetailContent({required this.exercise});

  @override
  Widget build(BuildContext context) {
    final bloc = context.watch<ExerciseExecutionBloc>();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          exercise.title,
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
            onPressed: () => _selectSound(context),
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
                      exercise.generalDescription,
                      style: const TextStyle(
                        fontSize: 16,
                        color: healthTextColor,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Информация о травмах
                    _buildInfoSection(
                      context,
                      'Информация по травмам',
                      exercise.injurySpecificInfo.entries
                          .map((entry) => '${entry.key}: ${entry.value}')
                          .join('\n'),
                    ),
                    const SizedBox(height: 24),
                    // Подходящие уровни
                    _buildInfoSection(
                      context,
                      'Подходит для',
                      exercise.suitableFor.join(', '),
                    ),
                    const SizedBox(height: 24),
                    // Шаги выполнения
                    _buildStepsSection(context, exercise.steps),
                    const SizedBox(height: 24),
                    // Уровень боли
                    _buildPainLevelSection(context),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
              // Кнопка начала выполнения
              Padding(
                padding: const EdgeInsets.all(20),
                child: SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton.icon(
                    onPressed: bloc.state.isExerciseCompleted
                        ? null
                        : () => _showTimerPicker(context),
                    icon: const Icon(Icons.play_arrow, color: Colors.white),
                    label: Text(
                      bloc.state.isExerciseCompleted ? 'Завершено' : 'Начать выполнение',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: healthPrimaryColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoSection(BuildContext context, String title, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: healthPrimaryColor,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Text(
            content,
            style: TextStyle(fontSize: 14, color: healthTextColor),
          ),
        ),
      ],
    );
  }

  Widget _buildStepsSection(BuildContext context, List<String> steps) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Шаги выполнения',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: healthPrimaryColor,
              ),
            ),
            const Spacer(),
            TextButton.icon(
              onPressed: () => _showFullSteps(context, steps),
              icon: const Icon(Icons.expand_more, size: 16),
              label: const Text('Подробнее'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...steps.asMap().entries.map((entry) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: healthPrimaryColor,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '${entry.key + 1}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      entry.value,
                      style: TextStyle(fontSize: 14, color: healthTextColor),
                    ),
                  ),
                ],
              ),
            )),
      ],
    );
  }

  Widget _buildPainLevelSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Оцените уровень боли',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: healthPrimaryColor,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            children: List.generate(10, (index) {
              final level = index + 1;
              return GestureDetector(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: (context.watch<ExerciseExecutionBloc>().state.painLevel == level)
                        ? Colors.blue.shade50
                        : Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Text('$level'),
                      const SizedBox(width: 12),
                      Expanded(
                        child: LinearProgressIndicator(
                          value: level / 10,
                          backgroundColor: Colors.grey.shade200,
                          valueColor: AlwaysStoppedAnimation<Color>(_getPainColor(level)),
                        ),
                      ),
                    ],
                  ),
                ),
                onTap: () {
                  context.read<ExerciseExecutionBloc>().add(UpdatePainLevel(level: level));
                },
              );
            }),
          ),
        ),
        // Предупреждение при высокой боли
        if (context.watch<ExerciseExecutionBloc>().state.painLevel >= 4)
          Container(
            margin: const EdgeInsets.only(top: 16),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text(
              "Прекратите упражнение и проконсультируйтесь с врачом!",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
      ],
    );
  }

  void _showTimerPicker(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => TimerPickerDialog(
        onDurationSelected: (duration) {
          Navigator.pop(context);
          context.read<ExerciseExecutionBloc>().add(StartSet(duration: duration.inSeconds, sets: 3)); // Пример sets=3
        },
      ),
    );
  }

  void _selectSound(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => SoundSelectionDialog(
        currentSound: null, // Или из prefs
        onSoundSelected: (sound) {
          context.read<ExerciseExecutionBloc>().add(ToggleSound(sound: sound));
        },
      ),
    );
  }

  void _showFullSteps(BuildContext context, List<String> steps) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Полные шаги'),
        content: SingleChildScrollView(child: Text(steps.join('\n'))),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Color _getPainColor(int level) {
    if (level <= 3) return Colors.green;
    if (level <= 6) return Colors.orange;
    return Colors.red;
  }
}

// Простой диалог для таймера (адаптирован из timer_picker_screen.dart)
class TimerPickerDialog extends StatefulWidget {
  final Function(Duration) onDurationSelected;

  const TimerPickerDialog({super.key, required this.onDurationSelected});

  @override
  State<TimerPickerDialog> createState() => _TimerPickerDialogState();
}

class _TimerPickerDialogState extends State<TimerPickerDialog> {
  int _minutes = 0;
  int _seconds = 30; // Дефолт 30 сек

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Выберите время'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '${_minutes.toString().padLeft(2, '0')}:${_seconds.toString().padLeft(2, '0')}',
            style: TextStyle(
              fontSize: 48,
              fontWeight: FontWeight.bold,
              color: healthPrimaryColor,
            ),
          ),
          Row(
            children: [
              Expanded(child: _buildNumberPicker(_minutes, 59, 'минут', (v) => setState(() => _minutes = v))),
              Expanded(child: _buildNumberPicker(_seconds, 59, 'секунд', (v) => setState(() => _seconds = v))),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Отмена'),
        ),
        ElevatedButton(
          onPressed: () {
            final duration = Duration(minutes: _minutes, seconds: _seconds);
            widget.onDurationSelected(duration);
          },
          style: ElevatedButton.styleFrom(backgroundColor: healthPrimaryColor),
          child: const Text('OK', style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }

  Widget _buildNumberPicker(int value, int max, String label, Function(int) onChanged) {
    return Column(
      children: [
        Text(label, style: TextStyle(color: healthSecondaryTextColor)),
        SizedBox(
          height: 150,
          child: ListWheelScrollView.useDelegate(
            itemExtent: 50,
            physics: const FixedExtentScrollPhysics(),
            onSelectedItemChanged: onChanged,
            childDelegate: ListWheelChildBuilderDelegate(
              builder: (context, index) => Center(
                child: Text(
                  index.toString().padLeft(2, '0'),
                  style: TextStyle(
                    fontSize: value == index ? 28 : 22,
                    fontWeight: value == index ? FontWeight.bold : FontWeight.normal,
                    color: value == index ? healthPrimaryColor : healthTextColor,
                  ),
                ),
              ),
              childCount: max + 1,
            ),
          ),
        ),
      ],
    );
  }
}