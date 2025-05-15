import 'dart:io';
import 'package:permission_handler/permission_handler.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'audio_player_utils.dart';
import '../../data/models/sound.dart';

// Сервис для работы со звуками: воспроизведение, хранение, управление громкостью
class SoundService {
  static final AudioPlayer previewPlayer =
      AudioPlayer()..setReleaseMode(ReleaseMode.stop);
  static final List<Sound> sounds = [
    Sound(
      name: "Сигнал 1",
      path: "sounds/ending-sound-effect.mp3",
      isAsset: true,
    ),
    Sound(name: "Сигнал 2", path: "sounds/klubnichki.mp3", isAsset: true),
    Sound(name: "Сигнал 3", path: "sounds/pobeda.mp3", isAsset: true),
  ];
  static List<Sound> customSounds = [];

  // Инициализация пользовательских звуков
  static Future<void> init() async {
    await _loadCustomSounds();
  }

  static Future<void> playSound(Sound sound) async {
    if (Platform.isWindows) {
      await AudioPlayerUtils.playSound(
        sound.path,
        isAsset: sound.isAsset,
        volume: sound.volume,
      );
    } else if (Platform.isAndroid) {
      try {
        await previewPlayer.stop();
        if (sound.isAsset) {
          await previewPlayer.play(AssetSource(sound.path));
        } else {
          final file = File(sound.path);
          if (await file.exists()) {
            await previewPlayer.play(DeviceFileSource(sound.path));
          } else {
            debugPrint("Фаил не найден: ${sound.path}");
          }
        }
      } catch (e) {
        debugPrint("Ошибка проигрывания мелодии: $e");
        rethrow;
      }
    }
  }

  static Future<List<Sound>> getAllSounds() =>
      Future.value([...sounds, ...customSounds]);

  static Future<void> _loadCustomSounds() async {
    final prefs = await SharedPreferences.getInstance();
    final customPaths = prefs.getStringList('customSounds') ?? [];

    for (var path in customPaths) {
      if (await File(path).exists()) {
        // Проверяем существует ли файл
        final fileName = path.split('/').last;
        customSounds.add(
          Sound(
            name: fileName,
            path: path,
            volume: prefs.getDouble('$path.volume') ?? 1.0,
            isAsset: false,
            originalName:
                path.split('_').length > 1
                    ? path.split('_').sublist(1).join('_')
                    : fileName,
          ),
        );
      }
    }
  }

  // Добавление пользовательского звука
  static Future<bool> addCustomSound(String filePath) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final soundDir = Directory(path.join(dir.path, 'sounds'));

      if (!await soundDir.exists()) {
        await soundDir.create(recursive: true);
      }

      final fileName = path.basename(filePath);
      final newPath = path.join(soundDir.path, fileName);

      String uniqueName = fileName; // По умолчанию - оригинальное имя
      String actualPath = newPath;

      if (await File(newPath).exists()) {
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final uniqueName = '${timestamp}_$fileName';
        actualPath = path.join(soundDir.path, uniqueName); // Обновляем путь
        await File(filePath).copy(actualPath);
      } else {
        await File(filePath).copy(newPath);
        customSounds.add(Sound(name: fileName, path: newPath, isAsset: false));
      }
      customSounds.add(
        Sound(
          name: uniqueName,
          path: actualPath,
          isAsset: false,
          originalName: fileName,
        ),
      );
      return true;
    } catch (e) {
      debugPrint("Ошибка добавления звука: $e");
      return false;
    }
  }

  // Добавление пользовательского звука
  static Future<bool> addCustomSoundinAndroid(PlatformFile file) async {
    try {
      if (await Permission.storage.request().isGranted) {
        final dir = await getApplicationDocumentsDirectory();
        final soundDir = Directory(path.join(dir.path, 'sounds'));

        if (!await soundDir.exists()) {
          await soundDir.create(recursive: true);
        }

        final newPath = path.join(soundDir.path, file.name);
        await File(file.path!).copy(newPath);

        await addCustomSound(newPath); // Обновляем список
        return true;
      }
      return false;
    } catch (e) {
      debugPrint("Ошибка добавления звука: $e");
      return false;
    }
  }

  static Future<void> saveVolume(Sound sound) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('${sound.path}.volume', sound.volume);
  }

  static Future<void> previewSound(Sound sound) async {
    try {
      await previewPlayer.stop();
      await previewPlayer.release(); // Важно освобождать ресурсы

      if (sound.isAsset) {
        await previewPlayer.play(AssetSource(sound.path), volume: sound.volume);
      } else {
        final file = File(sound.path);
        if (await file.exists()) {
          await previewPlayer.play(
            DeviceFileSource(sound.path),
            volume: sound.volume,
          );
        } else {
          debugPrint("Фаил не найден: ${sound.path}");
        }
      }
    } catch (e) {
      debugPrint("Ошибка при предварительном прослушивании звука: $e");
      rethrow;
    }
  }
}
