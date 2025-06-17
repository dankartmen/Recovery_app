import 'dart:typed_data';

import 'package:open_file/open_file.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import '../../data/models/exercise_history.dart';
import '../../data/models/history_model.dart';
import '../../data/models/home_screen_model.dart';
import '../../data/models/models.dart';
import '../../data/models/training.dart';
import '../../data/models/training_schedule.dart';
import '../../data/repositories/history_repository.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../data/repositories/questionnaire_repository.dart';
import '../../services/auth_service.dart';

// Экран истории выполненных упражнений
class HistoryScreen extends StatefulWidget {
  final RecoveryData recoveryData;
  final TrainingSchedule schedule;

  const HistoryScreen({
    required this.recoveryData,
    required this.schedule,
    Key? key,
  }) : super(key: key);
  @override
  _HistoryScreenState createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  late HistoryRepository _repository;
  String _selectedInjuryType = "Все";
  String _selectedTimePeriod = "За всё время";
  final AuthService _authService = AuthService();
  DateTime? _firstExerciseDate;
  List<ExerciseHistory> _history = [];
  List<ExerciseHistory> _historyList = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadHistory();
    });
  }

  void _loadHistory() {
    final historyModel = Provider.of<HistoryModel>(context, listen: false);
    if (!historyModel.isInitialized) {
      historyModel.loadHistory();
    }
  }

  @override
  void dispose() {
    // Отписываемся при уничтожении виджета
    final historyModel = Provider.of<HistoryModel>(context, listen: false);
    historyModel.removeListener(_refreshHistory);
    super.dispose();
  }

  // Определение статуса дня
  int _getDayStatus(DateTime day, List<ExerciseHistory> history) {
    final normalizedDay = DateTime(day.year, day.month, day.day);
    //final now = DateTime.now();

    // Будущие дни всегда серые
    //if (day.isAfter(now)) return 0;
    // 1. Проверяем выполненные упражнения за день
    final completedExercises =
        history
            .where((h) => isSameDay(h.dateTime, normalizedDay))
            .map((h) => h.exerciseName)
            .toSet();

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

  // Построение индикатора дня
  Widget _buildDayProgress(int dayIndex) {
    if (_historyList.isEmpty) {
      return _buildDayContainer(dayIndex, Colors.grey);
    }
    final now = DateTime.now();
    _historyList.sort((a, b) => a.dateTime.compareTo(b.dateTime));
    final firstDate = _historyList.first.dateTime;
    final currentDate = firstDate.add(Duration(days: dayIndex));

    /*
    final currentDate = now
        .subtract(Duration(days: now.weekday - 1))
        .add(Duration(days: dayIndex)); // Понедельник текущей недели + dayIndex
*/
    // Проверка на будущее
    if (currentDate.isAfter(now)) {
      return _buildDayContainer(dayIndex, Colors.grey); // Будущие дни - серые
    }

    final status = _getDayStatus(currentDate, _historyList);

    return _buildDayContainer(dayIndex, _getStatusColor(status));
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

  Widget _buildDayContainer(int dayIndex, Color color) {
    return Container(
      width: 60,
      margin: const EdgeInsets.only(right: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            "Д${dayIndex + 1}",
            style: const TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 4),
          Icon(Icons.check_circle, color: color),
        ],
      ),
    );
  }

  Future<int> _deleteHistory(int id) async {
    final result = await _repository.deleteHistory(id);
    if (result > 0) _refreshHistory();
    return result;
  }

  LineChartData _buildProgressChart(List<ExerciseHistory> history) {
    // Сортируем по дате
    history.sort((a, b) => a.dateTime.compareTo(b.dateTime));

    // Агрегируем данные по дням
    Map<DateTime, Duration> dailyDurations = {};
    for (var exercise in history) {
      final date = DateTime(
        exercise.dateTime.year,
        exercise.dateTime.month,
        exercise.dateTime.day,
      );
      if (dailyDurations.containsKey(date)) {
        dailyDurations[date] = dailyDurations[date]! + exercise.duration;
      } else {
        dailyDurations[date] = exercise.duration;
      }
    }

    // Получаем список дат и суммарной длительности
    final dates = dailyDurations.keys.toList();
    final durations = dailyDurations.values.toList();

    return LineChartData(
      lineTouchData: LineTouchData(enabled: true),
      titlesData: FlTitlesData(
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            interval: 1, // Интервал между днями
            getTitlesWidget: (value, meta) {
              final date = dates[value.toInt()];
              return Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text(
                  DateFormat('dd.MM').format(date), // Отображаем дату
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
              );
            },
          ),
        ),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            getTitlesWidget:
                (value, meta) => Text(
                  '${value.toInt()}', // Общая длительность в секундах
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
          ),
        ),
      ),
      lineBarsData: [
        LineChartBarData(
          spots: List.generate(dates.length, (index) {
            return FlSpot(
              index.toDouble(),
              durations[index].inSeconds.toDouble(),
            ); // Общая длительность в секундах
          }),
          isCurved: true,
          color: Colors.blue,
          barWidth: 3,
          dotData: FlDotData(show: false), // Не отображаем точки
          belowBarData: BarAreaData(
            show: true,
            color: Colors.blue.withOpacity(0.1),
          ),
        ),
      ],
    );
  }

  // Вычисление прогресса за неделю (от 0 до 1)
  double _calculateWeeklyProgress(List<ExerciseHistory> history) {
    final now = DateTime.now();
    final weekAgo = now.subtract(Duration(days: 7));

    // Фильтруем упражнения за последнюю неделю
    final recentExercises =
        history.where((h) => h.dateTime.isAfter(weekAgo)).toList();

    // Суммируем длительность за неделю
    final totalDuration = recentExercises.fold<Duration>(
      Duration.zero,
      (previousValue, element) => previousValue + element.duration,
    );

    // Для примера: считаем прогресс относительно 5 часов (18000 секунд)
    const maxDuration = Duration(hours: 5);
    final progress = totalDuration.inSeconds / maxDuration.inSeconds;

    return progress.clamp(0.0, 1.0);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _refreshHistory();
  }

  // Обновляем метод обновления истории
  void _refreshHistory() {
    setState(() {
      // Принудительно обновляем состояние при изменении модели
    });
  }

  Future<pw.Font> _loadFont() async {
    final fontData = await rootBundle.load('assets/fonts/Roboto-Regular.ttf');
    return pw.Font.ttf(fontData);
  }
  // Метод для генерации PDF и возврата Uint8List
  // В history_screen.dart

  Future<Uint8List> _generatePdf(List<ExerciseHistory> historyList) async {
    final pdf = pw.Document();

    // Загружаем шрифт
    final ttf = await _loadFont();

    final headerStyle = pw.TextStyle(
      font: ttf,
      fontSize: 16,
      fontWeight: pw.FontWeight.bold,
      color: PdfColors.blue800,
    );

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: pw.EdgeInsets.all(32),
        build:
            (context) => [
              pw.Row(
                children: [
                  pw.SizedBox(width: 20),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'Отчет о реабилитационных упражнениях',
                        style: pw.TextStyle(
                          font: ttf,
                          fontSize: 22,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.blue900,
                        ),
                      ),
                      pw.Text(
                        'Сгенерировано: ${DateFormat('dd.MM.yyyy HH:mm').format(DateTime.now())}',
                        style: pw.TextStyle(
                          font: ttf,
                          fontSize: 10,
                          color: PdfColors.grey600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              pw.SizedBox(height: 20),

              // Информация о пациенте
              pw.Container(
                padding: pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.blue200),
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('Данные пациента:', style: headerStyle),
                    pw.SizedBox(height: 8),
                    _buildUserInfoRow(
                      'ФИО',
                      _formatUserValue(widget.recoveryData.name),
                      ttf,
                    ),
                    _buildUserInfoRow(
                      'Пол',
                      _formatUserValue(widget.recoveryData.gender),
                      ttf,
                    ),
                    _buildUserInfoRow(
                      'Рост/Вес',
                      '${_formatUserValue(widget.recoveryData.height)} см / ${_formatUserValue(widget.recoveryData.weight)} кг',
                      ttf,
                    ),
                    _buildUserInfoRow(
                      'Основная травма',
                      _formatUserValue(widget.recoveryData.mainInjuryType),
                      ttf,
                    ),
                    _buildUserInfoRow(
                      'Конкретная травма',
                      _formatUserValue(widget.recoveryData.specificInjury),
                      ttf,
                    ),
                  ],
                ),
              ),

              pw.SizedBox(height: 20),

              // Сводная статистика
              pw.Container(
                padding: pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.blue200),
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('Общая статистика:', style: headerStyle),
                    pw.SizedBox(height: 8),
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        _buildStatItem(
                          'Всего упражнений',
                          historyList.length.toString(),
                          ttf,
                        ),
                        _buildStatItem(
                          'Общее время',
                          _formatTotalDuration(historyList),
                          ttf,
                        ),
                        _buildStatItem(
                          'Средний уровень боли',
                          _calculateAveragePain(historyList),
                          ttf,
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              pw.SizedBox(height: 20),

              pw.Text('История выполнения:', style: headerStyle),
              pw.SizedBox(height: 10),
              // Таблица с фиксированной шириной столбцов
              pw.Table(
                border: pw.TableBorder.all(
                  color: PdfColors.grey300,
                  width: 0.5,
                ),
                columnWidths: {
                  0: pw.FixedColumnWidth(40), // Дата
                  1: pw.FlexColumnWidth(3), // Упражнение
                  2: pw.FixedColumnWidth(35), // Время
                  3: pw.FixedColumnWidth(30), // Подходы
                  4: pw.FixedColumnWidth(30), // Боль
                  5: pw.FlexColumnWidth(2), // Заметки
                },
                children: [
                  // Заголовок таблицы
                  pw.TableRow(
                    decoration: pw.BoxDecoration(
                      color: PdfColors.blue50,
                      borderRadius: pw.BorderRadius.circular(4),
                    ),
                    children: [
                      _buildTableCell('Дата', ttf),
                      _buildTableCell('Упражнение', ttf),
                      _buildTableCell('Время', ttf),
                      _buildTableCell('Подх.', ttf),
                      _buildTableCell('Боль', ttf),
                      _buildTableCell('Заметки', ttf),
                    ],
                  ),
                  // Данные
                  for (var history in historyList)
                    pw.TableRow(
                      verticalAlignment: pw.TableCellVerticalAlignment.middle,
                      children: [
                        _buildTableCell(
                          history.formattedDate.split(' ')[0],
                          ttf,
                        ), // Только дата
                        _buildTableCell(history.exerciseName, ttf),
                        _buildTableCell(
                          history.formattedDuration.replaceAll(':', '.'),
                          ttf,
                        ), // 04.00 вместо 04:00
                        _buildTableCell(history.sets.toString(), ttf),
                        _buildTableCell(
                          history.painLevel > 0
                              ? '${history.painLevel}/5'
                              : '-',
                          ttf,
                        ),
                        _buildTableCell(history.notes ?? '-', ttf),
                      ],
                    ),
                ],
              ),
              pw.SizedBox(height: 20),

              // Прогресс
              /*pw.Text('Прогресс реабилитации:', style: headerStyle),
              pw.SizedBox(height: 10),
              pw.Container(
                height: 30,
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey300),
                  borderRadius: pw.BorderRadius.circular(4),
                ),
                child: pw.Stack(
                  children: [
                    pw.Container(
                      width: _calculateWeeklyProgress(historyList) * 500,
                      decoration: pw.BoxDecoration(
                        color: PdfColors.green300,
                        borderRadius: pw.BorderRadius.circular(4),
                      ),
                    ),
                    pw.Center(
                      child: pw.Text(
                        'Прогресс: ${(_calculateWeeklyProgress(historyList) * 100).toStringAsFixed(1)}%',
                        style: pw.TextStyle(
                          font: ttf,
                          color: PdfColors.grey800,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 30),
              */
              pw.SizedBox(height: 30),
              pw.Divider(),
              pw.Center(
                child: pw.Text(
                  'Сгенерировано в приложении RehabHelper',
                  style: headerStyle,
                ),
              ),
            ],
      ),
    );

    return pdf.save();
  }

  // Метод для получения данных пациента
  Future<RecoveryData> _getUserInfo() async {
    try {
      final questionnaireRepo = QuestionnaireRepository();
      return await questionnaireRepo.getLatestQuestionnaire() ??
          RecoveryData.empty();
    } catch (e) {
      return RecoveryData.empty();
    }
  }

  // Обработка отсутствия данных
  String _formatUserValue(dynamic value) {
    if (value == null) return 'Не указано';
    if (value is String && value.isEmpty) return 'Не указано';
    if (value is num && value == 0) return 'Не указано';
    return value.toString();
  }

  // Метод для создания строки информации о пациенте
  pw.Widget _buildUserInfoRow(String label, String value, pw.Font font) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            '$label: ',
            style: pw.TextStyle(font: font, fontWeight: pw.FontWeight.bold),
          ),
          pw.Expanded(child: pw.Text(value, style: pw.TextStyle(font: font))),
        ],
      ),
    );
  }

  // Метод для создания ячейки таблицы
  pw.Widget _buildTableCell(String text, pw.Font font) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(4),
      child: pw.Text(
        text,
        style: pw.TextStyle(font: font, fontSize: 9),
        textAlign: pw.TextAlign.center,
        maxLines: 2,
      ),
    );
  }

  // Метод для создания элемента статистики
  pw.Widget _buildStatItem(String label, String value, pw.Font font) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          label,
          style: pw.TextStyle(
            font: font,
            fontSize: 9,
            color: PdfColors.grey600,
          ),
        ),
        pw.SizedBox(height: 4),
        pw.Text(
          value,
          style: pw.TextStyle(
            font: font,
            fontSize: 14,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
      ],
    );
  }

  String _buildPainIndicator(int painLevel) {
    if (painLevel == 0) return '-';
    return '${painLevel}/5';
  }

  String _formatTotalDuration(List<ExerciseHistory> history) {
    final totalDuration = history.fold<Duration>(
      Duration.zero,
      (prev, element) => prev + element.duration,
    );

    final hours = totalDuration.inHours;
    final minutes = totalDuration.inMinutes.remainder(60);

    if (hours > 0) {
      return '$hours ч ${minutes} мин';
    }
    return '$minutes мин';
  }

  String _calculateAveragePain(List<ExerciseHistory> history) {
    final painEntries = history.where((h) => h.painLevel > 0).toList();
    if (painEntries.isEmpty) return 'Нет данных';

    final average =
        painEntries.map((e) => e.painLevel).reduce((a, b) => a + b) /
        painEntries.length;
    return '${average.toStringAsFixed(1)}/5';
  }

  // Новый метод для перехода на экран просмотра PDF
  void _openPdfPreview() async {
    final filteredList = _applyFilters(_historyList); // Применяем фильтры
    final fileName =
        'RehabReport_${DateFormat('yyyyMMdd_HHmm').format(DateTime.now())}.pdf';

    Navigator.of(context).push(
      MaterialPageRoute(
        builder:
            (_) => PdfPreviewScreen(
              generatePdf: () => _generatePdf(filteredList),
              fileName: fileName,
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
    return Consumer<HistoryModel>(
      builder: (context, historyModel, child) {
        // Если история загружается
        if (historyModel.isLoading) {
          return Center(child: CircularProgressIndicator());
        }

        // Если расписание еще не загружено
        if (widget.schedule.trainings.isEmpty) {
          return Consumer<HomeScreenModel>(
            builder: (context, homeModel, child) {
              // Если расписание в HomeScreenModel тоже пустое
              if (homeModel.schedule.trainings.isEmpty) {
                return Scaffold(
                  appBar: AppBar(title: Text('История упражнений')),
                  body: Center(child: CircularProgressIndicator()),
                );
              }

              // Обновляем виджет с актуальным расписанием
              return _buildContent(historyModel, homeModel.schedule);
            },
          );
        }

        return _buildContent(historyModel, widget.schedule);
      },
    );
  }

  Widget _buildContent(HistoryModel historyModel, TrainingSchedule schedule) {
    _historyList = historyModel.history;
    return Scaffold(
      appBar: AppBar(
        title: Text('История упражнений'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _refreshHistory,
          ), // Кнопка обновления
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            onPressed: _openPdfPreview,
            tooltip: 'Экспорт для врача',
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF6A11CB), Color(0xFF2575FC)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          children: [
            // === ДОБАВЛЯЕМ ФИЛЬТРЫ ===
            //_buildFilters(),
            //const SizedBox(height: 10),

            // Существующий график (можно упростить по вашему желанию)
            //_buildSimpleProgressIndicator(_historyList),

            // === ДОБАВЛЯЕМ ТАЙМЛАЙН ВОССТАНОВЛЕНИЯ ===
            _buildRecoveryTimeline(),
            const SizedBox(height: 10),

            // Существующий список
            Expanded(
              child: ListView.builder(
                itemCount: _historyList.length,
                itemBuilder:
                    (context, index) => _buildHistoryItem(_historyList[index]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSimpleProgressIndicator(List<ExerciseHistory> history) {
    // Простой индикатор прогресса вместо сложного графика
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Column(
        children: [
          LinearProgressIndicator(
            value: _calculateWeeklyProgress(history),
            minHeight: 12,
            backgroundColor: Colors.grey[300],
            color: Colors.green,
          ),
          const SizedBox(height: 5),
          const Text(
            "Прогресс за неделю",
            style: TextStyle(color: Colors.white70),
          ),
        ],
      ),
    );
  }

  // Фильтры истории
  Widget _buildFilters() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          // Фильтр по типу травмы
          Row(
            children: [
              const Text(
                "Тип травмы:",
                style: TextStyle(color: Colors.white70),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: DropdownButton<String>(
                  value: _selectedInjuryType,
                  dropdownColor: Colors.deepPurple,
                  style: const TextStyle(color: Colors.white),
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
            ],
          ),

          // Фильтр по периоду времени
          Row(
            children: [
              const Text("Период:", style: TextStyle(color: Colors.white70)),
              const SizedBox(width: 10),
              Expanded(
                child: DropdownButton<String>(
                  value: _selectedTimePeriod,
                  dropdownColor: Colors.deepPurple,
                  style: const TextStyle(color: Colors.white),
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
            ],
          ),
        ],
      ),
    );
  }

  // Таймлайн восстановления
  Widget _buildRecoveryTimeline() {
    return Container(
      height: 100,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Прогресс восстановления:",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: 30, // дней
              itemBuilder: (context, index) {
                if (index >= _historyList.length) {
                  return _buildDayContainer(index, Colors.grey);
                }
                return _buildDayProgress(index);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryItem(ExerciseHistory history) {
    return AnimatedSwitcher(
      duration: Duration(milliseconds: 300),
      child: Container(
        key: ValueKey(history.id), // Уникальный ключ для анимации
        margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: ListTile(
          contentPadding: EdgeInsets.all(16),
          leading: Icon(Icons.fitness_center, color: Colors.white),
          title: Text(
            history.exerciseName,
            style: TextStyle(color: Colors.white),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(history.formattedDate),
              Text('Длительность: ${history.formattedDuration}'),
              Text(
                'Подходов: ${history.sets}',
              ), // Показываем количество подходов
              if (history.painLevel > 0) ...[
                SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.favorite, color: Colors.red, size: 16),
                    SizedBox(width: 4),
                    Text(
                      "Боль: ${history.painLevel}/5",
                      style: TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
              ],
            ],
          ),
          // Добавляем индикатор безопасности
          trailing: _buildSafetyIndicator(history),
        ),
      ),
    );
  }

  // Индикатор безопасности для элемента истории
  Widget _buildSafetyIndicator(ExerciseHistory history) {
    final safetyLevel = 10 - history.painLevel;
    return Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        color: _getSafetyColor(safetyLevel),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          safetyLevel.toString(),
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  Color _getSafetyColor(int level) {
    if (level >= 8) return Colors.green;
    if (level >= 6) return Colors.greenAccent;
    if (level >= 4) return Colors.orange;
    return Colors.red;
  }

  void _savePdfToDevice() async {
    final historyList = await _repository.getAllHistory();
    final filteredList = _applyFilters(historyList);
    final pdfBytes = await _generatePdf(filteredList);

    // Получаем директорию для сохранения
    final directory = await getApplicationDocumentsDirectory();
    final filePath =
        '${directory.path}/RehabReport_${DateFormat('yyyyMMdd_HHmm').format(DateTime.now())}.pdf';

    // Сохраняем файл
    final file = File(filePath);
    await file.writeAsBytes(pdfBytes);

    // Показываем уведомление
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Отчет сохранен: $filePath'),
        duration: Duration(seconds: 3),
      ),
    );
  }

  // Функция экспорта в PDF
  void _exportToPDF() async {
    final historyList = await _repository.getAllHistory();

    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build:
            (pw.Context context) => [
              pw.Header(
                level: 0,
                child: pw.Text(
                  'История упражнений',
                  style: pw.TextStyle(fontSize: 24),
                ),
              ),
              pw.Table.fromTextArray(
                headers: [
                  'Дата',
                  'Упражнение',
                  'Длительность',
                  'Подходы',
                  'Боль',
                ],
                data:
                    historyList.map((h) {
                      return [
                        h.formattedDate,
                        h.exerciseName,
                        h.formattedDuration,
                        h.sets.toString(),
                        h.painLevel > 0 ? '${h.painLevel}/5' : '-',
                      ];
                    }).toList(),
              ),
            ],
      ),
    );
    // Отобразить диалог печати / сохранения
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );
  }
}

class PdfPreviewScreen extends StatelessWidget {
  final Future<Uint8List> Function() generatePdf;
  final String fileName;

  const PdfPreviewScreen({
    Key? key,
    required this.generatePdf,
    required this.fileName,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Предпросмотр отчета'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: () async {
              final pdfBytes = await generatePdf();
              await _savePdf(pdfBytes, fileName, context);
            },
            tooltip: 'Сохранить отчет',
          ),
        ],
      ),
      body: PdfPreview(
        build: (format) => generatePdf(),
        canChangePageFormat: false,
        canChangeOrientation: false,
        canDebug: false,
      ),
    );
  }

  Future<void> _savePdf(
    Uint8List pdfBytes,
    String fileName,
    BuildContext context,
  ) async {
    try {
      // Получаем директорию для сохранения
      final directory = await getApplicationDocumentsDirectory();
      final filePath = '${directory.path}/$fileName';

      // Сохраняем файл
      final file = File(filePath);
      await file.writeAsBytes(pdfBytes);

      // Показываем уведомление
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Отчет сохранен: $filePath'),
            duration: const Duration(seconds: 3),
            action: SnackBarAction(
              label: 'Открыть',
              onPressed: () => _openFile(filePath),
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка сохранения: $e'),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _openFile(String filePath) async {
    if (Platform.isAndroid || Platform.isIOS) {
      await OpenFile.open(filePath);
    } else {
      // Для десктопных платформ
      final uri = Uri.file(filePath);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      }
    }
  }
}
