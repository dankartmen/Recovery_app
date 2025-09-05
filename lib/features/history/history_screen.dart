import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:flutter/material.dart';
import '../../data/models/exercise_history.dart';
import '../../data/models/history_model.dart';
import '../../data/models/models.dart';
import '../../data/models/training_schedule.dart';
import 'package:intl/intl.dart';
import '../../styles/style.dart';
import 'pdf_preview_screen.dart';

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
  HistoryModel? _historyModel;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadHistory();
    });
  }

  Future<void> _loadHistory() async {
    debugPrint('Начало загрузки истории в HistoryScreen');
    setState(() {
      _error = null;
      _isLoading = true;
    });

    try {
      final historyModel = Provider.of<HistoryModel>(context, listen: false);
      await historyModel.loadHistory();
      debugPrint('История загружена, записей: ${historyModel.history.length}');
      setState(() {
        _historyList = historyModel.history;
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
    final plannedTrainings = widget.schedule.trainings[normalizedDay] ?? [];

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

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final historyModel = Provider.of<HistoryModel>(context, listen: false);
    // Синхронизируем состояние с HistoryModel
    setState(() {
      _historyList = historyModel.history;
      _isLoading = historyModel.isLoading;
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

  // Применение фильтров к данным
  List<ExerciseHistory> _applyFilters(List<ExerciseHistory> history) {
    var result = history;

    // Фильтр по времени
    final now = DateTime.now();
    switch (_selectedTimePeriod) {
      case 'За неделю':
        result =
            result
                .where(
                  (h) => h.dateTime.isAfter(now.subtract(Duration(days: 7))),
                )
                .toList();
        break;
      case 'За месяц':
        result =
            result
                .where(
                  (h) => h.dateTime.isAfter(now.subtract(Duration(days: 30))),
                )
                .toList();
        break;
      case 'За 3 месяца':
        result =
            result
                .where(
                  (h) => h.dateTime.isAfter(now.subtract(Duration(days: 90))),
                )
                .toList();
        break;
    }

    return result;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("История упражнений"),
        backgroundColor: healthPrimaryColor,
      ),
      body: RefreshIndicator(child: _buildHistory(), onRefresh: _loadHistory),
    );
  }

  Widget _buildContent(HistoryModel historyModel, TrainingSchedule schedule) {
    _historyList = historyModel.history;
    if (_error != null || _historyList.isEmpty) {
      return Scaffold(
        appBar: buildAppBar('История упражнений'),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.history,
                  size: 72,
                  color: healthSecondaryColor.withValues(alpha: 0.3),
                ),
                const SizedBox(height: 20),
                Text(
                  _error ?? 'История упражнений пуста',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: healthTextColor,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: _loadHistory,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: healthPrimaryColor,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
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
      );
    }

    _historyList = historyModel.history;
    return Scaffold(
      appBar: buildAppBar(
        'История упражнений',
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf, color: Colors.white),
            onPressed: _exportToPdf,
            tooltip: 'Экспорт для врача',
          ),
        ],
      ),
      body: Container(
        color: healthBackgroundColor,
        child: Column(
          children: [
            // Статистика вверху
            _buildStatsHeader(),
            const SizedBox(height: 16),

            // Фильтры
            _buildFilters(),
            const SizedBox(height: 16),

            // Таймлайн восстановления
            _buildRecoveryTimeline(),
            const SizedBox(height: 16),

            // Заголовок списка
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  Text(
                    'История упражнений',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: healthTextColor,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    'Всего: ${_historyList.length}',
                    style: TextStyle(
                      fontSize: 14,
                      color: healthSecondaryTextColor,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // Список истории
            Expanded(
              child:
                  _historyList.isEmpty
                      ? _buildEmptyState()
                      : ListView.builder(
                        padding: const EdgeInsets.only(bottom: 20),
                        itemCount: _historyList.length,
                        itemBuilder:
                            (context, index) =>
                                _buildHistoryItem(_historyList[index]),
                      ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsHeader() {
    final totalDuration = _historyList.fold<Duration>(
      Duration.zero,
      (prev, element) => prev + element.duration,
    );

    final totalSets = _historyList.fold<int>(0, (sum, item) => sum + item.sets);

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 4)),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(
            'Упражнений',
            _historyList.length.toString(),
            Icons.fitness_center,
            healthPrimaryColor,
          ),
          _buildStatItem(
            'Подходов',
            totalSets.toString(),
            Icons.repeat,
            healthSecondaryColor,
          ),
          _buildStatItem(
            'Общее время',
            '${totalDuration.inHours}ч ${totalDuration.inMinutes.remainder(60)}м',
            Icons.access_time,
            Color(0xFF6A11CB),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: healthTextColor,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: healthSecondaryTextColor),
        ),
      ],
    );
  }

  Widget _buildFilters() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: healthDividerColor),
              ),
              child: DropdownButton<String>(
                value: _selectedInjuryType,
                isExpanded: true,
                underline: const SizedBox(),
                icon: Icon(Icons.arrow_drop_down, color: healthSecondaryColor),
                style: TextStyle(color: healthTextColor),
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedInjuryType = newValue!;
                  });
                },
                items:
                    <String>[
                      'Все',
                      'Ортопедические',
                      'Нейрохирургические',
                      'Спортивные',
                      'Послеоперационные',
                      'Хронические',
                    ].map<DropdownMenuItem<String>>((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: healthDividerColor),
              ),
              child: DropdownButton<String>(
                value: _selectedTimePeriod,
                isExpanded: true,
                underline: const SizedBox(),
                icon: Icon(Icons.arrow_drop_down, color: healthSecondaryColor),
                style: TextStyle(color: healthTextColor),
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedTimePeriod = newValue!;
                  });
                },
                items:
                    <String>[
                      'За всё время',
                      'За неделю',
                      'За месяц',
                      'За 3 месяца',
                    ].map<DropdownMenuItem<String>>((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecoveryTimeline() {
    // Получаем дату первого упражнения
    if (_historyList.isEmpty) {
      return _buildEmptyTimelinePlaceholder();
    }

    final sortedHistory = List<ExerciseHistory>.from(_historyList)
      ..sort((a, b) => a.dateTime.compareTo(b.dateTime));
    final firstExerciseDate =
        sortedHistory.isNotEmpty
            ? sortedHistory.first.dateTime
            : DateTime.now();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Прогресс восстановления",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: healthTextColor,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            height: 80,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: 30,
              itemBuilder: (context, index) {
                final day = firstExerciseDate.add(Duration(days: index));
                final status = _getDayStatus(day, _historyList);
                final color = _getStatusColor(status);

                return Container(
                  width: 60,
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: healthDividerColor),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Д${index + 1}",
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: healthSecondaryTextColor,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Icon(Icons.check_circle, color: color, size: 24),
                      const SizedBox(height: 2),
                      Text(
                        DateFormat('dd.MM').format(day),
                        style: TextStyle(
                          fontSize: 10,
                          color: healthSecondaryTextColor,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildStatusIndicator(Colors.green, 'Выполнено'),
              const SizedBox(width: 16),
              _buildStatusIndicator(Colors.yellow, 'Частично'),
              const SizedBox(width: 16),
              _buildStatusIndicator(Colors.grey, 'Не выполнено'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyTimelinePlaceholder() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 4)),
        ],
      ),
      child: Column(
        children: [
          Icon(Icons.history_toggle_off, size: 40, color: healthSecondaryColor),
          const SizedBox(height: 8),
          Text(
            'Начните выполнять упражнения, чтобы отслеживать прогресс',
            textAlign: TextAlign.center,
            style: TextStyle(color: healthSecondaryTextColor),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusIndicator(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: healthSecondaryTextColor),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.history,
              size: 72,
              color: healthSecondaryColor.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 20),
            Text(
              'История упражнений пуста',
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
      ),
    );
  }

  Widget _buildHistory() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_error!, style: TextStyle(color: Colors.red, fontSize: 16)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadHistory,
              child: const Text('Повторить'),
            ),
          ],
        ),
      );
    }
    if (_historyList.isEmpty) {
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

    return ListView.builder(
      itemCount: _historyList.length,
      itemBuilder: (context, index) => _buildHistoryItem(_historyList[index]),
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
