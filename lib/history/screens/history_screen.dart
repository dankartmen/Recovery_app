import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:flutter/material.dart';
import '../../exercises/models/exercise_history.dart';
import '../../data/models/models.dart';
import '../../training/bloc/training_bloc.dart';
import '../../training/models/training.dart';
import '../../training/models/training_schedule.dart';
import '../../core/styles/style.dart';
import '../../exercises/models/exercise.dart';
import '../../training/screen/day_schedule_bottom_sheet.dart';
import '../bloc/history_bloc.dart';
import 'pdf_preview_screen.dart';

// Экран истории выполненных упражнений
class HistoryScreen extends StatefulWidget {
  final RecoveryData recoveryData;
  final TrainingSchedule? schedule;

  const HistoryScreen({
    required this.recoveryData,
    required this.schedule,
    super.key,
  });
  
  @override
  HistoryScreenState createState() => HistoryScreenState();
}

class HistoryScreenState extends State<HistoryScreen> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadHistoryIfNeeded();
      _loadTrainingSchedule();
    });
  }

  /// Загрузка истории только при необходимости
  void _loadHistoryIfNeeded() {
    final bloc = context.read<HistoryBloc>();
    final state = bloc.state;
    
    if (state is HistoryInitial) {
      _loadHistory();
    }
  }

  /// Загрузка расписания тренировок
  void _loadTrainingSchedule() {
    final bloc = context.read<TrainingBloc>();
    final state = bloc.state;
    
    if (state is TrainingInitial) {
      bloc.add(LoadCurrentSchedule());
    }
  }

  /// Инициализация загрузки истории
  void _loadHistory() {
    context.read<HistoryBloc>().add(LoadHistory());
  }
  
  /// Обновление истории
  void _refreshHistory() {
    context.read<HistoryBloc>().add(RefreshHistory());
    context.read<TrainingBloc>().add(RefreshTrainingHistory());
  }

  /// Показ деталей дня (нижний лист с тренировками)
  void _showDayDetails(DateTime day, List<Exercise> exercises) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => MultiBlocProvider(
        providers: [
          BlocProvider.value(value: context.read<TrainingBloc>()),
          BlocProvider.value(value: context.read<HistoryBloc>()),
        ],
        child: DayScheduleBottomSheet(
          day: day,
          filteredExercises: exercises,
          isReadOnly: true, // В истории только просмотр
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    
    return MultiBlocListener(
      listeners: [
        BlocListener<HistoryBloc, HistoryState>(
          listener: (context, state) {
            if (state is HistoryError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(state.message)),
              );
            }
          },
        ),
        BlocListener<TrainingBloc, TrainingState>(
          listener: (context, state) {
            if (state is TrainingError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(state.message)),
              );
            }
          },
        ),
      ],
      child: BlocBuilder<HistoryBloc, HistoryState>(
        builder: (context, historyState) {
          return BlocBuilder<TrainingBloc, TrainingState>(
            builder: (context, trainingState) {
              if (historyState is HistoryLoading || trainingState is TrainingLoading) {
                return _buildLoadingState();
              } else if (historyState is HistoryError) {
                return _buildErrorState(historyState.message);
              } else if (historyState is HistoryLoaded) {
                final filteredHistory = _applyFilters(
                  historyState.history,
                  historyState.selectedInjuryType,
                  historyState.selectedTimePeriod,
                  historyState.selectedDay,
                );

                if (filteredHistory.isEmpty) {
                  return _buildEmptyState();
                }

                return Scaffold(
                  appBar: AppBar(
                    title: const Text(
                      'История восстановления',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    backgroundColor: healthPrimaryColor,
                    iconTheme: const IconThemeData(color: Colors.white),
                    actions: [
                      IconButton(
                        icon: const Icon(Icons.picture_as_pdf),
                        onPressed: () => _exportToPdf(context, filteredHistory),
                        tooltip: 'Экспорт в PDF',
                      ),
                      IconButton(
                        icon: const Icon(Icons.refresh),
                        onPressed: _refreshHistory,
                        tooltip: 'Обновить',
                      ),
                    ],
                  ),
                  body: RefreshIndicator(
                    onRefresh: () async {
                      _refreshHistory();
                      return Future.delayed(const Duration(seconds: 1));
                    },
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Фильтры
                          _buildFilters(historyState),
                          // Календарь
                          _buildCalendar(historyState, trainingState),
                          // Список истории
                          _buildHistoryList(filteredHistory),
                        ],
                      ),
                    ),
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          );
        },
      ),
    );
  }

  Widget _buildFilters(HistoryLoaded state) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: DropdownButton<String>(
              isExpanded: true,
              value: state.selectedInjuryType,
              onChanged: (value) => context.read<HistoryBloc>().add(
                UpdateInjuryTypeFilter(filter: value ?? 'Все')
              ),
              items: const [
                DropdownMenuItem(value: 'Все', child: Text('Все травмы')),
                DropdownMenuItem(value: 'Ортопедические', child: Text('Ортопедические')),
                DropdownMenuItem(value: 'Нейрохирургические', child: Text('Нейрохирургические')),
                DropdownMenuItem(value: 'Спортивные травмы', child: Text('Спортивные травмы')),
                DropdownMenuItem(value: 'Послеоперационная реабилитация', child: Text('Послеоперационная реабилитация')),
                DropdownMenuItem(value: 'Хронические заболевания', child: Text('Хронические заболевания')),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: DropdownButton<String>(
              isExpanded: true,
              value: state.selectedTimePeriod,
              onChanged: (value) => context.read<HistoryBloc>().add(
                UpdateTimePeriodFilter(filter: value ?? 'За всё время')
              ),
              items: const [
                DropdownMenuItem(value: 'За всё время', child: Text('За всё время')),
                DropdownMenuItem(value: 'Неделя', child: Text('Неделя')),
                DropdownMenuItem(value: 'Месяц', child: Text('Месяц')),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendar(HistoryLoaded historyState, TrainingState trainingState) {
    final schedule = trainingState is TrainingLoaded ? trainingState.schedule : null;
    
    return TableCalendar(
      firstDay: DateTime.utc(2020, 1, 1),
      lastDay: DateTime.utc(2030, 12, 31),
      focusedDay: historyState.selectedDay ?? DateTime.now(),
      selectedDayPredicate: (day) => isSameDay(historyState.selectedDay, day),
      onDaySelected: (selectedDay, focusedDay) {
        context.read<HistoryBloc>().add(SelectDay(day: selectedDay));
        // Для демонстрации упражнений - в реальном приложении нужно загружать упражнения
        _showDayDetails(selectedDay, []);
      },
      locale: 'ru_RU',
      startingDayOfWeek: StartingDayOfWeek.monday,
      calendarBuilders: CalendarBuilders(
        markerBuilder: (context, day, events) {
          final status = _getDayStatus(day, historyState.history, schedule);
          return status != null
              ? Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _getStatusColor(status),
                  ),
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.only(top: 24),
                )
              : null;
        },
      ),
      calendarStyle: CalendarStyle(
        todayDecoration: BoxDecoration(
          color: healthPrimaryColor.withValues(alpha: 0.2),
          shape: BoxShape.circle
        ),
        selectedDecoration: BoxDecoration(
          color: healthPrimaryColor,
          shape: BoxShape.circle
        ),
        selectedTextStyle: const TextStyle(color: Colors.white),
        weekendTextStyle: TextStyle(color: Colors.red[300]),
      ),
      headerStyle: HeaderStyle(
        formatButtonVisible: false,
        titleCentered: true,
        titleTextStyle: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: healthTextColor,
        ),
        leftChevronIcon: Icon(
          Icons.chevron_left,
          color: healthPrimaryColor,
        ),
        rightChevronIcon: Icon(
          Icons.chevron_right,
          color: healthPrimaryColor,
        ),
      ),
      daysOfWeekStyle: DaysOfWeekStyle(
        weekdayStyle: TextStyle(
          color: healthTextColor,
          fontWeight: FontWeight.bold,
        ),
        weekendStyle: TextStyle(
          color: Colors.red[300],
          fontWeight: FontWeight.bold,
        )
      ),
      
    );
  }

  Widget _buildHistoryList(List<ExerciseHistory> historyList) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: historyList.length,
      itemBuilder: (context, index) {
        final item = historyList[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: _getPainColor(item.painLevel).withValues(alpha: 0.2),
              child: Icon(
                Icons.fitness_center,
                color: _getPainColor(item.painLevel),
              ),
            ),
            title: Text(item.exerciseName),
            subtitle: Text(item.formattedDate),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('${item.sets} подходов'),
                Text('Боль: ${item.painLevel}/5', 
                  style: TextStyle(color: _getPainColor(item.painLevel))),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildLoadingState() {
    return const Center(child: CircularProgressIndicator(color: healthPrimaryColor));
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(error, style: const TextStyle(color: Colors.red, fontSize: 16)),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              _loadHistory();
              _loadTrainingSchedule();
            },
            child: const Text('Повторить'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.history_toggle_off,
            size: 64,
            color: healthSecondaryTextColor,
          ),
          const SizedBox(height: 16),
          const Text(
            'История пуста',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: healthTextColor,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Выполняйте упражнения, чтобы отслеживать свой прогресс',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: healthSecondaryTextColor),
          ),
        ],
      ),
    );
  }

  // Метод фильтрации истории упражнений
  List<ExerciseHistory> _applyFilters(
    List<ExerciseHistory> history, 
    String injuryType, 
    String timePeriod, 
    DateTime? selectedDay
  ) {
    var filtered = history;
    
    // Фильтрация по типу травмы
    if (injuryType != 'Все') {
      filtered = filtered.where((h) => h.exerciseName.contains(injuryType)).toList();
    }
    
    // Фильтр по периоду
    if (timePeriod != 'За всё время') {
      final now = DateTime.now();
      DateTime cutoff;
      if (timePeriod == 'Неделя') {
        cutoff = now.subtract(const Duration(days: 7));
      } else if (timePeriod == 'Месяц') {
        cutoff = now.subtract(const Duration(days: 30));
      } else {
        cutoff = DateTime(2000);
      }
      filtered = filtered.where((h) => h.dateTime.isAfter(cutoff)).toList();
    }
    
    // Фильтр по выбранному дню
    if (selectedDay != null) {
      filtered = filtered.where((h) => isSameDay(h.dateTime, selectedDay)).toList();
    }
    
    return filtered;
  }

  void _exportToPdf(BuildContext context, List<ExerciseHistory> history) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PdfPreviewScreen(
          recoveryData: widget.recoveryData, 
          historyList: history
        ),
      ),
    );
  }

  // Определение статуса дня
  int? _getDayStatus(DateTime day, List<ExerciseHistory> historyList, TrainingSchedule? schedule) {
    if (schedule == null) return null;
    
    final normalizedDay = DateTime(day.year, day.month, day.day);
    final trainings = schedule.trainings[normalizedDay] ?? <Training>[];
    final completedCount = trainings.where((t) => t.isCompleted).length;
    final historyCount = historyList.where((h) => isSameDay(h.dateTime, day)).length;

    if (trainings.isEmpty) return 0;
    if (completedCount + historyCount >= trainings.length) return 2;
    if (completedCount + historyCount > 0) return 1;
    return 0;
  }

  Color _getStatusColor(int status) {
    switch (status) {
      case 2:
        return Colors.green;
      case 1:
        return Colors.yellow;
      default:
        return Colors.grey;
    }
  }

  Color _getPainColor(int level) {
    switch (level) {
      case 1:
        return Colors.green;
      case 2:
        return Colors.lightGreen;
      case 3:
        return Colors.orange;
      case 4:
        return Colors.deepOrange;
      case 5:
        return Colors.red;
      default:
        return healthSecondaryTextColor;
    }
  }
}