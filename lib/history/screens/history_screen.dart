import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:flutter/material.dart';
import '../../data/models/exercise_history.dart';
import '../../data/models/models.dart';
import '../../data/models/training.dart';
import '../../data/models/training_schedule.dart';
import 'package:intl/intl.dart';
import '../../core/styles/style.dart';
import '../../exercises/models/exercise.dart';
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

class HistoryScreenState extends State<HistoryScreen> {
  String _selectedInjuryType = "Все";
  String _selectedTimePeriod = "За всё время";
  List<ExerciseHistory> _historyList = [];
  List<Exercise> _exercises = []; // Для добавления тренировок

  /// Выбранный день в календаре
  DateTime? _selectedDay;

  TrainingSchedule? _schedule;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<HistoryBloc>().add(LoadHistory());
    });
    _schedule = widget.schedule;
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HistoryBloc, HistoryState>(
      builder: (context, state) {
        if (state is HistoryLoading) {
          return _buildLoadingState();
        } else if (state is HistoryError) {
          return _buildErrorState(state.message);
        } else if (state is HistoryLoaded) {
          final filteredHistory = _applyFilters(state.history, state.selectedInjuryType, state.selectedTimePeriod, state.selectedDay);
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
              ],
            ),
            body: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Фильтры
                  _buildFilters(state.selectedInjuryType, state.selectedTimePeriod),
                  // Календарь
                  _buildCalendar(state.history, state.selectedDay),
                  // Список истории
                  _buildHistoryList(filteredHistory),
                ],
              ),
            ),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildFilters(String selectedInjuryType, String selectedTimePeriod) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: DropdownButton<String>(
              value: selectedInjuryType,
              onChanged: (value) => context.read<HistoryBloc>().add(UpdateInjuryTypeFilter(filter: value ?? 'Все')),
              items: const [
                DropdownMenuItem(value: 'Все', child: Text('Все травмы')),
                // Добавьте другие типы из injuryCategories, если нужно
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: DropdownButton<String>(
              value: selectedTimePeriod,
              onChanged: (value) => context.read<HistoryBloc>().add(UpdateTimePeriodFilter(filter: value ?? 'За всё время')),
              items: const [
                DropdownMenuItem(value: 'За всё время', child: Text('За всё время')),
                DropdownMenuItem(value: 'Неделя', child: Text('Неделя')),
                DropdownMenuItem(value: 'Месяц', child: Text('Месяц')),
                // Другие периоды
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendar(List<ExerciseHistory> history, DateTime? selectedDay) {
    return TableCalendar(
      firstDay: DateTime.utc(2020, 1, 1),
      lastDay: DateTime.utc(2030, 12, 31),
      focusedDay: selectedDay ?? DateTime.now(),
      selectedDayPredicate: (day) => isSameDay(selectedDay, day),
      onDaySelected: (selectedDay, focusedDay) {
        context.read<HistoryBloc>().add(SelectDay(day: selectedDay));
      },
      calendarBuilders: CalendarBuilders(
        markerBuilder: (context, day, events) {
          final status = _getDayStatus(day, history);
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
    );
  }

  Widget _buildHistoryList(List<ExerciseHistory> historyList) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: historyList.length,
      itemBuilder: (context, index) {
        final item = historyList[index];
        return ListTile(
          title: Text(item.exerciseName),
          subtitle: Text(item.formattedDate),
          trailing: Text('Боль: ${item.painLevel}'),
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
            onPressed: () => context.read<HistoryBloc>().add(LoadHistory()),
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
  List<ExerciseHistory> _applyFilters(List<ExerciseHistory> history, String injuryType, String timePeriod, DateTime? selectedDay) {
    var filtered = history;
    // Фильтрация по типу травмы
    if (injuryType != 'Все') {
      filtered = filtered.where((h) => h.exerciseName.contains(injuryType)).toList(); // Пример; адаптируйте по данным
    }
    if (timePeriod != 'За всё время') {
      // Фильтр по периоду (неделя, месяц и т.д.)
      final now = DateTime.now();
      DateTime cutoff;
      if (timePeriod == 'Неделя') {
        cutoff = now.subtract(const Duration(days: 7));
      } else if (timePeriod == 'Месяц') {
        cutoff = now.subtract(const Duration(days: 30));
      } else {
        cutoff = DateTime(2000); // Очень ранняя дата
      }
      filtered = filtered.where((h) => h.dateTime.isAfter(cutoff)).toList();
    }
    if (selectedDay != null) {
      filtered = filtered.where((h) => isSameDay(h.dateTime, selectedDay)).toList();
    }
    return filtered;
  }

  void _exportToPdf(BuildContext context, List<ExerciseHistory> history) {
    // Логика экспорта (оригинальная: навигация к PdfPreviewScreen)
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PdfPreviewScreen(recoveryData: widget.recoveryData, history: history),
      ),
    );
  }

  // Определение статуса дня (0 - нет, 1 - частично/вне плана, 2 - все/полностью)
  int _getDayStatus(DateTime day, List<ExerciseHistory> historyList) {
    final normalizedDay = DateTime(day.year, day.month, day.day);
    final trainings = _schedule?.trainings[normalizedDay] ?? <Training>[];
    final completedCount = trainings.where((t) => t.isCompleted).length;
    final historyCount = historyList.where((h) => isSameDay(h.dateTime, day)).length;

    if (trainings.isEmpty) return 0;
    if (completedCount + historyCount >= trainings.length) return 2;
    if (completedCount + historyCount > 0) return 1;
    return 0;
  }

  Color _getStatusColor(int status) {
    switch (status) {
      case 3:
        return Colors.green; // Все выполнено
      case 2:
        return Colors.yellow; // Частично
      case 1:
        return Colors.blue; // Выполнено вне плана
      default:
        return Colors.grey; // Не выполнено
    }
  }
}