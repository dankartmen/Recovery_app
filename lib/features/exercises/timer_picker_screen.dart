import 'package:flutter/material.dart';

import '../../style.dart';

// Экран выбора времени для таймера упражнения
class TimerPickerScreen extends StatefulWidget {
  @override
  _TimerPickerScreenState createState() => _TimerPickerScreenState();
}

class _TimerPickerScreenState extends State<TimerPickerScreen> {
  int _minutes = 0;
  int _seconds = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: buildAppBar('Выберите время'),
      body: Column(
        children: [
          Expanded(
            child: Row(
              children: [
                // минуты
                _buildNumberPicker(
                  value: _minutes,
                  max: 59,
                  label: 'минут',
                  onChanged: (value) => setState(() => _minutes = value),
                ),
                // Вертикальный разделитель
                Container(
                  width: 2,
                  height: double.infinity,
                  color: Colors.grey[300],
                ),
                _buildNumberPicker(
                  value: _seconds,
                  max: 59,
                  label: 'секунд',
                  onChanged: (value) => setState(() => _seconds = value),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: primaryButton(
              text: 'Установить время',
              onPressed: () {
                final totalSeconds =
                    _minutes * 60 +
                    _seconds; // Возврат общего времени в секундах
                Navigator.pop(context, totalSeconds);
              },
            ),
          ),
        ],
      ),
    );
  }

  // Виджет выбора числа с анимацией
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
          Text(
            label,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: ListWheelScrollView(
              itemExtent: 50,
              diameterRatio: 1.2,
              useMagnifier: true,
              magnification: 1.5,
              physics: const FixedExtentScrollPhysics(),
              onSelectedItemChanged: onChanged,
              children: List.generate(max + 1, (index) {
                final isSelected = index == value;
                return Center(
                  child: AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 200),
                    style: TextStyle(
                      fontSize: isSelected ? 28 : 20,
                      color: isSelected ? Colors.blue : Colors.black,
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                    child: Text(index.toString().padLeft(2, '0')),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}
