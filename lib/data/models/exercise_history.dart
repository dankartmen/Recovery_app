import 'package:intl/intl.dart';

class ExerciseHistory {
  final int? id;
  final String exerciseName;
  final DateTime dateTime;
  final Duration duration;
  final String? notes;

  ExerciseHistory({
    this.id,
    required this.exerciseName,
    required this.dateTime,
    required this.duration,
    this.notes,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'exerciseName': exerciseName,
      'dateTime': dateTime.toIso8601String(),
      'duration': duration.inSeconds,
      'notes': notes,
    };
  }

  factory ExerciseHistory.fromMap(Map<String, dynamic> map) {
    return ExerciseHistory(
      id: map['id'],
      exerciseName: map['exerciseName'],
      dateTime: DateTime.parse(map['dateTime']),
      duration: Duration(seconds: map['duration']),
      notes: map['notes'],
    );
  }

  String get formattedDate {
    return DateFormat('dd MMM yyyy HH:mm').format(dateTime);
  }

  String get formattedDuration {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    return [
      if (hours > 0) hours.toString().padLeft(2, '0'),
      minutes.toString().padLeft(2, '0'),
      seconds.toString().padLeft(2, '0'),
    ].join(':');
  }
}
