import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../data/models/models.dart';
import '../../data/models/training.dart';
import '../../style.dart';

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
      padding: EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            DateFormat('dd MMMM y', 'ru_RU').format(widget.day),
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 16),

          if (trainings.isNotEmpty) ...[
            Expanded(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: trainings.length,
                itemBuilder: (context, index) {
                  final training = trainings[index];
                  final isCompleted = widget.isTrainingCompleted(training);

                  return ListTile(
                    leading: Icon(
                      isCompleted ? Icons.check_circle : Icons.circle_outlined,
                      color: isCompleted ? Colors.green : Colors.grey,
                    ),
                    title: Text(
                      training.title,
                      style: TextStyle(
                        decoration:
                            isCompleted
                                ? TextDecoration.lineThrough
                                : TextDecoration.none,
                      ),
                    ),
                    subtitle: Text(
                      'Время: ${trainings[index].time.format(context)}',
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Кнопка изменения времени
                        IconButton(
                          icon: Icon(Icons.access_time),
                          onPressed:
                              () =>
                                  _editTrainingTime(context, trainings[index]),
                        ),
                        // Кнопка удаления
                        IconButton(
                          icon: Icon(Icons.delete),
                          onPressed: () {
                            widget.onDelete(trainings[index]);
                            _updateTrainings(); // Обновляем локальное состояние
                          },
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            SizedBox(height: 16),
          ] else ...[
            Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Text('Нет запланированных тренировок'),
            ),
          ],

          primaryButton(
            onPressed: () {
              _showAddTrainingDialog(context);
              _updateTrainings();
            },
            text: 'Добавить тренировку',
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
