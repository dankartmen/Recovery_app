import 'dart:async';

import '../../data/models/sound.dart';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:file_picker/file_picker.dart';
import 'sound_service.dart';

/// {@template sound_selection_dialog}
/// Диалог выбора звука для уведомлений или других целей.
/// Позволяет выбирать между системными и пользовательскими звуками,
/// предпрослушивать их и настраивать громкость.
/// {@endtemplate}
class SoundSelectionDialog extends StatefulWidget {
  /// Текущий выбранный звук
  final Sound? currentSound;

  /// {@macro sound_selection_dialog}
  const SoundSelectionDialog({super.key, this.currentSound});

  @override
  SoundSelectionDialogState createState() => SoundSelectionDialogState();
}

class SoundSelectionDialogState extends State<SoundSelectionDialog> {
  /// Выбранный звук в диалоге
  late Sound? _selectedSound;

  /// Флаг воспроизведения звука
  bool _isPlaying = false;

  /// Текущая позиция воспроизведения
  Duration _currentPosition = Duration.zero;

  /// Общая длительность звука
  Duration? _totalDuration;

  /// Текущий воспроизводимый звук
  Sound? _currentlyPlayingSound;

  /// Подписка на событие завершения воспроизведения
  late StreamSubscription<void> _playerCompleteSubscription;

  /// Подписка на изменение позиции воспроизведения
  late StreamSubscription<Duration> _positionChangedSubscription;

  /// Подписка на изменение длительности звука
  late StreamSubscription<Duration> _durationChangedSubscription;

  @override
  void initState() {
    super.initState();
    _selectedSound = widget.currentSound;

    _playerCompleteSubscription = SoundService.previewPlayer.onPlayerComplete
        .listen((_) {
          if (mounted) {
            setState(() {
              _isPlaying = false;
              _currentPosition = Duration.zero;
            });
          }
        });

    _positionChangedSubscription = SoundService.previewPlayer.onPositionChanged
        .listen((position) {
          if (mounted && _isPlaying) {
            setState(() => _currentPosition = position);
          }
        });

    _durationChangedSubscription = SoundService.previewPlayer.onDurationChanged
        .listen((duration) {
          if (mounted) {
            setState(() => _totalDuration = duration);
          }
        });
  }

  @override
  void dispose() {
    _playerCompleteSubscription.cancel();
    _positionChangedSubscription.cancel();
    _durationChangedSubscription.cancel();
    SoundService.previewPlayer.stop();
    super.dispose();
  }

  /// Воспроизведение звука
  /// Принимает:
  /// - [sound] - звук для воспроизведения
  /// - [seek] - позиция для начала воспроизведения
  Future<void> _playSound(Sound sound, {Duration? seek}) async {
    if (sound.isAsset) {
      await SoundService.previewPlayer.play(
        AssetSource(sound.path),
        volume: sound.volume,
        position: seek,
      );
    } else {
      await SoundService.previewPlayer.play(
        DeviceFileSource(sound.path),
        volume: sound.volume,
        position: seek,
      );
    }
  }

  /// Переключение воспроизведения/паузы для звука
  /// Принимает:
  /// - [sound] - звук для управления воспроизведением
  Future<void> _togglePlayPause(Sound sound) async {
    if (!mounted) return;

    if (_isPlaying && _currentlyPlayingSound?.path == sound.path) {
      await SoundService.previewPlayer.pause();
      if (mounted) {
        setState(() => _isPlaying = false);
      }
    } else {
      try {
        if (_currentlyPlayingSound?.path != sound.path) {
          _currentPosition = Duration.zero;
          await SoundService.previewPlayer.stop();
          await _playSound(sound);
        } else {
          await _playSound(sound, seek: _currentPosition);
        }
        if (mounted) {
          setState(() {
            _isPlaying = true;
            _currentlyPlayingSound = sound;
          });
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Ошибка воспроизведения: ${e.toString()}")),
          );
        }
      }
    }
  }

  /// Добавление пользовательского звука на Android
  Future<void> _addCustomSoundinAndriod() async {
    try {
      final result = await FilePicker.platform.pickFiles(type: FileType.audio);
      if (!mounted) return;

      if (result != null && result.files.isNotEmpty) {
        final platformFile = result.files.first;
        if (platformFile.path != null) {
          final success = await SoundService.addCustomSoundinAndroid(
            platformFile,
          );
          if (!mounted) return;
          if (success) {
            setState(() {});
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text("Звук успешно добавлен")));
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Ошибка: не удалось получить путь к файлу")),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Ошибка: ${e.toString()}")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text("Выбор мелодии"),
      content: SingleChildScrollView(
        child: Column(
          children: [
            _buildSoundList("Системные", true),
            Divider(),
            _buildSoundList("Пользовательские", false),
            ElevatedButton(
              onPressed: _addCustomSoundinAndriod,
              child: Text("Добавить свой звук"),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            SoundService.previewPlayer.stop();
            Navigator.pop(context, _selectedSound); // Возвращаем выбранный звук
          },
          child: Text("Отмена"),
        ),
        TextButton(
          onPressed: () {
            SoundService.previewPlayer.stop();
            Navigator.pop(context, _selectedSound);
          },
          child: Text("Выбрать"),
        ),
      ],
    );
  }

  /// Построение списка звуков
  /// Принимает:
  /// - [title] - заголовок списка
  /// - [isAsset] - флаг системных звуков
  /// Возвращает:
  /// - виджет списка звуков
  Widget _buildSoundList(String title, bool isAsset) {
    return FutureBuilder<List<Sound>>(
      future: SoundService.getAllSounds(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return CircularProgressIndicator();

        final sounds =
            snapshot.data!.where((s) => s.isAsset == isAsset).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Text(title, style: TextStyle(fontWeight: FontWeight.w600)),
            ),
            RadioGroup(
              onChanged: (Sound? newValue){
                if (newValue != null){
                  setState(() => _selectedSound = newValue);
                }
              },
              groupValue: _selectedSound,
              child: Column(children: sounds.map((sound) => _buildSoundTile(sound)).toList(),) 
            )
          ],
        );
      },
    );
  }

  /// Построение элемента списка звуков
  /// Принимает:
  /// - [sound] - звук для отображения
  /// Возвращает:
  /// - виджет элемента списка
  Widget _buildSoundTile(Sound sound) {
    final isPlayingCurrent = _isPlaying && _currentlyPlayingSound?.path == sound.path;

    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        RadioListTile<Sound>(
          value: sound,
          contentPadding: const EdgeInsets.only(left: 0),
          title: Text(
            sound.originalName ?? sound.name,
            style: TextStyle(
              fontSize: 16,
              fontWeight: isPlayingCurrent ? FontWeight.w600 : FontWeight.normal,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          secondary: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.volume_up),
                onPressed: () {
                  debugPrint('Открыт диалог громкости для ${sound.name}');
                  _showVolumeDialog(sound);}
              ),
              IconButton(
                icon: Icon(
                  isPlayingCurrent ? Icons.pause : Icons.play_arrow,
                ),
                onPressed: () { 
                  debugPrint('Воспроизведение/пауза для ${sound.name}');
                  _togglePlayPause(sound);}
              ),
            ],
          ),
        ),
        if (isPlayingCurrent && _totalDuration != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                Slider(
                  value: _currentPosition.inMilliseconds.toDouble(),
                  min: 0,
                  max: _totalDuration!.inMilliseconds.toDouble(),
                  onChanged: (value) {
                    setState(() {
                      _currentPosition = Duration(milliseconds: value.toInt());
                    });
                  },
                  onChangeEnd: (value) async {
                    await SoundService.previewPlayer.seek(
                      Duration(milliseconds: value.toInt()),
                    );
                  },
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(_formatDuration(_currentPosition)),
                    Text(_formatDuration(_totalDuration!)),
                  ],
                ),
              ],
            ),
          ),
      ],
    );
  }

  /// Форматирование длительности в строку
  /// Принимает:
  /// - [duration] - длительность для форматирования
  /// Возвращает:
  /// - отформатированную строку времени
  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  /// Показ диалога настройки громкости
  /// Принимает:
  /// - [sound] - звук для настройки громкости
  void _showVolumeDialog(Sound sound) {
    showDialog(
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder: (context, setState) {
              return AlertDialog(
                title: Text("Громкость для ${sound.name}"),
                content: Slider(
                  value: sound.volume,
                  min: 0,
                  max: 1,
                  divisions: 10,
                  onChanged:
                      (v) => setState(() {
                        sound.volume = v;
                        SoundService.saveVolume(sound);
                      }),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text("OK"),
                  ),
                ],
              );
            },
          ),
    );
  }
}