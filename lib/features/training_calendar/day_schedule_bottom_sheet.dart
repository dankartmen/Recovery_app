import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../data/models/models.dart';
import '../../data/models/training.dart';
import '../../styles/style.dart';

/// {@template day_schedule_bottom_sheet}
/// Виджет нижнего листа для отображения и управления расписанием тренировок на конкретный день.
/// Позволяет просматривать, добавлять, редактировать и удалять тренировки.
/// {@endtemplate}
class DayScheduleBottomSheet extends StatefulWidget {
  /// День, для которого отображается расписание
  final DateTime day;

  /// Функция для получения списка тренировок на указанный день
  final List<Training> Function() getTrainingsForDay;

  /// Функция обратного вызова при добавлении новой тренировки
  final Function(Training)? onAdd;

  /// Функция обратного вызова при удалении тренировки
  final Function(Training)? onDelete;

  /// Отфильтрованный список упражнений для выбора при добавлении тренировки
  final List<Exercise> filteredExercises;

  /// Функция обратного вызова при обновлении тренировки
  final Function(Training, Training)? onUpdate;

  /// Функция для проверки завершенности тренировки
  final bool Function(Training) isTrainingCompleted;

  /// Режим только для чтения
  final bool isReadOnly;

  /// {@macro day_schedule_bottom_sheet}
  const DayScheduleBottomSheet({
    super.key,
    required this.filteredExercises,
    required this.day,
    required this.getTrainingsForDay,
    this.onAdd,
    this.onDelete,
    this.onUpdate,
    required this.isTrainingCompleted,
    this.isReadOnly = false,
  });

  @override
  DayScheduleBottomSheetState createState() => DayScheduleBottomSheetState();
}

class DayScheduleBottomSheetState extends State<DayScheduleBottomSheet> {
  /// Локальный список тренировок для отображения
  late List<Training> trainings;

  @override
  void initState() {
    super.initState();
    // Инициализация списка тренировок при создании виджета
    trainings = widget.getTrainingsForDay();
  }

  /// Обновление локального списка тренировок
  void _updateTrainings() {
    setState(() {
      trainings = widget.getTrainingsForDay();
    });
  }

  /// Добавление новой тренировки
  /// Принимает:
  /// - [day] - день для добавления тренировки
  /// - [exercise] - выбранное упражнение
  /// - [time] - время тренировки
  void _addTraining(DateTime day, Exercise exercise, TimeOfDay time) {
    final newTraining = Training(
      exercise: exercise,
      date: day,
      title: exercise.title,
      time: time,
    );
    widget.onAdd?.call(newTraining);
    _updateTrainings();
  }

  @override
  Widget build(BuildContext context) {
    final formattedDay = DateFormat('dd MMMM y', 'ru_RU').format(widget.day);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: healthBackgroundColor,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Заголовок c датой
          Center(
            child: Column(
              children: [
                const SizedBox(height: 8),
                Text(
                  formattedDay,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: healthTextColor,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  widget.onAdd == null
                      ? 'Просмотр тренировок'
                      : 'Расписание на день',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: healthSecondaryTextColor.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Список тренировок
          if (trainings.isEmpty)
            Center(
              child: Column(
                children: [
                  Icon(
                    Icons.event_note,
                    size: 64,
                    color: healthSecondaryColor.withValues(alpha: 0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    widget.onAdd == null
                        ? 'Нет тренировок в этот день'
                        : 'Нет запланированных тренировок',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: healthTextColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.onAdd == null
                        ? 'В этот день не было тренировок'
                        : 'Добавьте упражнения для этого дня',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: healthSecondaryTextColor.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            )
          else
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: trainings.length,
                itemBuilder: (context, index) {
                  final training = trainings[index];
                  final isCompleted = widget.isTrainingCompleted(training);
                  return Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      title: Text(training.title),
                      subtitle: Text(training.time.format(context)),
                      trailing:
                          widget.onAdd == null
                              ? null // Нет действий для прошлых дней
                              : Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit),
                                    onPressed:
                                        () => _editTrainingTime(
                                          context,
                                          training,
                                        ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete),
                                    onPressed: () => widget.onDelete!(training),
                                  ),
                                ],
                              ),
                      leading:
                          isCompleted
                              ? const Icon(
                                Icons.check_circle,
                                color: Colors.green,
                              )
                              : const Icon(Icons.pending, color: Colors.orange),
                    ),
                  );
                },
              ),
            ),

          const SizedBox(height: 16),

          // Кнопка добавления (только для будущих дней)
          if (widget.onAdd != null)
            Center(
              child: ElevatedButton.icon(
                onPressed: () => _showAddTrainingDialog(context),
                icon: const Icon(Icons.add),
                label: const Text('Добавить тренировку'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: healthPrimaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// Показ диалога добавления новой тренировки
  /// Принимает:
  /// - [context] - контекст построения виджета
  void _showAddTrainingDialog(BuildContext context) async {
    final Exercise? selectedExercise = await showDialog<Exercise>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text("Выберите упражнение"),
            content: SizedBox(
              width: double.maxFinite,
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: widget.filteredExercises.length,
                itemBuilder: (context, index) {
                  final exercise = widget.filteredExercises[index];
                  return ListTile(
                    title: Text(exercise.title),
                    subtitle: Text(exercise.generalDescription),
                    onTap: () => Navigator.pop(context, exercise),
                  );
                },
              ),
            ),
          ),
    );

    if (selectedExercise == null) return;
    if (!context.mounted) return;
    final TimeOfDay? selectedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: ColorScheme.light(primary: Colors.blue),
          ),
          child: child!,
        );
      },
    );

    if (selectedTime == null) return;

    _addTraining(widget.day, selectedExercise, selectedTime);
  }

  /// Редактирование времени тренировки
  /// Принимает:
  /// - [context] - контекст построения виджета
  /// - [training] - тренировка для редактирования
  void _editTrainingTime(BuildContext context, Training training) async {
    final TimeOfDay? newTime = await showTimePicker(
      context: context,
      initialTime: training.time,
    );

    if (newTime != null) {
      final updatedTraining = training.copyWith(time: newTime);
      widget.onUpdate?.call(training, updatedTraining);
      _updateTrainings(); // Обновляем локальное состояние
    }
  }
}
