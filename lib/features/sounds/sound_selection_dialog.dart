import 'dart:async';

import '../../data/models/sound.dart';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:file_picker/file_picker.dart';
import 'sound_service.dart';

class SoundSelectionDialog extends StatefulWidget {
  final Sound? currentSound;

  const SoundSelectionDialog({super.key, this.currentSound});

  @override
  SoundSelectionDialogState createState() => SoundSelectionDialogState();
}

class SoundSelectionDialogState extends State<SoundSelectionDialog> {
  late Sound? _selectedSound;
  bool _isPlaying = false;
  Duration _currentPosition = Duration.zero;
  Duration? _totalDuration;
  Sound? _currentlyPlayingSound;
  late StreamSubscription<void> _playerCompleteSubscription;
  late StreamSubscription<Duration> _positionChangedSubscription;
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
            ...sounds.map((sound) => _buildSoundTile(sound)),
          ],
        );
      },
    );
  }

  Widget _buildSoundTile(Sound sound) {
    final isPlayingCurrent =
        _isPlaying && _currentlyPlayingSound?.path == sound.path;

    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Container(
          padding: EdgeInsets.only(left: 0),
          child: Row(
            children: [
              // Radio button - левый край
              Radio<Sound>(
                value: sound,
                groupValue: _selectedSound,
                onChanged: (s) => setState(() => _selectedSound = s),
              ),

              // Название мелодии - центр
              Expanded(
                child: Text(
                  sound.originalName ?? sound.name,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight:
                        isPlayingCurrent ? FontWeight.w600 : FontWeight.normal,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),

              // Кнопки управления - правый край
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(Icons.volume_up),
                    onPressed: () => _showVolumeDialog(sound),
                  ),
                  IconButton(
                    icon: Icon(
                      isPlayingCurrent ? Icons.pause : Icons.play_arrow,
                    ),
                    onPressed: () => _togglePlayPause(sound),
                  ),
                ],
              ),
            ],
          ),
        ),
        if (isPlayingCurrent && _totalDuration != null)
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
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

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

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
