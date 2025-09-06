import 'package:auth_test/data/models/exercise_list_model.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../../data/models/exercise_history.dart';
import '../../data/models/history_model.dart';
import '../../data/models/models.dart';
import '../../data/models/training.dart';
import '../../data/models/training_calendar_model.dart';
import '../../data/models/training_schedule.dart';
import '../../data/models/home_screen_model.dart';
import 'package:intl/intl.dart';
import '../../styles/style.dart';
import 'pdf_preview_screen.dart';
import '../training_calendar/day_schedule_bottom_sheet.dart';

// Экран истории выполненных упражнений
class HistoryScreen extends StatefulWidget {
  final RecoveryData recoveryData;
  final TrainingSchedule schedule;

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
  bool _isLoading = true;
  String? _error;
  TrainingSchedule _schedule = TrainingSchedule(trainings: {}, injuryType: '');
  List<Exercise> _exercises = []; // Для добавления тренировок

  /// Выбранный день в календаре
  DateTime? _selectedDay;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    debugPrint('Начало загрузки данных в HistoryScreen');
    setState(() {
      _error = null;
      _isLoading = true;
    });

    try {
      // Загрузка истории
      final historyModel = Provider.of<HistoryModel>(context, listen: false);
      await historyModel.loadHistory();
      debugPrint(
        'История загружена в HistoryScreen, записей: ${historyModel.history.length}',
      );
      _historyList = historyModel.history;

      // Загрузка расписания из Hive
      final scheduleBox = await Hive.openBox<TrainingSchedule>(
        'training_schedule',
      );
      final savedSchedule = scheduleBox.get('schedule');
      _schedule = savedSchedule ?? TrainingSchedule.empty();
      if (!mounted) return;

      // Загрузка упражнений
      final exerciseListModel = Provider.of<ExerciseListModel>(
        context,
        listen: false,
      );
      if (exerciseListModel.exercises.isEmpty) {
        await exerciseListModel.loadExercises(
          injuryType: widget.recoveryData.specificInjury,
        );
      }
      _exercises = exerciseListModel.exercises;
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = "Не удалось загрузить историю. Попробуйте снова.";
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  // Определение статуса дня
  int _getDayStatus(DateTime day, List<ExerciseHistory> history) {
    final normalizedDay = DateTime(day.year, day.month, day.day);
    // 1. Проверяем выполненные упражнения за день
    final completedExercises =
        history
            .where((h) => isSameDay(h.dateTime, normalizedDay))
            .map((h) => h.exerciseName)
            .toSet();
    if (completedExercises.isEmpty) {
      return 0; // если нету выполненных тренировок
    }
    // 2. Получаем запланированные тренировки
    final plannedTrainings = _schedule.trainings[normalizedDay] ?? [];

    // 3. Определяем статус
    if (plannedTrainings.isEmpty) {
      return history.any((h) => isSameDay(h.dateTime, day)) ? 1 : 0;
    }

    final allCompleted = plannedTrainings.every(
      (training) => completedExercises.contains(training.title),
    );

    return allCompleted ? 3 : 2; // 3 = все выполнено, 2 = частично
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

  /// Показ деталей дня (нижний лист с тренировками)
  /// Принимает:
  /// - [day] - день для отображения деталей
  void _showDayDetails(DateTime day) {
    final normalizedDay = DateTime(day.year, day.month, day.day);
    final dayTrainings = _schedule.trainings[normalizedDay] ?? [];
    debugPrint(
      'Запрошены тренировки на ${DateFormat('dd.MM.yyyy').format(normalizedDay)}: ${dayTrainings.length}',
    );

    final isPastDay = normalizedDay.isBefore(DateTime.now());

    showModalBottomSheet(
      context: context,
      builder:
          (context) => DayScheduleBottomSheet(
            filteredExercises: _exercises,
            day: normalizedDay,
            getTrainingsForDay: () => dayTrainings,
            onAdd:
                isPastDay
                    ? null
                    : (training) => _addTraining(normalizedDay, training),
            onDelete:
                isPastDay
                    ? null
                    : (training) => _deleteTraining(normalizedDay, training),
            onUpdate:
                isPastDay
                    ? null
                    : (oldTraining, newTraining) => _updateTraining(
                      normalizedDay,
                      oldTraining,
                      newTraining,
                    ),
            isTrainingCompleted:
                Provider.of<TrainingCalendarModel>(
                  context,
                  listen: false,
                ).isTrainingCompleted,
            isReadOnly: isPastDay,
          ),
    );
  }

  /// Обновление тренировки
  /// Принимает:
  /// - [day] - день тренировки
  /// - [oldTraining] - старая версия тренировки
  /// - [newTraining] - новая версия тренировки
  void _updateTraining(
    DateTime day,
    Training oldTraining,
    Training newTraining,
  ) {
    final index = _schedule.trainings[day]?.indexOf(oldTraining);

    if (index != null && index >= 0) {
      setState(() {
        _schedule.trainings[day]![index] = newTraining;
      });
      _saveSchedule(_schedule);
    }
  }

  /// Добавление новой тренировки
  /// Принимает:
  /// - [day] - день для добавления тренировки
  /// - [training] - данные тренировки
  void _addTraining(DateTime day, Training training) {
    final List<Training> newTrainings = [
      ..._schedule.trainings[day] ?? [],
      training,
    ];

    setState(() {
      _schedule.trainings[day] = newTrainings;
    });

    _saveSchedule(_schedule);
  }

  /// Удаление тренировки
  /// Принимает:
  /// - [day] - день тренировки
  /// - [training] - тренировка для удаления
  void _deleteTraining(DateTime day, Training training) {
    final List<Training> newTrainings = [...?_schedule.trainings[day]];
    newTrainings.remove(training);

    setState(() {
      if (newTrainings.isEmpty) {
        _schedule.trainings.remove(day);
      } else {
        _schedule.trainings[day] = newTrainings;
      }
    });

    _saveSchedule(_schedule);
  }

  /// Сохранение расписания тренировок в хранилище
  /// Принимает:
  /// - [schedule] - расписание для сохранения
  Future<void> _saveSchedule(TrainingSchedule schedule) async {
    setState(() => _schedule = schedule);
    try {
      final scheduleBox = await Hive.openBox<TrainingSchedule>(
        'training_schedule',
      );
      await scheduleBox.put('schedule', schedule);
      if (!mounted) return;

      // Обновляем глобальное состояние
      Provider.of<HomeScreenModel>(
        context,
        listen: false,
      ).updateSchedule(schedule);

      // УВЕДОМЛЕНИЕ ОБ УСПЕШНОМ СОХРАНЕНИИ
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Расписание обновлено!')));
    } catch (e) {
      debugPrint('Ошибка сохранения расписания: $e');
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final historyModel = Provider.of<HistoryModel>(context, listen: false);
    final homeModel = Provider.of<HomeScreenModel>(context, listen: false);
    // Синхронизируем состояние с HistoryModel
    setState(() {
      _historyList = historyModel.history;
      _isLoading = historyModel.isLoading;
      _schedule = homeModel.schedule;
    });
  }

  // Новый метод для перехода на экран просмотра PDF
  Future<void> _exportToPdf() async {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => PdfPreviewScreen(
              generatePdf:
                  () => PdfPreviewScreen.generateHistoryPdf(
                    historyList: _historyList,
                    recoveryData: widget.recoveryData,
                  ),
              fileName:
                  'history_report_${DateFormat('yyyyMMdd').format(DateTime.now())}.pdf',
            ),
      ),
    );
  }

  // Метод фильтрации истории
  List<ExerciseHistory> _filterHistory(List<ExerciseHistory> history) {
    List<ExerciseHistory> filtered = history;

    // Фильтрация по типу травмы
    if (_selectedInjuryType != "Все") {
      filtered =
          filtered
              .where((h) => h.exerciseName.contains(_selectedInjuryType))
              .toList();
    }

    // Фильтрация по периоду времени
    final now = DateTime.now();
    switch (_selectedTimePeriod) {
      case 'За неделю':
        final lastWeek = now.subtract(Duration(days: 7));
        filtered = filtered.where((h) => h.dateTime.isAfter(lastWeek)).toList();
        break;
      case 'За месяц':
        final lastMonth = now.subtract(Duration(days: 30));
        filtered =
            filtered.where((h) => h.dateTime.isAfter(lastMonth)).toList();
        break;
      default: // 'За всё время'
        // Нет фильтрации
        break;
    }

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("История упражнений"),
        backgroundColor: healthPrimaryColor,
        actions: [
          IconButton(onPressed: _exportToPdf, icon: Icon(Icons.picture_as_pdf)),
        ],
      ),
      body: RefreshIndicator(onRefresh: _loadData, child: _buildContent()),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: healthPrimaryColor),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_error!, style: TextStyle(color: Colors.red, fontSize: 16)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadData,
              child: const Text('Повторить'),
            ),
          ],
        ),
      );
    }

    // Фильтрация истории по выбранным параметрам
    List<ExerciseHistory> filteredHistory = _filterHistory(_historyList);

    if (filteredHistory.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history, size: 64, color: healthSecondaryTextColor),
            const SizedBox(height: 8),
            Text(
              'История пуста',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: healthTextColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Выполняйте упражнения, чтобы отслеживать свой прогресс',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: healthSecondaryTextColor),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Календарь (восстановленный)
        TableCalendar(
          locale: 'ru_RU',
          startingDayOfWeek: StartingDayOfWeek.monday,
          firstDay: DateTime.utc(2020, 1, 1),
          lastDay: DateTime.utc(2030, 12, 31),
          focusedDay: DateTime.now(),
          calendarStyle: CalendarStyle(
            todayDecoration: BoxDecoration(
              color: healthPrimaryColor.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            selectedDecoration: BoxDecoration(
              color: healthPrimaryColor,
              shape: BoxShape.circle,
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
            ),
          ),
          onDaySelected: (selectedDay, focusedDay) {
            setState(() {
              _selectedDay = selectedDay;
            });
            _showDayDetails(selectedDay);
          },
          selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
          calendarBuilders: CalendarBuilders(
            markerBuilder: (context, day, events) {
              final status = _getDayStatus(day, _historyList);
              return status > 0
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
        ),
        const SizedBox(height: 16),

        // Фильтры
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Expanded(
              child: DropdownButton<String>(
                value: _selectedInjuryType,
                isExpanded: true,
                items:
                    [
                          'Все',
                          'Ортопедические',
                          'Нейрохирургические',
                          'Спортивные травмы',
                          'Послеоперационная реабилитация',
                          'Хронические заболевания',
                        ]
                        .map(
                          (type) => DropdownMenuItem<String>(
                            value: type,
                            child: Text(type, overflow: TextOverflow.ellipsis),
                          ),
                        )
                        .toList(),
                onChanged:
                    (value) => setState(() => _selectedInjuryType = value!),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: DropdownButton<String>(
                value: _selectedTimePeriod,
                isExpanded: true,
                items:
                    ['За всё время', 'За неделю', 'За месяц']
                        .map(
                          (period) => DropdownMenuItem<String>(
                            value: period,
                            child: Text(
                              period,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        )
                        .toList(),
                onChanged:
                    (value) => setState(() => _selectedTimePeriod = value!),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Список истории
        Expanded(
          child: ListView.builder(
            itemCount: filteredHistory.length,
            itemBuilder:
                (context, index) => _buildHistoryItem(filteredHistory[index]),
          ),
        ),
      ],
    );
  }

  Widget _buildHistoryItem(ExerciseHistory history) {
    return Container(
      key: ValueKey(history.id),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 2)),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: healthPrimaryColor.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.fitness_center, color: healthPrimaryColor),
        ),
        title: Text(
          history.exerciseName,
          style: TextStyle(fontWeight: FontWeight.w600, color: healthTextColor),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  size: 14,
                  color: healthSecondaryTextColor,
                ),
                const SizedBox(width: 4),
                Text(
                  history.formattedDate,
                  style: TextStyle(
                    fontSize: 12,
                    color: healthSecondaryTextColor,
                  ),
                ),
                const SizedBox(width: 12),
                Icon(
                  Icons.access_time,
                  size: 14,
                  color: healthSecondaryTextColor,
                ),
                const SizedBox(width: 4),
                Text(
                  history.formattedDuration,
                  style: TextStyle(
                    fontSize: 12,
                    color: healthSecondaryTextColor,
                  ),
                ),
              ],
            ),
            if (history.painLevel > 0) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.favorite, size: 14, color: Colors.red),
                  const SizedBox(width: 4),
                  Text(
                    "Уровень боли: ${history.painLevel}/5",
                    style: TextStyle(
                      fontSize: 12,
                      color: healthSecondaryTextColor,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '${history.sets}',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: healthPrimaryColor,
              ),
            ),
            Text(
              'подходов',
              style: TextStyle(fontSize: 12, color: healthSecondaryTextColor),
            ),
          ],
        ),
      ),
    );
  }
}
