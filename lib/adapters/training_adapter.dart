import 'package:hive/hive.dart';

import '../data/models/training.dart';

class TrainingAdapter extends TypeAdapter<Training> {
  @override
  final int typeId = 1;

  @override
  Training read(BinaryReader reader) {
    return Training(
      exercise: reader.read(),
      date: DateTime.parse(reader.read()),
      title: reader.read(),
      time: reader.read(),
      isCompleted: reader.read(),
    );
  }

  @override
  void write(BinaryWriter writer, Training obj) {
    writer.write(obj.exercise);
    writer.write(obj.date.toIso8601String());
    writer.write(obj.title);
    writer.write(obj.time);
    writer.write(obj.isCompleted);
  }
}
