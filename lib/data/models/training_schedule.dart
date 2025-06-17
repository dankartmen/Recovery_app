import 'package:hive/hive.dart';

import 'training.dart';

@HiveType(typeId: 4) // Должен совпадать с адаптером
class TrainingSchedule {
  @HiveField(0)
  final Map<DateTime, List<Training>> trainings;

  @HiveField(1)
  final String injuryType;

  TrainingSchedule({required this.trainings, required this.injuryType});
  static TrainingSchedule empty() {
    return TrainingSchedule(trainings: {}, injuryType: '');
  }
}
