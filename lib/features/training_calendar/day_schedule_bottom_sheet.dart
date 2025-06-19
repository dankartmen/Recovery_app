import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../data/models/models.dart';
import '../../data/models/training.dart';
import '../../styles/style.dart';

class DayScheduleBottomSheet extends StatefulWidget {
  final DateTime day;
  final List<Training> Function() getTrainingsForDay;
  final Function(Training) onAdd;
  final Function(Training) onDelete;
  final List<Exercise> filteredExercises;
  final Function(Training, Training) onUpdate;
  final bool Function(Training) isTrainingCompleted;

  const DayScheduleBottomSheet({
    Key? key,
    required this.filteredExercises,
    required this.day,
    required this.getTrainingsForDay,
    required this.onAdd,
    required this.onDelete,
    required this.onUpdate,
    required this.isTrainingCompleted,
  }) : super(key: key);

  @override
  _DayScheduleBottomSheetState createState() => _DayScheduleBottomSheetState();
}

class _DayScheduleBottomSheetState extends State<DayScheduleBottomSheet> {
  late List<Training> trainings;

  @override
  void initState() {
    super.initState();
    trainings = widget.getTrainingsForDay();
  }

  void _updateTrainings() {
    setState(() {
      trainings = widget.getTrainingsForDay();
    });
  }

  void _addTraining(DateTime day, Exercise exercise, TimeOfDay time) {
    final newTraining = Training(
      exercise: exercise,
      date: day,
      title: exercise.title,
      time: time,
    );
    widget.onAdd(newTraining);
    _updateTrainings();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: healthBackgroundColor,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Заголовок с градиентом
          Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: healthPrimaryColor,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: Text(
                DateFormat('dd MMMM y', 'ru_RU').format(widget.day),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Список тренировок
          if (trainings.isNotEmpty) ...[
            Expanded(
              child: ListView.builder(
                shrinkWrap: true,
                physics: const ClampingScrollPhysics(),
                itemCount: trainings.length,
                itemBuilder: (context, index) {
                  final training = trainings[index];
                  final isCompleted = widget.isTrainingCompleted(training);

                  return _buildTrainingCard(training, isCompleted);
                },
              ),
            ),
            const SizedBox(height: 16),
          ] else ...[
            _buildEmptyState(),
          ],

          // Кнопка добавления
          primaryButton(
            onPressed: () {
              _showAddTrainingDialog(context);
            },
            text: 'Добавить тренировку',
          ),
        ],
      ),
    );
  }

  Widget _buildTrainingCard(Training training, bool isCompleted) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: healthPrimaryColor.withOpacity(0.1), width: 1),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color:
                isCompleted
                    ? Colors.green.withOpacity(0.1)
                    : healthPrimaryColor.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            isCompleted ? Icons.check_circle : Icons.access_time,
            color: isCompleted ? Colors.green : healthPrimaryColor,
            size: 24,
          ),
        ),
        title: Text(
          training.title,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: healthTextColor,
            decoration:
                isCompleted ? TextDecoration.lineThrough : TextDecoration.none,
          ),
        ),
        subtitle: Text(
          'Время: ${training.time.format(context)}',
          style: TextStyle(color: healthSecondaryTextColor, fontSize: 14),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(Icons.access_time, color: healthSecondaryColor),
              onPressed: () => _editTrainingTime(context, training),
            ),
            IconButton(
              icon: Icon(Icons.delete, color: Colors.red[300]),
              onPressed: () {
                widget.onDelete(training);
                _updateTrainings();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        children: [
          Icon(
            Icons.fitness_center,
            size: 64,
            color: healthSecondaryColor.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'Нет запланированных тренировок',
            style: TextStyle(
              fontSize: 18,
              color: healthSecondaryTextColor,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Добавьте упражнения для этого дня',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: healthSecondaryTextColor.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

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

  void _editTrainingTime(BuildContext context, Training training) async {
    final TimeOfDay? newTime = await showTimePicker(
      context: context,
      initialTime: training.time,
    );

    if (newTime != null) {
      final updatedTraining = training.copyWith(time: newTime);
      widget.onUpdate(training, updatedTraining);
      _updateTrainings(); // Обновляем локальное состояние
    }
  }
}
