import 'package:flutter/material.dart';

import 'models.dart';

class Training {
  final Exercise exercise;
  final DateTime date;
  final String title;
  final TimeOfDay time;
  bool isCompleted;

  Training({
    required this.exercise,
    required this.date,
    required this.title,
    required this.time,
    this.isCompleted = false,
  });

  Training copyWith({TimeOfDay? time, bool? isCompleted}) {
    return Training(
      exercise: exercise,
      date: date,
      title: title,
      time: time ?? this.time,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }

  // Добавим метод для сравнения времени
  bool isSameTime(TimeOfDay other) {
    return time.hour == other.hour && time.minute == other.minute;
  }

  bool isCompletedOn(DateTime date) {
    final normalizedDate = DateTime(date.year, date.month, date.day);
    return isCompleted &&
        date.year == normalizedDate.year &&
        date.month == normalizedDate.month &&
        date.day == normalizedDate.day;
  }
}
