import 'package:flutter/material.dart';

import 'package:hive/hive.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';

import '../../data/models/exercise_history.dart';
import '../../data/models/home_screen_model.dart';
import '../../data/models/models.dart';
import '../../data/models/training.dart';
import '../../data/models/training_calendar_model.dart';
import '../../data/models/training_schedule.dart';
import '../../data/repositories/history_repository.dart';
import '../../services/auth_service.dart';
import '../../services/exercise_service.dart';
import 'day_schedule_bottom_sheet.dart';

class TrainingCalendarScreen extends StatefulWidget {
  final RecoveryData recoveryData;

  const TrainingCalendarScreen({required this.recoveryData});

  @override
  _TrainingCalendarScreenState createState() => _TrainingCalendarScreenState();
}

class _TrainingCalendarScreenState extends State<TrainingCalendarScreen> {
  late Box<TrainingSchedule> _scheduleBox;
  TrainingSchedule _schedule = TrainingSchedule(trainings: {}, injuryType: '');
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  bool _isLoading = true;
  String? _error;
  List<Exercise> _exercises = [];
  List<ExerciseHistory> _exerciseHistory = [];
  late HistoryRepository _historyRepo;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Слушаем изменения в модели
    Provider.of<TrainingCalendarModel>(context, listen: true).addListener(() {
      setState(() {}); // Принудительное обновление
    });
  }

  @override
  void initState() {
    super.initState();
    initializeDateFormatting('ru_RU', null);
    _initHive();
    _historyRepo = HistoryRepository(
      Provider.of<AuthService>(context, listen: false),
    );
    _loadExerciseHistory();
  }

  Future<void> _loadExerciseHistory() async {
    try {
      final history = await _historyRepo.getAllHistory();
      setState(() => _exerciseHistory = history);
    } catch (e) {
      debugPrint('Ошибка загрузки истории: $e');
    }
  }

  // Проверка выполнения всех тренировок за день
  bool _isDayCompleted(DateTime day) {
    final normalizedDay = DateTime(day.year, day.month, day.day);
    final trainings = _schedule.trainings[normalizedDay] ?? [];

    if (trainings.isEmpty) return false;

    return trainings.every((training) {
      return _exerciseHistory.any((history) {
        return history.exerciseName == training.title &&
            isSameDay(history.dateTime, training.date);
      });
    });
  }

  // Проверка выполнения конкретной тренировки
  bool _isTrainingCompleted(Training training) {
    return _exerciseHistory.any(
      (history) =>
          history.exerciseName == training.title &&
          isSameDay(history.dateTime, training.date),
    );
  }

  Future<void> _initHive() async {
    try {
      _scheduleBox = await Hive.openBox<TrainingSchedule>('training_schedule');
      _loadSchedule();
    } catch (e) {
      debugPrint('Ошибка инициализации Hive: $e');
      // При критической ошибке сбрасываем хранилище
      await _scheduleBox.deleteFromDisk();
      _scheduleBox = await Hive.openBox<TrainingSchedule>('training_schedule');
      _loadExercises();
    }
  }

  Future<void> _loadSchedule() async {
    try {
      final savedSchedule = _scheduleBox.get('schedule');
      await _loadExercises();
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

  Future<void> _loadExercises() async {
    try {
      final exerciseService = ExerciseService(
        authService: Provider.of<AuthService>(context, listen: false),
      );
      final exercises = await exerciseService.getExercises(
        injuryType: widget.recoveryData.specificInjury,
      );

      setState(() {
        _exercises = exercises;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  // Функция для определения частоты тренировок на основе типа травмы
  Map<String, dynamic> _getExerciseFrequency(String title) {
    switch (title) {
      case "Изометрическое напряжение мышц":
        return {'timesPerDay': 3, 'daysPerWeek': 7};
      case "Нейропластическая гимнастика":
        return {'timesPerDay': 2, 'daysPerWeek': 5};
      case "Пассивная разработка сустава":
        return {'timesPerDay': 2, 'daysPerWeek': 6};
      case "Дыхательная гимнастика":
        return {'timesPerDay': 5, 'daysPerWeek': 7};
      case "Тренировка мелкой моторики":
        return {'timesPerDay': 2, 'daysPerWeek': 7};
      case "Растяжка ахиллова сухожилия":
        return {'timesPerDay': 1, 'daysPerWeek': 3};
      case "Стабилизация плечевого сустава":
        return {'timesPerDay': 2, 'daysPerWeek': 4};
      case "Восстановление мышц живота":
        return {'timesPerDay': 3, 'daysPerWeek': 5};
      case "Дыхание с сопротивлением":
        return {'timesPerDay': 4, 'daysPerWeek': 7};
      case "Аквааэробика":
        return {'timesPerDay': 1, 'daysPerWeek': 3};
      case "Баланс-терапия":
        return {'timesPerDay': 2, 'daysPerWeek': 5};
      default:
        return {'timesPerDay': 1, 'daysPerWeek': 3};
    }
  }

  bool _shouldAddTraining(DateTime date, Map<String, dynamic> frequency) {
    final dayOfWeek = date.weekday;
    final timesPerDay = frequency['timesPerDay'] ?? 1;
    final daysPerWeek = frequency['daysPerWeek'] ?? 3;

    // Проверяем соответствие дню недели
    //final isTrainingDay = dayOfWeek <= daysPerWeek;

    // Для разнообразия - добавляем не все тренировки подряд
    return dayOfWeek <=
        daysPerWeek; //isTrainingDay && (date.day % (7 ~/ timesPerDay) == 0);
  }

  // Добавляем новый метод для генерации и сохранения расписания
  Future<void> _generateAndSaveSchedule(RecoveryData data) async {
    try {
      final exerciseService = ExerciseService(
        authService: Provider.of<AuthService>(context, listen: false),
      );
      final exercises = await exerciseService.getExercises(
        injuryType: widget.recoveryData.specificInjury,
      );

      final newSchedule = _generateSchedule(data);
      await _scheduleBox.put('schedule', newSchedule);

      // Обновляем состояние главного экрана
      Provider.of<HomeScreenModel>(
        context,
        listen: false,
      ).updateSchedule(newSchedule);

      setState(() => _schedule = newSchedule);
    } catch (e) {
      debugPrint('Ошибка генерации расписания: $e');
    }
  }

  // Проверяем, нужно ли добавлять тренировку в этот день
  TrainingSchedule _generateSchedule(RecoveryData data) {
    final schedule = <DateTime, List<Training>>{};

    if (_exercises.isEmpty) {
      return TrainingSchedule(trainings: {}, injuryType: data.mainInjuryType);
    }

    DateTime currentDate = DateTime.now();
    currentDate = DateTime(
      currentDate.year,
      currentDate.month,
      currentDate.day,
    );
    final endDate = currentDate.add(const Duration(days: 30)); // 12 недель

    while (currentDate.isBefore(endDate)) {
      final dayTrainings = <Training>[];

      for (final exercise in _exercises) {
        final frequency = _getExerciseFrequency(exercise.title);
        if (_shouldAddTraining(currentDate, frequency)) {
          dayTrainings.add(
            Training(
              exercise: exercise,
              date: currentDate,
              title: exercise.title,
              time: TimeOfDay(hour: 9 + dayTrainings.length, minute: 0),
            ),
          );
        }
      }

      if (dayTrainings.isNotEmpty) {
        schedule[currentDate] = dayTrainings;
      }
      currentDate = currentDate.add(const Duration(days: 1));
    }

    final newSchedule = TrainingSchedule(
      trainings: schedule,
      injuryType: data.mainInjuryType,
    );

    // Сохраняем новое расписание
    _saveSchedule(newSchedule);

    // Обновляем состояние в HomeScreen
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<HomeScreenModel>(
        context,
        listen: false,
      ).updateSchedule(newSchedule);
    });

    return newSchedule;
  }

  // Новый метод для сохранения
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

  Widget _buildCalendarMarker(DateTime date) {
    if (!_schedule.trainings.containsKey(date)) return SizedBox();

    final isCompleted = _isDayCompleted(date);
    return Icon(
      isCompleted ? Icons.check_circle : Icons.circle,
      color: isCompleted ? Colors.green : Colors.blue,
      size: 16,
    );
  }

  @override
  Widget build(BuildContext context) {
    final calendarModel = Provider.of<TrainingCalendarModel>(context);
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text('Календарь тренировок')),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: Text('Календарь тренировок')),
        body: Center(child: Text('Ошибка: $_error')),
      );
    }

    _exerciseHistory.sort((a, b) => a.dateTime.compareTo(b.dateTime));
    final firstDate = _exerciseHistory.first.dateTime;
    return Scaffold(
      appBar: AppBar(title: Text('Календарь тренировок')),
      body: Column(
        children: [
          TableCalendar(
            locale: 'ru_RU', // русская локализация в календаре
            startingDayOfWeek:
                StartingDayOfWeek.monday, // начинается с понедельника
            onFormatChanged:
                (
                  format,
                ) {}, // формат - по умолч месяц(month), есть twoWeeks → const CalendarFormat week → const CalendarFormat
            firstDay: firstDate,
            lastDay: DateTime.now().add(Duration(days: 30)),
            focusedDay: _focusedDay,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
              });
              _showDayDetails(selectedDay);
            },
            headerStyle: HeaderStyle(
              formatButtonVisible: false, // убрана кнопка для смены формата
              titleCentered: true,
            ),
            calendarBuilders: CalendarBuilders(
              todayBuilder:
                  (context, date, _) => Container(
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Center(child: Text(date.day.toString())),
                  ),
              markerBuilder: (context, date, events) {
                final trainings = _schedule.trainings[date] ?? [];
                if (trainings.isEmpty) return SizedBox();

                final completedCount =
                    trainings
                        .where(
                          (training) =>
                              calendarModel.isTrainingCompleted(training),
                        )
                        .length;

                return Container(
                  padding: EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color:
                        completedCount == trainings.length
                            ? Colors.green.withOpacity(0.3)
                            : completedCount > 0
                            ? Colors.blue.withOpacity(0.3)
                            : Colors.transparent,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    completedCount.toString(),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color:
                          completedCount == trainings.length
                              ? Colors.green
                              : Colors.blue,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

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
