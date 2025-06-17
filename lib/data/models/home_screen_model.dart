import 'package:flutter/material.dart';

import 'training_schedule.dart';

class HomeScreenModel extends ChangeNotifier {
  TrainingSchedule _schedule = TrainingSchedule(trainings: {}, injuryType: '');

  TrainingSchedule get schedule => _schedule;

  void updateSchedule(TrainingSchedule newSchedule) {
    debugPrint('Обновление расписания:');
    debugPrint('Количество дней: ${newSchedule.trainings.length}');
    debugPrint('Ключи: ${newSchedule.trainings.keys}');
    _schedule = newSchedule;
    notifyListeners();
  }
}
