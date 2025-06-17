import 'package:intl/intl.dart';

class ExerciseHistory {
  final int? id;
  final String exerciseName;
  final DateTime dateTime;
  final Duration duration;
  final String? notes;
  final int sets;
  final int painLevel;

  ExerciseHistory({
    this.id,
    required this.exerciseName,
    required this.dateTime,
    required this.duration,
    this.notes,
    this.sets = 1, // Добавляем поле для подходов
    this.painLevel = 0,
  });

  // Добавляем форматированное количество подходов
  String get formattedSets =>
      '$sets ${_pluralize(sets, 'подход', 'подхода', 'подходов')}';

  String _pluralize(int n, String form1, String form2, String form5) {
    n = n.abs() % 100;
    int n1 = n % 10;
    if (n > 10 && n < 20) return form5;
    if (n1 > 1 && n1 < 5) return form2;
    if (n1 == 1) return form1;
    return form5;
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'exerciseName': exerciseName,
      'dateTime': dateTime.toIso8601String(),
      'duration': duration.inSeconds,
      'notes': notes,
      'sets': sets,
      'painLevel': painLevel,
    };
  }

  factory ExerciseHistory.fromMap(Map<String, dynamic> map) {
    return ExerciseHistory(
      id: map['id'],
      exerciseName: map['exerciseName'],
      dateTime: DateTime.parse(map['dateTime']),
      duration: Duration(seconds: map['duration']),
      notes: map['notes'],
      sets: map['sets'],
      painLevel: map['painLevel'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'exercise_name': exerciseName,
    'date_time': dateTime.toIso8601String(),
    'duration': duration.inSeconds,
    'notes': notes,
    'sets': sets,
    'pain_level': painLevel,
  };

  factory ExerciseHistory.fromJson(Map<String, dynamic> json) {
    return ExerciseHistory(
      id: json['id'],
      exerciseName: json['exercise_name'],
      dateTime: DateTime.parse(json['date_time']),
      duration: Duration(seconds: json['duration']),
      notes: json['notes'],
      sets: json['sets'],
      painLevel: json['pain_level'],
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

  factory ExerciseHistory.empty() {
    return ExerciseHistory(
      exerciseName: 'Ошибка загрузки',
      dateTime: DateTime.now(),
      duration: Duration.zero,
      sets: 0,
      painLevel: 0,
    );
  }
}
