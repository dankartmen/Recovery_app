import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:printing/printing.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../data/models/exercise_history.dart';
import '../../data/models/models.dart';
import '../../core/styles/style.dart';

class PdfPreviewScreen extends StatelessWidget {
  final List<ExerciseHistory> historyList;
  final RecoveryData recoveryData;

  const PdfPreviewScreen({
    super.key,
    required this.historyList,
    required this.recoveryData,
  });

  static Future<pw.Font> _loadFont() async {
    final fontData = await rootBundle.load('assets/fonts/Roboto-Regular.ttf');
    return pw.Font.ttf(fontData);
  }

  // Метод для генерации PDF и возврата Uint8List
  Future<Uint8List> generateHistoryPdf(PdfPageFormat format) async {
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
        pageFormat: format,
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
                      _formatUserValue(recoveryData.name),
                      ttf,
                    ),
                    _buildUserInfoRow(
                      'Пол',
                      _formatUserValue(recoveryData.gender),
                      ttf,
                    ),
                    _buildUserInfoRow(
                      'Рост/Вес',
                      '${_formatUserValue(recoveryData.height)} см / ${_formatUserValue(recoveryData.weight)} кг',
                      ttf,
                    ),
                    _buildUserInfoRow(
                      'Основная травма',
                      _formatUserValue(recoveryData.mainInjuryType),
                      ttf,
                    ),
                    _buildUserInfoRow(
                      'Конкретная травма',
                      _formatUserValue(recoveryData.specificInjury),
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

  static String _calculateAveragePain(List<ExerciseHistory> history) {
    final painEntries = history.where((h) => h.painLevel > 0).toList();
    if (painEntries.isEmpty) return 'Нет данных';

    final average =
        painEntries.map((e) => e.painLevel).reduce((a, b) => a + b) /
        painEntries.length;
    return '${average.toStringAsFixed(1)}/5';
  }

  static String _formatTotalDuration(List<ExerciseHistory> history) {
    final totalDuration = history.fold<Duration>(
      Duration.zero,
      (prev, element) => prev + element.duration,
    );

    final hours = totalDuration.inHours;
    final minutes = totalDuration.inMinutes.remainder(60);

    if (hours > 0) {
      return '$hours ч $minutes мин';
    }
    return '$minutes мин';
  }

  // Метод для создания элемента статистики
  static pw.Widget _pdfBuildStatItem(String label, String value, pw.Font font) {
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

  // Обработка отсутствия данных
  static String _formatUserValue(dynamic value) {
    if (value == null) return 'Не указано';
    if (value is String && value.isEmpty) return 'Не указано';
    if (value is num && value == 0) return 'Не указано';
    return value.toString();
  }

  // Метод для создания строки информации о пациенте
  static pw.Widget _buildUserInfoRow(String label, String value, pw.Font font) {
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
  static pw.Widget _buildTableCell(String text, pw.Font font) {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: buildAppBar(
        'Предпросмотр отчета',
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: () async {
              final pdfBytes = await generateHistoryPdf(PdfPageFormat.a4);
              if (!context.mounted) return;
              await _savePdf(pdfBytes, _generateFileName(), context);
            },
            tooltip: 'Сохранить отчет',
          ),
        ],
      ),
      body: PdfPreview(
        build: generateHistoryPdf,
        canChangePageFormat: false,
        canChangeOrientation: false,
        canDebug: false,
      ),
    );
  }

  String _generateFileName() {
    final name = recoveryData.name.isNotEmpty
        ? recoveryData.name.replaceAll(' ', '_')
        : 'patient';
    final now = DateTime.now();
    final formattedDate = DateFormat('yyyy-MM-dd_HH-mm-ss').format(now);
    return 'RehabReport_${name}_$formattedDate.pdf';
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
            duration: const Duration(seconds: 30),
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
            duration: const Duration(seconds: 5),
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