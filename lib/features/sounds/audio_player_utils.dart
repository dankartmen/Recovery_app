import 'dart:io';
import 'package:audioplayers/audioplayers.dart';

class AudioPlayerUtils {
  static final AudioPlayer _player = AudioPlayer();

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
          throw Exception("Audio file not found");
        }
      }
    } catch (e) {
      print("Error playing sound: $e");
      rethrow;
    }
  }

  static Future<void> stopAllSounds() async {
    await _player.stop();
  }
}
