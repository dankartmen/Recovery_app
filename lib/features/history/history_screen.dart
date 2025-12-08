import '../../data/models/exercise_list_model.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:flutter/material.dart';
//import 'package:hive/hive.dart';
import '../../data/models/exercise_history.dart';
import '../../data/models/history_model.dart';
import '../../data/models/models.dart';
import '../../data/models/training.dart';
import '../../data/models/training_calendar_model.dart';
import '../../data/models/training_schedule.dart';
import '../../data/models/home_screen_model.dart';
import 'package:intl/intl.dart';
import '../../core/styles/style.dart';
import '../../exercises/models/exercise.dart';
import 'pdf_preview_screen.dart';
import '../training_calendar/day_schedule_bottom_sheet.dart';

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
  bool _isLoading = true;
  String? _error;
  List<Exercise> _exercises = []; // Для добавления тренировок

  /// Выбранный день в календаре
  DateTime? _selectedDay;

  TrainingSchedule? _schedule;

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

      if(!mounted) return;
      // Загрузка расписания через модель
      final trainingCalendarModel = Provider.of<TrainingCalendarModel>(context, listen: false);
      await trainingCalendarModel.loadCurrentSchedule(); // Загрузка с сервера
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

      if(!mounted) return;
      // Подтягиваем расписание из HomeScreenModel (или use trainingCalendarModel.currentSchedule)
      final homeModel = Provider.of<HomeScreenModel>(context, listen: false);
      _schedule = homeModel.schedule ?? trainingCalendarModel.currentSchedule;

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

  /// Показ деталей дня (нижний лист с тренировками)
  /// Принимает:
  /// - [day] - день для отображения деталей
  void _showDayDetails(DateTime day) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DayScheduleBottomSheet(
        day: day,
        getTrainingsForDay: () => _getTrainingsForDay(day), 
        filteredExercises: _exercises, // Из _loadData
        onAdd: null, // Опционально, модель обновит UI
        onDelete: null,
        onUpdate: null,
        isReadOnly: false,
        trainingCalendarModel: Provider.of<TrainingCalendarModel>(context, listen: false),
      ),
    ).then((_) => setState(() {})); // Обновить UI после закрытия
  }

  Future<List<Training>> _getTrainingsForDay(DateTime day) async {
    final trainingCalendarModel = Provider.of<TrainingCalendarModel>(context, listen: false);
    return trainingCalendarModel.getTrainingsForDay(day).then((list) => list); // Адаптируйте под async если нужно
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
    if (_schedule == null) return;
    final list = _schedule!.trainings[day];
    if (list == null) return;
    final index = list.indexOf(oldTraining);

    if (index >= 0) {
      setState(() {
        _schedule!.trainings[day]![index] = newTraining;
      });
      //_saveSchedule(_schedule!);
    }
  }

  

  /// Удаление тренировки
  /// Принимает:
  /// - [day] - день тренировки
  /// - [training] - тренировка для удаления
  void _deleteTraining(DateTime day, Training training) {
    if (_schedule == null) return;
    final List<Training> newTrainings = [...?_schedule!.trainings[day]];
    newTrainings.remove(training);

    setState(() {
      if (newTrainings.isEmpty) {
        _schedule!.trainings.remove(day);
      } else {
        _schedule!.trainings[day] = newTrainings;
      }
    });

    //_saveSchedule(_schedule!);
  }

  /// Сохранение расписания тренировок в хранилище
  /// Принимает:
  /// - [schedule] - расписание для сохранения
  // Future<void> _saveSchedule(TrainingSchedule schedule) async {
  //   setState(() => _schedule = schedule);
  //   try {
  //     final scheduleBox = await Hive.openBox<TrainingSchedule>(
  //       'training_schedule',
  //     );
  //     await scheduleBox.put('schedule', schedule);
  //     if (!mounted) return;

  //     // Обновляем глобальное состояние
  //     Provider.of<HomeScreenModel>(
  //       context,
  //       listen: false,
  //     ).updateSchedule(schedule);

  //     // УВЕДОМЛЕНИЕ ОБ УСПЕШНОМ СОХРАНЕНИИ
  //     ScaffoldMessenger.of(
  //       context,
  //     ).showSnackBar(SnackBar(content: Text('Расписание обновлено!')));
  //   } catch (e) {
  //     debugPrint('Ошибка сохранения расписания: $e');
  //   }
  // }

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
          filtered.where((h) {
            // Находим упражнение в списке по названию
            final exercise = _exercises.firstWhere(
              (e) => e.title == h.exerciseName,
              orElse:
                  () => Exercise(
                    id: null,
                    title: '',
                    generalDescription: '',
                    suitableFor: [],
                    maxPainLevel: 0,
                    steps: [],
                    tags: [],
                  ),
            );

            // Проверяем, есть ли пересечение с подтипами выбранной категории травм
            final categorySpecifics =
                injuryCategories[_selectedInjuryType] ?? [];
            return exercise.suitableFor.any(
              (suitable) => categorySpecifics.contains(suitable),
            );
          }).toList();
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

  Widget _buildStatsSection() {
    final filteredHistory = _filterHistory(_historyList);
    final totalWorkouts = filteredHistory.length;
    final totalDuration = filteredHistory.fold(
      Duration.zero,
      (sum, item) => sum + item.duration,
    );
    final avgPainLevel =
        filteredHistory.isEmpty
            ? 0
            : filteredHistory.map((e) => e.painLevel).reduce((a, b) => a + b) /
                totalWorkouts;

    return Container(
      margin: EdgeInsets.all(16),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 2)),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem('Тренировки', '$totalWorkouts', Icons.fitness_center),
          _buildStatItem(
            'Время',
            '${totalDuration.inHours}ч',
            Icons.access_time,
          ),
          _buildStatItem(
            'Боль',
            '${avgPainLevel.toStringAsFixed(1)}/5',
            Icons.favorite,
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String title, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: healthPrimaryColor, size: 20),
        SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        Text(
          title,
          style: TextStyle(fontSize: 12, color: healthSecondaryTextColor),
        ),
      ],
    );
  }

  Widget _buildHistoryItem(ExerciseHistory history) {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _showDayDetails(history.dateTime),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Row(
            children: [
              // Иконка с цветом по уровню боли
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: _getPainColor(
                    history.painLevel,
                  ).withValues(alpha:0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.fitness_center,
                  color: _getPainColor(history.painLevel),
                  size: 24,
                ),
              ),
              SizedBox(width: 16),

              // Основная информация
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      history.exerciseName,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                        color: healthTextColor,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 4),

                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today,
                          size: 14,
                          color: healthSecondaryTextColor,
                        ),
                        SizedBox(width: 4),
                        Text(
                          history.formattedDate,
                          style: TextStyle(
                            fontSize: 12,
                            color: healthSecondaryTextColor,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Метрики
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Chip(
                    label: Text('${history.sets} подходов'),
                    backgroundColor: healthPrimaryColor.withValues(alpha:0.1),
                    labelStyle: TextStyle(
                      color: healthPrimaryColor,
                      fontSize: 12,
                    ),
                  ),
                  if (history.painLevel > 0)
                    Text(
                      'Боль: ${history.painLevel}/5',
                      style: TextStyle(
                        fontSize: 12,
                        color: _getPainColor(history.painLevel),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFiltersSection() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: Colors.grey[50],
      child: Row(
        children: [
          Expanded(
            child: FilterChip(
              label: Text(_selectedTimePeriod),
              selected: true,
              onSelected: (_) => _showTimePeriodDialog(),
              backgroundColor: healthPrimaryColor.withValues(alpha:0.1),
              labelStyle: TextStyle(color: healthPrimaryColor),
            ),
          ),
          SizedBox(width: 8),
          Expanded(
            child: FilterChip(
              label: Text(_selectedInjuryType),
              selected: true,
              onSelected: (_) => _showInjuryTypeDialog(),
              backgroundColor: healthPrimaryColor.withValues(alpha:0.1),
              labelStyle: TextStyle(color: healthPrimaryColor),
            ),
          ),
        ],
      ),
    );
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

  SliverList _buildHistoryList() {
    final filteredHistory = _filterHistory(_historyList);

    if (filteredHistory.isEmpty) {
      return SliverList(
        delegate: SliverChildListDelegate([_buildEmptyState()]),
      );
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) => _buildHistoryItem(filteredHistory[index]),
        childCount: filteredHistory.length,
      ),
    );
  }

  // Диалог выбора периода времени
  void _showTimePeriodDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Выберите период'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  title: Text('За всё время'),
                  onTap: () {
                    setState(() => _selectedTimePeriod = 'За всё время');
                    Navigator.pop(context);
                  },
                ),
                ListTile(
                  title: Text('За неделю'),
                  onTap: () {
                    setState(() => _selectedTimePeriod = 'За неделю');
                    Navigator.pop(context);
                  },
                ),
                ListTile(
                  title: Text('За месяц'),
                  onTap: () {
                    setState(() => _selectedTimePeriod = 'За месяц');
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
          ),
    );
  }

  // Диалог выбора типа травмы
  void _showInjuryTypeDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Выберите тип травмы'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    title: Text('Все'),
                    onTap: () {
                      setState(() => _selectedInjuryType = 'Все');
                      Navigator.pop(context);
                    },
                  ),
                  ListTile(
                    title: Text('Ортопедические'),
                    onTap: () {
                      setState(() => _selectedInjuryType = 'Ортопедические');
                      Navigator.pop(context);
                    },
                  ),
                  ListTile(
                    title: Text('Нейрохирургические'),
                    onTap: () {
                      setState(
                        () => _selectedInjuryType = 'Нейрохирургические',
                      );
                      Navigator.pop(context);
                    },
                  ),
                  ListTile(
                    title: Text('Спортивные травмы'),
                    onTap: () {
                      setState(() => _selectedInjuryType = 'Спортивные травмы');
                      Navigator.pop(context);
                    },
                  ),
                  ListTile(
                    title: Text('Послеоперационная реабилитация'),
                    onTap: () {
                      setState(
                        () =>
                            _selectedInjuryType =
                                'Послеоперационная реабилитация',
                      );
                      Navigator.pop(context);
                    },
                  ),
                  ListTile(
                    title: Text('Хронические заболевания'),
                    onTap: () {
                      setState(
                        () => _selectedInjuryType = 'Хронические заболевания',
                      );
                      Navigator.pop(context);
                    },
                  ),
                ],
              ),
            ),
          ),
    );
  }


  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("История тренировок"),
        backgroundColor: healthPrimaryColor,
        actions: [
          IconButton(
            icon: Icon(Icons.picture_as_pdf),
            onPressed: _exportToPdf,
            tooltip: 'Экспорт в PDF',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: AnimatedSwitcher(
          duration: Duration(milliseconds: 300),
          child:
              _isLoading
                  ? _buildLoadingState()
                  : _error != null
                  ? _buildErrorState()
                  : CustomScrollView(
                    key: ValueKey(
                      'history_list_${_selectedTimePeriod}_$_selectedInjuryType',
                    ),
                    slivers: [
                      // Календарь
                      SliverToBoxAdapter(child: _buildCalendarSection()),

                      // Фильтры
                      SliverToBoxAdapter(child: _buildFiltersSection()),

                      // Статистика
                      SliverToBoxAdapter(child: _buildStatsSection()),

                      // Заголовок списка
                      SliverPadding(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        sliver: SliverToBoxAdapter(
                          child: Text(
                            'Последние тренировки',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: healthTextColor,
                            ),
                          ),
                        ),
                      ),

                      // Список истории
                      _buildHistoryList(),
                    ],
                  ),
        ),
      ),
    );
  }

  // Новые вспомогательные методы
  Widget _buildCalendarSection() {
    return Container(
      padding: EdgeInsets.all(16),
      child: TableCalendar(
        locale: 'ru_RU',
        startingDayOfWeek: StartingDayOfWeek.monday,
        firstDay: DateTime.utc(2020, 1, 1),
        lastDay: DateTime.utc(2030, 12, 31),
        focusedDay: DateTime.now(),
        calendarStyle: CalendarStyle(
          todayDecoration: BoxDecoration(
            color: healthPrimaryColor.withValues(alpha:0.2),
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
          leftChevronIcon: Icon(Icons.chevron_left, color: healthPrimaryColor),
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
    );
  }

  Widget _buildLoadingState() {
    return Center(child: CircularProgressIndicator(color: healthPrimaryColor));
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(_error!, style: TextStyle(color: Colors.red, fontSize: 16)),
          SizedBox(height: 16),
          ElevatedButton(onPressed: _loadData, child: const Text('Повторить')),
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
          SizedBox(height: 16),
          Text(
            'История пуста',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: healthTextColor,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Выполняйте упражнения, чтобы отслеживать свой прогресс',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: healthSecondaryTextColor),
          ),
        ],
      ),
    );
  }
}
