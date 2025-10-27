import 'package:auth_test/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../controllers/exercise_execution_controller.dart';
import '../../data/models/models.dart';
import '../../data/models/sound.dart';
import '../../data/repositories/history_repository.dart';
import '../../styles/style.dart';
import '../sounds/sound_selection_dialog.dart';
import 'timer_picker_screen.dart';

// Экран с конкретным упражнением
class ExerciseDetailScreen extends StatelessWidget {
  final Exercise exercise;

  const ExerciseDetailScreen({super.key, required this.exercise});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Builder(
        builder: (context) {
          final authService = Provider.of<AuthService>(context);
          final historyRepository = HistoryRepository(authService);
          
          return ChangeNotifierProvider(
            create: (context) => ExerciseExecutionController(
              exercise: exercise,
              historyRepository: historyRepository,
            )..loadSoundSettings(),
            child: _ExerciseDetailContent(),
          );
        },
      ),
    );
  }
}
  
class _ExerciseDetailContent extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final controller = Provider.of<ExerciseExecutionController>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          controller.exercise.title,
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
            onPressed: () => _selectSound(context, controller),
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
              
              // Основной контент упражнения (оригинальная структура)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Общее описание упражнения
                    Text(
                      controller.exercise.generalDescription,
                      style: const TextStyle(
                        fontSize: 16,
                        color: healthTextColor,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Специфическая информация для типа травмы
                    if (controller.exercise.injurySpecificInfo.isNotEmpty)
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
                              color: healthPrimaryColor.withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: healthPrimaryColor.withValues(alpha: 0.2),
                              ),
                            ),
                            child: Text(
                              controller.exercise.injurySpecificInfo.values.first,
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
                    ...controller.exercise.steps.map(
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
                                '${controller.exercise.steps.indexOf(step) + 1}',
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
                    if (controller.exercise.imageUrl != null)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.network(
                          controller.exercise.imageUrl!,
                          fit: BoxFit.cover,
                          height: 200,
                          width: double.infinity,
                        ),
                      ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
              
              // Панель управления подходами и таймером (оригинальный дизайн)
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
                      'Подходы: ${controller.completedSets}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: healthTextColor,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Таймер подхода
                    Text(
                      controller.formatTime(controller.remainingSeconds),
                      style: TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        color: controller.isRunning 
                            ? healthPrimaryColor 
                            : healthSecondaryColor,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Индикатор прогресса подхода
                    LinearProgressIndicator(
                      value: controller.progress,
                      minHeight: 10,
                      backgroundColor: Colors.grey[300],
                      color: healthPrimaryColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    const SizedBox(height: 20),

                    // Кнопки управления таймером (старт/пауза/стоп)
                    if (controller.isRunning || controller.remainingSeconds > 0)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Кнопка паузы/старта таймера
                          ElevatedButton(
                            onPressed: controller.toggleTimer,
                            style: ElevatedButton.styleFrom(
                              shape: const CircleBorder(),
                              padding: const EdgeInsets.all(16),
                              backgroundColor: healthPrimaryColor,
                            ),
                            child: Icon(
                              controller.isRunning ? Icons.pause : Icons.play_arrow,
                              color: Colors.white,
                              size: 32,
                            ),
                          ),
                          const SizedBox(width: 20),
                          // Кнопка остановки таймера
                          ElevatedButton(
                            onPressed: controller.stopTimer,
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
                    if (controller.completedSets == 0 && controller.remainingSeconds == 0)
                      Center(
                        child: SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () => _openTimerPicker(context, controller),
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
                          // Кнопка добавления подхода
                          if (controller.completedSets > 0 && !controller.isRunning)
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () => _openTimerPicker(context, controller),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: healthSecondaryColor,
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                icon: const Icon(Icons.add, color: Colors.white),
                                label: const Text(
                                  'Добавить подход',
                                  style: TextStyle(color: Colors.white),
                                ),
                              ),
                            ),
                          const SizedBox(width: 16),
                          // Кнопка завершения упражнения
                          if (controller.completedSets > 0 && !controller.isRunning)
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: controller.isExerciseCompleted 
                                    ? null 
                                    : () => _completeExerciseDialog(context, controller),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: healthPrimaryColor,
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                icon: const Icon(Icons.check, color: Colors.white),
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

  void _openTimerPicker(BuildContext context, ExerciseExecutionController controller) async {
    final selectedTime = await Navigator.push<int>(
      context,
      MaterialPageRoute(
        builder: (context) => TimerPickerScreen(),
        fullscreenDialog: true,
      ),
    );

    if (selectedTime != null && selectedTime > 0) {
      controller.startSet(selectedTime);
    }
  }

  void _selectSound(BuildContext context, ExerciseExecutionController controller) async {
    final sound = await Navigator.push<Sound?>(
      context,
      MaterialPageRoute(
        builder: (context) => SoundSelectionDialog(currentSound: controller.selectedSound),
      ),
    );

    if (sound != null) {
      controller.selectSound(sound);
      // Сохранение в SharedPreferences (можно добавить в контроллер)
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('selectedSound', sound.path);
    }
  }

  void _completeExerciseDialog(BuildContext context, ExerciseExecutionController controller) async {
    final notes = await showDialog<String>(
      context: context,
      builder: (context) {
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
                      controller: controller.notesController,
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
                            color: index < controller.painLevel
                                ? healthPrimaryColor
                                : Colors.grey.shade300,
                            size: 32,
                          ),
                          onPressed: () {
                            setDialogState(() {});
                            controller.updatePainLevel(index + 1);
                          },
                        ),
                      ),
                    ),
                    
                    // Предупреждение при высокой боли
                    if (controller.painLevel >= 4)
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
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    'Пропустить',
                    style: TextStyle(color: healthSecondaryTextColor),
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context, controller.notesController.text);
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

    if (notes != null) {
      final success = await controller.completeExercise(notes: notes);
      if (success && context.mounted) {
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
    }
  }
}
  

