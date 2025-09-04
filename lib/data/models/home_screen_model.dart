import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'training_schedule.dart';

class HomeScreenModel extends ChangeNotifier {
  TrainingSchedule _schedule = TrainingSchedule(trainings: {}, injuryType: '');

  TrainingSchedule get schedule => _schedule;

  HomeScreenModel() {
    _init();
  }

  Future<void> _init() async {
    final box = await Hive.openBox<TrainingSchedule>('training_schedule');
    updateSchedule(
      box.get('schedule') ?? TrainingSchedule(trainings: {}, injuryType: ''),
    );

    // Слушаем изменения в Hive
    box.listenable().addListener(() {
      updateSchedule(
        box.get('schedule') ?? TrainingSchedule(trainings: {}, injuryType: ''),
      );
    });
  }

  void updateSchedule(TrainingSchedule newSchedule) {
    debugPrint('Обновление расписания:');
    debugPrint('Количество дней: ${newSchedule.trainings.length}');
    debugPrint('Ключи: ${newSchedule.trainings.keys}');
    _schedule = newSchedule;
    notifyListeners();
  }
}
