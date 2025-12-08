import 'package:flutter/material.dart';
import '../core/styles/style.dart';

class TimerPickerScreen extends StatefulWidget {
  const TimerPickerScreen({super.key});

  @override
  TimerPickerScreenState createState() => TimerPickerScreenState();
}

class TimerPickerScreenState extends State<TimerPickerScreen> {
  int _minutes = 0;
  int _seconds = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: buildAppBar('Выберите время'),
      body: Container(
        color: healthBackgroundColor,
        child: Column(
          children: [
            // Визуализация выбранного времени
            Container(
              margin: const EdgeInsets.symmetric(vertical: 24),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 8,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Text(
                '${_minutes.toString().padLeft(2, '0')}:${_seconds.toString().padLeft(2, '0')}',
                style: TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: healthPrimaryColor,
                ),
              ),
            ),

            // Заголовок
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                'Установите время для выполнения упражнения',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: healthSecondaryTextColor),
              ),
            ),
            const SizedBox(height: 16),

            // Прокручиваемые селекторы
            Expanded(
              child: Row(
                children: [
                  // Минуты
                  _buildNumberPicker(
                    value: _minutes,
                    max: 59,
                    label: 'минут',
                    onChanged: (value) => setState(() => _minutes = value),
                  ),

                  // Вертикальный разделитель
                  Container(
                    width: 1,
                    height: double.infinity,
                    color: healthDividerColor,
                    margin: const EdgeInsets.symmetric(vertical: 40),
                  ),

                  // Секунды
                  _buildNumberPicker(
                    value: _seconds,
                    max: 59,
                    label: 'секунд',
                    onChanged: (value) => setState(() => _seconds = value),
                  ),
                ],
              ),
            ),

            // Кнопка подтверждения
            Padding(
              padding: const EdgeInsets.all(24),
              child: primaryButton(
                text: 'Установить время',
                onPressed: () {
                  final totalSeconds = _minutes * 60 + _seconds;
                  Navigator.pop(context, totalSeconds);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Виджет выбора числа с улучшенным дизайном
  Widget _buildNumberPicker({
    required int value,
    required int max,
    required String label,
    required Function(int) onChanged,
  }) {
    return Expanded(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Заголовок
          Text(
            label,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: healthSecondaryTextColor,
            ),
          ),
          const SizedBox(height: 16),

          // Колесо выбора
          Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 6,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: ListWheelScrollView(
                itemExtent: 60,
                diameterRatio: 1.8,
                useMagnifier: true,
                magnification: 1.3,
                physics: const FixedExtentScrollPhysics(),
                onSelectedItemChanged: onChanged,
                children: List.generate(max + 1, (index) {
                  final isSelected = index == value;
                  return Container(
                    decoration: BoxDecoration(
                      color:
                          isSelected
                              ? healthPrimaryColor.withValues(alpha: 0.1)
                              : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        index.toString().padLeft(2, '0'),
                        style: TextStyle(
                          fontSize: isSelected ? 28 : 22,
                          color:
                              isSelected ? healthPrimaryColor : healthTextColor,
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
