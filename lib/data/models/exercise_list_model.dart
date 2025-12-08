import '../../exercises/models/exercise.dart';
import '../../services/exercise_service.dart';
import 'package:flutter/material.dart';

class ExerciseListModel extends ChangeNotifier {
  final ExerciseService exerciseService;
  bool _isLoading = false;
  List<Exercise> _exercises = [];
  String? _error;

  List<Exercise> get exercises => _exercises;
  String? get error => _error;
  bool get isLoading => _isLoading;

  ExerciseListModel({required this.exerciseService});

  Future<void> loadExercises({String? injuryType, int? minPainLevel}) async {
    _isLoading = true;
    _error = null;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });

    try {
      final result = await exerciseService.getExercises(injuryType: injuryType);
      if (minPainLevel != null) {
        _exercises =
            result.where((e) => e.maxPainLevel >= minPainLevel).toList();
      } else {
        _exercises = result;
      }
    } catch (e) {
      debugPrint("Ошибка в exerciseListModel");
      _error = "Не удалось загрузить упражнения";
      _exercises = [];
    } finally {
      _isLoading = false;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifyListeners();
      });
    }
  }
}
