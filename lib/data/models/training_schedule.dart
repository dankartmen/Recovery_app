import 'package:hive/hive.dart';
import '../../training/models/training.dart';

@HiveType(typeId: 4)
class TrainingSchedule {
  final Map<DateTime, List<Training>> trainings;

  final String injuryType;

  final int id;

  final bool isActive;

  final int questionnaireId;

  final String specificInjury;

  TrainingSchedule({
    required this.trainings,
    required this.injuryType,
    required this.id,
    this.isActive = true,
    required this.questionnaireId,
    required this.specificInjury,
  });

  factory TrainingSchedule.fromJson(Map<String, dynamic> json) {
    final List<Training> allTrainings = (json['trainings'] as List<dynamic>? ?? [])
        .map((t) => Training.fromJson(t as Map<String, dynamic>))
        .toList();

    final Map<DateTime, List<Training>> trainingsMap = <DateTime, List<Training>>{};
    for (final training in allTrainings) {
      final normalizedDate = DateTime(training.date.year, training.date.month, training.date.day);
      trainingsMap.putIfAbsent(normalizedDate, () => <Training>[]).add(training);
    }

    return TrainingSchedule(
      trainings: trainingsMap,
      injuryType: json['injury_type'] ?? '',
      id: json['id'] ?? 0,
      isActive: json['is_active'] ?? true,
      questionnaireId: json['questionnaire_id'] ?? 0,
      specificInjury: json['specific_injury'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    final trainingsList = <Map<String, dynamic>>[];
    trainings.forEach((date, trainingList) {
      for (final training in trainingList) {
        trainingsList.add(training.toJson());
      }
    });

    return {
      'id': id,
      'injury_type': injuryType,
      'is_active': isActive,
      'questionnaire_id': questionnaireId,
      'specific_injury': specificInjury,
      'trainings': trainingsList,
    };
  }

  TrainingSchedule copyWith({
    Map<DateTime, List<Training>>? trainings,
    String? injuryType,
    int? id,
    bool? isActive,
    int? questionnaireId,
    String? specificInjury,
  }) {
    return TrainingSchedule(
      trainings: trainings ?? this.trainings,
      injuryType: injuryType ?? this.injuryType,
      id: id ?? this.id,
      isActive: isActive ?? this.isActive,
      questionnaireId: questionnaireId ?? this.questionnaireId,
      specificInjury: specificInjury ?? this.specificInjury,
    );
  }

  static TrainingSchedule empty() {
    return TrainingSchedule(
      trainings: {},
      injuryType: '',
      id: 0,
      isActive: false,
      questionnaireId: 0,
      specificInjury: '',
    );
  }
}