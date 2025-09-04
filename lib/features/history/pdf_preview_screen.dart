import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:printing/printing.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../styles/style.dart';

class PdfPreviewScreen extends StatelessWidget {
  final Future<Uint8List> Function() generatePdf;
  final String fileName;

  const PdfPreviewScreen({
    super.key,
    required this.generatePdf,
    required this.fileName,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: buildAppBar(
        'Предпросмотр отчета',
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: () async {
              final pdfBytes = await generatePdf();
              if (!context.mounted) return;
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
