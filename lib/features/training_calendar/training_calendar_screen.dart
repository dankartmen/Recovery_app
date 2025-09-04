import 'package:auth_test/data/models/exercise_list_model.dart';
import 'package:flutter/material.dart';

import 'package:hive/hive.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';

import '../../data/models/exercise_history.dart';
import '../../data/models/history_model.dart';
import '../../data/models/home_screen_model.dart';
import '../../data/models/models.dart';
import '../../data/models/training.dart';
import '../../data/models/training_calendar_model.dart';
import '../../data/models/training_schedule.dart';
import '../../styles/style.dart';
import 'day_schedule_bottom_sheet.dart';

/// {@template training_calendar_screen}
/// Экран календаря тренировок для просмотра и управления расписанием занятий.
/// Отображает календарь с отметками о запланированных и выполненных тренировках.
/// {@endtemplate}
class TrainingCalendarScreen extends StatefulWidget {
  /// Данные о восстановлении для инициализации календаря
  final RecoveryData recoveryData;

  /// {@macro training_calendar_screen}
  const TrainingCalendarScreen({super.key, required this.recoveryData});

  @override
  TrainingCalendarScreenState createState() => TrainingCalendarScreenState();
}

class TrainingCalendarScreenState extends State<TrainingCalendarScreen> {
  /// Hive box для хранения расписания тренировок
  late Box<TrainingSchedule> _scheduleBox;

  /// Текущее расписание тренировок
  TrainingSchedule _schedule = TrainingSchedule(trainings: {}, injuryType: '');

  /// Текущий сфокусированный день в календаре
  DateTime _focusedDay = DateTime.now();

  /// Выбранный день в календаре
  DateTime? _selectedDay;

  /// Флаг загрузки данных
  bool _isLoading = true;

  /// Сообщение об ошибке при загрузке
  String? _error;

  /// Список доступных упражнений
  List<Exercise> _exercises = [];

  /// История выполненных упражнений
  List<ExerciseHistory> _exerciseHistory = [];

  /// Флаг загрузки истории тренировок
  bool _isHistoryLoaded = false;

  @override
  void initState() {
    super.initState();
    // Инициализация локализации для форматирования дат
    initializeDateFormatting('ru_RU', null);
    _initHive();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Загрузка истории тренировок при первом изменении зависимостей
    if (!_isHistoryLoaded) {
      _loadExerciseHistory();
      _isHistoryLoaded = true;
    }
  }

  /// Загрузка истории выполненных упражнений
  Future<void> _loadExerciseHistory() async {
    try {
      debugPrint("Загружаю историю в trainingCalendarScreenState");
      final historyModel = Provider.of<HistoryModel>(context);
      final historyList = historyModel.history;
      setState(() => _exerciseHistory = historyList);
    } catch (e) {
      debugPrint('Ошибка загрузки истории: $e');
    }
  }

  /// Инициализация Hive хранилища
  Future<void> _initHive() async {
    try {
      _scheduleBox = await Hive.openBox<TrainingSchedule>('training_schedule');
      _loadSchedule();
    } catch (e) {
      debugPrint('Ошибка инициализации Hive: $e');
      // При критической ошибке сбрасываем хранилище
      await _scheduleBox.deleteFromDisk();
      _scheduleBox = await Hive.openBox<TrainingSchedule>('training_schedule');
    }
  }

  /// Загрузка расписания тренировок из хранилища
  Future<void> _loadSchedule() async {
    try {
      final savedSchedule = _scheduleBox.get('schedule');
      if (savedSchedule != null) {
        setState(() {
          _schedule = savedSchedule;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Ошибка загрузки расписания: $e');
    }
  }

  /// Сохранение расписания тренировок в хранилище
  /// Принимает:
  /// - [schedule] - расписание для сохранения
  void _saveSchedule(TrainingSchedule schedule) {
    setState(() => _schedule = schedule);
    try {
      _scheduleBox.put('schedule', schedule);
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
  Widget build(BuildContext context) {
    final calendarModel = context.watch<TrainingCalendarModel>();

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text(
            'Календарь тренировок',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          backgroundColor: healthPrimaryColor,
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: Container(
          color: healthBackgroundColor,
          child: const Center(
            child: CircularProgressIndicator(color: healthPrimaryColor),
          ),
        ),
      );
    }

    if (_error != null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text(
            'Календарь тренировок',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          backgroundColor: healthPrimaryColor,
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: Container(
          color: healthBackgroundColor,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 20),
                  Text(
                    'Ошибка загрузки календаря',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: healthTextColor,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _error!,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: healthSecondaryTextColor,
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _initHive,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: healthPrimaryColor,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 14,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Попробовать снова',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    // Сортировка истории тренировок по дате
    _exerciseHistory.sort((a, b) => a.dateTime.compareTo(b.dateTime));
    final firstDate =
        _exerciseHistory.isNotEmpty
            ? _exerciseHistory.first.dateTime
            : DateTime.now().subtract(const Duration(days: 30));

    final exerciseListModel = Provider.of<ExerciseListModel>(
      context,
      listen: false,
    );
    _exercises = exerciseListModel.exercises;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Календарь тренировок',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: healthPrimaryColor,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Container(
        color: healthBackgroundColor,
        child: Column(
          children: [
            // Статистика
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  _buildStatCard(
                    'Тренировок',
                    _schedule.trainings.values
                        .fold(0, (sum, list) => sum + list.length)
                        .toString(),
                    healthPrimaryColor,
                  ),
                  const SizedBox(width: 12),
                  _buildStatCard(
                    'Выполнено',
                    _exerciseHistory.length.toString(),
                    healthSecondaryColor,
                  ),
                ],
              ),
            ),

            // Календарь
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: TableCalendar(
                    locale: 'ru_RU',
                    startingDayOfWeek: StartingDayOfWeek.monday,
                    firstDay: firstDate,
                    lastDay: DateTime.now().add(const Duration(days: 60)),
                    focusedDay: _focusedDay,
                    selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                    onDaySelected: (selectedDay, focusedDay) {
                      setState(() {
                        _selectedDay = selectedDay;
                        _focusedDay = focusedDay;
                      });
                      _showDayDetails(selectedDay);
                    },
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
                    calendarBuilders: CalendarBuilders(
                      defaultBuilder: (context, day, focusedDay) {
                        return Container(
                          margin: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border:
                                isSameDay(day, DateTime.now())
                                    ? Border.all(
                                      color: healthPrimaryColor,
                                      width: 1.5,
                                    )
                                    : null,
                          ),
                          child: Center(
                            child: Text(
                              day.day.toString(),
                              style: TextStyle(
                                color: _getDayColor(day),
                                fontWeight:
                                    isSameDay(day, DateTime.now())
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                              ),
                            ),
                          ),
                        );
                      },
                      todayBuilder: (context, day, focusedDay) {
                        return Container(
                          margin: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: healthPrimaryColor.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: healthPrimaryColor,
                              width: 1.5,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              day.day.toString(),
                              style: TextStyle(
                                color: healthPrimaryColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        );
                      },
                      markerBuilder: (context, date, events) {
                        final trainings = _schedule.trainings[date] ?? [];
                        if (trainings.isEmpty) return const SizedBox();

                        final completedCount =
                            trainings
                                .where(
                                  (training) => calendarModel
                                      .isTrainingCompleted(training),
                                )
                                .length;

                        final color =
                            completedCount == trainings.length
                                ? Colors.green
                                : completedCount > 0
                                ? healthPrimaryColor
                                : Colors.grey;

                        return Positioned(
                          bottom: 1,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '$completedCount/${trainings.length}',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: color,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),

            // Подсказка
            Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: healthPrimaryColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text('Сегодня', style: TextStyle(fontSize: 14)),
                  const SizedBox(width: 16),
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text('Выполнено', style: TextStyle(fontSize: 14)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Получение цвета для дня в календаре
  /// Принимает:
  /// - [day] - день для определения цвета
  /// Возвращает:
  /// - цвет текста для указанного дня
  Color _getDayColor(DateTime day) {
    if (day.weekday == DateTime.saturday || day.weekday == DateTime.sunday) {
      return Colors.red[300]!;
    }
    return healthTextColor;
  }

  /// Построение карточки статистики
  /// Принимает:
  /// - [title] - заголовок карточки
  /// - [value] - значение статистики
  /// - [color] - цвет акцента карточки
  /// Возвращает:
  /// - виджет карточки статистики
  Widget _buildStatCard(String title, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(fontSize: 14, color: healthSecondaryTextColor),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Показ деталей дня (нижний лист с тренировками)
  /// Принимает:
  /// - [day] - день для отображения деталей
  void _showDayDetails(DateTime day) {
    final normalizedDay = DateTime(day.year, day.month, day.day);

    final dayTrainings = _schedule.trainings[normalizedDay] ?? [];
    final calendarModel = Provider.of<TrainingCalendarModel>(
      context,
      listen: false,
    );
    debugPrint(
      'Запрошены тренировки на ${DateFormat('dd.MM.yyyy').format(normalizedDay)}: ${dayTrainings.length}',
    );

    showModalBottomSheet(
      context: context,
      builder:
          (context) => DayScheduleBottomSheet(
            filteredExercises: _exercises,
            day: normalizedDay,
            getTrainingsForDay: () => dayTrainings,
            onAdd: (training) => _addTraining(normalizedDay, training),
            onDelete: (training) => _deleteTraining(normalizedDay, training),
            onUpdate:
                (oldTraining, newTraining) =>
                    _updateTraining(normalizedDay, oldTraining, newTraining),
            isTrainingCompleted: calendarModel.isTrainingCompleted,
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
}
