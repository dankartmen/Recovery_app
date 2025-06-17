import 'package:hive/hive.dart';

import '../data/models/models.dart';

class ExerciseAdapter extends TypeAdapter<Exercise> {
  @override
  final int typeId = 2; // Уникальный идентификатор (должен отличаться от других адаптеров)

  @override
  Exercise read(BinaryReader reader) {
    return Exercise(
      id: reader.read(),
      title: reader.read(),
      generalDescription: reader.read(),
      injurySpecificInfo: _readInjuryMap(reader),
      suitableFor: _readStringList(reader),
      maxPainLevel: reader.read(),
      steps: _readStringList(reader),
      tags: _readStringList(reader),
      imageUrl: reader.read(),
    );
  }

  @override
  void write(BinaryWriter writer, Exercise obj) {
    writer.write(obj.id);
    writer.write(obj.title);
    writer.write(obj.generalDescription);
    _writeInjuryMap(writer, obj.injurySpecificInfo);
    _writeStringList(writer, obj.suitableFor);
    writer.write(obj.maxPainLevel);
    _writeStringList(writer, obj.steps);
    _writeStringList(writer, obj.tags);
    writer.write(obj.imageUrl);
  }

  // Вспомогательные методы для работы с Map<String, String>
  Map<String, String> _readInjuryMap(BinaryReader reader) {
    final length = reader.readByte();
    final map = <String, String>{};
    for (var i = 0; i < length; i++) {
      final key = reader.read() as String;
      final value = reader.read() as String;
      map[key] = value;
    }
    return map;
  }

  void _writeInjuryMap(BinaryWriter writer, Map<String, String> map) {
    writer.writeByte(map.length);
    map.forEach((key, value) {
      writer.write(key);
      writer.write(value);
    });
  }

  // Вспомогательные методы для работы со списками строк
  List<String> _readStringList(BinaryReader reader) {
    final length = reader.readByte();
    return List.generate(length, (_) => reader.read() as String);
  }

  void _writeStringList(BinaryWriter writer, List<String> list) {
    writer.writeByte(list.length);
    list.forEach(writer.write);
  }
}
