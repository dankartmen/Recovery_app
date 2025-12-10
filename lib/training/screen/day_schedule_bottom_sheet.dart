import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../core/styles/style.dart';
import '../models/training.dart';
import '../../exercises/models/exercise.dart';
import '../bloc/training_bloc.dart';

/// {@template day_schedule_bottom_sheet}
/// Виджет нижнего листа для отображения и управления расписанием тренировок на конкретный день.
/// Позволяет просматривать, добавлять, редактировать и удалять тренировки.
/// {@endtemplate}
class DayScheduleBottomSheet extends StatefulWidget {
  /// День, для которого отображается расписание
  final DateTime day;

  /// Отфильтрованный список упражнений для выбора при добавлении тренировки
  final List<Exercise> filteredExercises;

  /// Режим только для чтения
  final bool isReadOnly;

  /// {@macro day_schedule_bottom_sheet}
  const DayScheduleBottomSheet({
    super.key,
    required this.day,
    required this.filteredExercises,
    this.isReadOnly = false,
  });

  @override
  DayScheduleBottomSheetState createState() => DayScheduleBottomSheetState();
}

class DayScheduleBottomSheetState extends State<DayScheduleBottomSheet> {
  List<Training> _trainings = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _updateTrainings();
  }

  /// Обновление списка тренировок на день
  Future<void> _updateTrainings() async {
    setState(() => _isLoading = true);
    context.read<TrainingBloc>().add(GetTrainingsForDay(day: widget.day));
    // Слушаем обновления в BlocListener
    setState(() => _isLoading = false);
  }

  /// Открытие диалога добавления новой тренировки
  void _showAddTrainingDialog() {
    showDialog<Training>(
      context: context,
      builder: (context) => _AddTrainingDialog(
        filteredExercises: widget.filteredExercises,
        day: widget.day,
      ),
    ).then((newTraining) {
      if (newTraining != null) {
        context.read<TrainingBloc>().add(AddTraining(training: newTraining));
        _updateTrainings();
      }
    });
  }

  /// Редактирование времени тренировки
  void _editTrainingTime(Training training) async {
    final TimeOfDay? newTime = await showTimePicker(
      context: context,
      initialTime: training.time,
    );

    if (newTime != null && !training.isSameTime(newTime)) {
      final updatedTraining = training.copyWith(time: newTime);
      context.read<TrainingBloc>().add(UpdateTraining(
        oldTraining: training,
        updatedTraining: updatedTraining,
      ));
      _updateTrainings();
    }
  }

  /// Удаление тренировки
  void _deleteTraining(Training training) {
    context.read<TrainingBloc>().add(DeleteTraining(training: training));
    _updateTrainings();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<TrainingBloc, TrainingState>(
      listener: (context, state) {
        if (state is TrainingLoaded && state.dayTrainings != null) {
          setState(() => _trainings = state.dayTrainings!);
        } else if (state is TrainingError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message)),
          );
        }
      },
      builder: (context, state) {
        return Container(
          decoration: BoxDecoration(
            color: healthBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Заголовок
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Text(
                  'Тренировки на ${DateFormat('dd MMM yyyy').format(widget.day)}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: healthTextColor,
                  ),
                ),
              ),
              if (_isLoading) const Center(child: CircularProgressIndicator()),
              if (!_isLoading && _trainings.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'Нет тренировок на этот день',
                    style: TextStyle(color: healthSecondaryTextColor),
                  ),
                ),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _trainings.length,
                  itemBuilder: (context, index) {
                    final training = _trainings[index];
                    return ListTile(
                      title: Text(training.title),
                      subtitle: Text(training.timeStr),
                      trailing: widget.isReadOnly
                          ? null
                          : Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit),
                                  onPressed: () => _editTrainingTime(training),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete),
                                  onPressed: () => _deleteTraining(training),
                                ),
                              ],
                            ),
                    );
                  },
                ),
              ),
              if (!widget.isReadOnly)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: ElevatedButton(
                    onPressed: _showAddTrainingDialog,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: healthPrimaryColor,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Добавить тренировку', style: TextStyle(color: Colors.white)),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

/// Диалог добавления новой тренировки
class _AddTrainingDialog extends StatefulWidget {
  final List<Exercise> filteredExercises;
  final DateTime day;

  const _AddTrainingDialog({
    required this.filteredExercises,
    required this.day,
  });

  @override
  _AddTrainingDialogState createState() => _AddTrainingDialogState();
}

class _AddTrainingDialogState extends State<_AddTrainingDialog> {
  Exercise? _selectedExercise;
  TimeOfDay? _selectedTime;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Добавить тренировку'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DropdownButton<Exercise>(
            hint: const Text('Выберите упражнение'),
            value: _selectedExercise,
            onChanged: (value) => setState(() => _selectedExercise = value),
            items: widget.filteredExercises
                .map((e) => DropdownMenuItem(value: e, child: Text(e.title)))
                .toList(),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () async {
              _selectedTime = await showTimePicker(
                context: context,
                initialTime: TimeOfDay.now(),
              );
              setState(() {});
            },
            child: Text(_selectedTime?.format(context) ?? 'Выберите время'),
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
            if (_selectedExercise != null && _selectedTime != null) {
              final newTraining = Training(
                id: 0, // Будет присвоен сервером
                scheduleId: 0, // Из текущего расписания
                exerciseId: _selectedExercise!.id!,
                title: _selectedExercise!.title,
                date: widget.day,
                timeStr: _selectedTime!.format(context),
              );
              Navigator.pop(context, newTraining);
            }
          },
          child: const Text('Добавить'),
        ),
      ],
    );
  }
}