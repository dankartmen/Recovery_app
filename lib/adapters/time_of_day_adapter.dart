import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

/// {@template time_of_day_adapter}
/// Адаптер для сериализации/десериализации объектов TimeOfDay в Hive.
/// Позволяет сохранять время в базе данных Hive.
/// {@endtemplate}
class TimeOfDayAdapter extends TypeAdapter<TimeOfDay> {
  /// Уникальный идентификатор типа для Hive
  @override
  final int typeId = 3;

  /// Чтение объекта TimeOfDay из бинарного потока Hive
  /// Возвращает:
  /// - объект TimeOfDay с восстановленными значениями часов и минут
  @override
  TimeOfDay read(BinaryReader reader) {
    final hour = reader.readByte();
    final minute = reader.readByte();
    return TimeOfDay(hour: hour, minute: minute);
  }

  /// Запись объекта TimeOfDay в бинарный поток Hive
  /// Принимает:
  /// - [writer] - объект для записи бинарных данных
  /// - [obj] - объект TimeOfDay для сериализации
  @override
  void write(BinaryWriter writer, TimeOfDay obj) {
    writer.writeByte(obj.hour);
    writer.writeByte(obj.minute);
  }
}
