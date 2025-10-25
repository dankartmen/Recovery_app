
import 'package:flutter/material.dart';
import 'models.dart'; 

class Training {
  final int id;
  final int scheduleId;
  final int exerciseId;
  final String title; 
  final DateTime date;
  final String timeStr;
  bool isCompleted;
  DateTime? completedAt;

  // Computed properties
  TimeOfDay get time => _parseTimeOfDay(timeStr);
  Exercise? exercise; 

  Training({
    required this.id,
    required this.scheduleId,
    required this.exerciseId,
    required this.title,
    required this.date,
    required this.timeStr,
    this.isCompleted = false,
    this.completedAt,
    this.exercise,
  });

  TimeOfDay _parseTimeOfDay(String timeStr) {
    final parts = timeStr.split(':');
    return TimeOfDay(
      hour: int.parse(parts[0]),
      minute: int.parse(parts[1]),
    );
  }


  factory Training.fromJson(Map<String, dynamic> json) {
    DateTime? completedAt;
    if (json['completed_at'] != null) {
      completedAt = DateTime.parse(json['completed_at']);
    }

    return Training(
      id: json['id'] ?? 0,
      scheduleId: json['schedule_id'] ?? 0,
      exerciseId: json['exercise_id'] ?? 0,
      title: json['title'] ?? '', 
      date: DateTime.parse(json['date']),
      timeStr: json['time'] ?? '09:00',
      isCompleted: json['is_completed'] ?? false,
      completedAt: completedAt,
    );
  }


  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'schedule_id': scheduleId,
      'exercise_id': exerciseId,
      'title': title,
      'date': date.toIso8601String(),
      'time': timeStr,
      'is_completed': isCompleted,
      'completed_at': completedAt?.toIso8601String(),
    };
  }

  Training copyWith({
    TimeOfDay? time,
    bool? isCompleted,
    DateTime? completedAt,
    Exercise? exercise,
  }) {
    return Training(
      id: id,
      scheduleId: scheduleId,
      exerciseId: exerciseId,
      title: title,
      date: date,
      timeStr: timeStr,
      isCompleted: isCompleted ?? this.isCompleted,
      completedAt: completedAt ?? this.completedAt,
      exercise: exercise ?? this.exercise,
    );
  }

  bool isSameTime(TimeOfDay other) {
    return time.hour == other.hour && time.minute == other.minute;
  }

  bool isCompletedOn(DateTime targetDate) {
    final normalizedDate = DateTime(targetDate.year, targetDate.month, targetDate.day);
    final thisDate = DateTime(date.year, date.month, date.day);
    return isCompleted && thisDate == normalizedDate;
  }
}