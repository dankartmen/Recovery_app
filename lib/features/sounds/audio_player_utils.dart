import 'dart:io';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';

/// {@template audio_player_utils}
/// Утилиты для воспроизведения аудиофайлов.
/// Предоставляет статические методы для управления воспроизведением звуков.
/// {@endtemplate}
class AudioPlayerUtils {
  /// Аудиоплеер для воспроизведения звуков
  static final AudioPlayer _player = AudioPlayer();

   /// Воспроизведение звукового файла
  /// Принимает:
  /// - [path] - путь к аудиофайлу
  /// - [isAsset] - флаг указывающий является ли файл ассетом приложения
  /// - [volume] - громкость воспроизведения (от 0.0 до 1.0)
  /// Выбрасывает исключение:
  /// - при ошибках загрузки или воспроизведения файла
  static Future<void> playSound(
    String path, {
    bool isAsset = true,
    double volume = 1.0,
  }) async {
    try {
      await _player.stop();
      if (isAsset) {
        await _player.play(AssetSource(path), volume: volume);
      } else {
        final file = File(path);
        if (await file.exists()) {
          await _player.play(DeviceFileSource(path), volume: volume);
        } else {
          throw Exception("Аудиофайл не найден");
        }
      }
    } catch (e) {
      debugPrint("Ошибка проигрывания аудиофайла: $e");
      rethrow;
    }
  }

  /// Остановка всех воспроизводимых звуков
  static Future<void> stopAllSounds() async {
    await _player.stop();
  }
}
