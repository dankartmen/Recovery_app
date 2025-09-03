import 'dart:typed_data';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:flutter/material.dart';
import '../../data/models/exercise_history.dart';
import '../../data/models/history_model.dart';
import '../../data/models/home_screen_model.dart';
import '../../data/models/models.dart';
import '../../data/models/training_schedule.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../styles/style.dart';
import 'pdf_preview_screen.dart';

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
  String _selectedInjuryType = "Все";
  String _selectedTimePeriod = "За всё время";
  List<ExerciseHistory> _historyList = [];
  HistoryModel? _historyModel;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadHistory();
    });
  }

  void _loadHistory() {
    setState(() {
      _error = null;
    });
    try {
      final historyModel = Provider.of<HistoryModel>(context, listen: false);
      if (!historyModel.isInitialized) {
        historyModel.loadHistory();
      }
    } catch (e) {
      setState(() {
        _error = "Не удалось загрузить историю. Попробуйте снова.";
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
    _historyModel ??= Provider.of<HistoryModel>(context, listen: false);
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
                        _pdfBuildStatItem(
                          'Всего упражнений',
                          historyList.length.toString(),
                          ttf,
                        ),
                        _pdfBuildStatItem(
                          'Общее время',
                          _formatTotalDuration(historyList),
                          ttf,
                        ),
                        _pdfBuildStatItem(
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
  pw.Widget _pdfBuildStatItem(String label, String value, pw.Font font) {
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
    try {
      final filteredList = _applyFilters(_historyList);
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
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Ошибка экспорта PDF: $e')));
    }
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
          return Center(
            child: CircularProgressIndicator(color: healthPrimaryColor),
          );
        }

        // Если расписание еще не загружено
        if (widget.schedule.trainings.isEmpty) {
          return Consumer<HomeScreenModel>(
            builder: (context, homeModel, child) {
              // Если расписание в HomeScreenModel тоже пустое
              if (homeModel.schedule.trainings.isEmpty) {
                return Scaffold(
                  appBar: buildAppBar('История упражнений'),
                  body: Center(
                    child: CircularProgressIndicator(color: healthPrimaryColor),
                  ),
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
            onPressed: _openPdfPreview,
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
