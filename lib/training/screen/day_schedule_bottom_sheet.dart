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
    _loadTrainings();
  }

  /// Загрузка тренировок на день
  Future<void> _loadTrainings() async {
    if (!mounted) return;
    
    setState(() => _isLoading = true);
    
    try {
      final bloc = context.read<TrainingBloc>();
      bloc.add(GetTrainingsForDay(day: widget.day));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка загрузки тренировок: $e')),
        );
      }
    }
  }

  /// Открытие диалога добавления новой тренировки
  void _showAddTrainingDialog() async {
    final Exercise? selectedExercise = await showDialog<Exercise>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Выберите упражнение"),
        content: SizedBox(
          width: double.maxFinite,
          child: widget.filteredExercises.isEmpty
              ? const Center(child: Text('Нет доступных упражнений'))
              : ListView.builder(
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
    );

    if (selectedTime == null) return;

    final bloc = context.read<TrainingBloc>();
    final schedule = bloc.currentSchedule;
    
    if (schedule == null || schedule.id == 0) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Нет активного расписания')),
        );
      }
      return;
    }

    final newTraining = Training(
      id: 0,
      scheduleId: schedule.id,
      exerciseId: selectedExercise.id ?? 0,
      title: selectedExercise.title,
      date: widget.day,
      timeStr: '${selectedTime.hour.toString().padLeft(2, '0')}:${selectedTime.minute.toString().padLeft(2, '0')}',
      isCompleted: false,
    );

    bloc.add(AddTraining(training: newTraining));
    await _loadTrainings();
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
      _loadTrainings();
    }
  }

  /// Удаление тренировки
  void _deleteTraining(Training training) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить тренировку?'),
        content: const Text('Вы уверены, что хотите удалить эту тренировку?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<TrainingBloc>().add(DeleteTraining(training: training));
              _loadTrainings();
            },
            child: const Text('Удалить', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<TrainingBloc, TrainingState>(
      listener: (context, state) {
        if (state is TrainingError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message)),
          );
          setState(() => _isLoading = false);
        } else if (state is TrainingDayLoaded && state.day == widget.day) {
          setState(() {
            _trainings = state.trainings;
            _isLoading = false;
          });
        } 
      },
      builder: (context, state) {
        final formattedDay = DateFormat('dd MMMM y', 'ru_RU').format(widget.day);
      
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: healthBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
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
                      widget.isReadOnly
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

              // Индикатор загрузки или список тренировок
              if (_isLoading)
                const Center(child: CircularProgressIndicator())
              else if (_trainings.isEmpty)
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
                        widget.isReadOnly
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
                        widget.isReadOnly
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
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _trainings.length,
                    itemBuilder: (context, index) {
                      final training = _trainings[index];
                      final isCompleted = context.read<TrainingBloc>().isTrainingCompleted(training);
                      
                      return Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListTile(
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
                          leading: isCompleted
                              ? const Icon(
                                  Icons.check_circle,
                                  color: Colors.green,
                                )
                              : const Icon(Icons.pending, color: Colors.orange),
                          onTap: widget.isReadOnly
                              ? null
                              : () => _editTrainingTime(training),
                        ),
                      );
                    },
                  ),
                ),

              const SizedBox(height: 16),

              // Кнопка добавления (только для будущих дней и не только для чтения)
              if (!widget.isReadOnly && widget.day.isAfter(DateTime.now().subtract(const Duration(days: 1))))
                Center(
                  child: ElevatedButton.icon(
                    onPressed: _showAddTrainingDialog,
                    icon: const Icon(Icons.add, color: Colors.white),
                    label: const Text('Добавить тренировку', style: TextStyle(color: Colors.white)),
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
      },
    );
  }
}