import 'package:hive/hive.dart';

import '../data/models/training.dart';
import '../data/models/training_schedule.dart';

class TrainingScheduleAdapter extends TypeAdapter<TrainingSchedule> {
  @override
  final int typeId = 4; // Уникальный ID (должен отличаться от других)

  @override
  TrainingSchedule read(BinaryReader reader) {
    // Чтение данных
    final injuryType = reader.read() as String;
    final trainingsMap = reader.read() as Map<dynamic, dynamic>;

    // Конвертация Map<dynamic, dynamic> в Map<DateTime, List<Training>>
    final trainings = <DateTime, List<Training>>{};
    trainingsMap.forEach((key, value) {
      final dateTime = DateTime.parse(key as String);
      trainings[dateTime] = List<Training>.from(value as List);
    });

    return TrainingSchedule(trainings: trainings, injuryType: injuryType);
  }

  @override
  void write(BinaryWriter writer, TrainingSchedule obj) {
    // Запись типа травмы
    writer.write(obj.injuryType);

    // Конвертация DateTime в строку для ключей
    final trainingsMap = <String, List<Training>>{};
    obj.trainings.forEach((date, trainings) {
      trainingsMap[date.toIso8601String()] = trainings;
    });

    writer.write(trainingsMap);
  }
}
