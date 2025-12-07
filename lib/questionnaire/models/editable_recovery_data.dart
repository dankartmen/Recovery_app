import '../../data/models/models.dart';

class EditableRecoveryData {
  String name;
  String gender;
  double weight;
  double height;
  String mainInjuryType;
  String specificInjury;
  int painLevel;
  String trainingTime;

  EditableRecoveryData({
    required this.name,
    required this.gender,
    required this.weight,
    required this.height,
    required this.mainInjuryType,
    required this.specificInjury,
    required this.painLevel,
    required this.trainingTime,
  });

  factory EditableRecoveryData.empty() {
    return EditableRecoveryData(
      name: '',
      gender: '',
      weight: 0,
      height: 0,
      mainInjuryType: '',
      specificInjury: '',
      painLevel: 0,
      trainingTime: '',
    );
  }

  factory EditableRecoveryData.fromRecoveryData(RecoveryData data) {
    return EditableRecoveryData(
      name: data.name,
      gender: data.gender,
      weight: data.weight,
      height: data.height,
      mainInjuryType: data.mainInjuryType,
      specificInjury: data.specificInjury,
      painLevel: data.painLevel,
      trainingTime: data.trainingTime,
    );
  }

  RecoveryData toRecoveryData({int? id}) {
    return RecoveryData(
      id: id,
      name: name,
      gender: gender,
      weight: weight,
      height: height,
      mainInjuryType: mainInjuryType,
      specificInjury: specificInjury,
      painLevel: painLevel,
      trainingTime: trainingTime,
    );
  }

  EditableRecoveryData copyWith({
    String? name,
    String? gender,
    double? weight,
    double? height,
    String? mainInjuryType,
    String? specificInjury,
    int? painLevel,
    String? trainingTime,
  }) {
    return EditableRecoveryData(
      name: name ?? this.name,
      gender: gender ?? this.gender,
      weight: weight ?? this.weight,
      height: height ?? this.height,
      mainInjuryType: mainInjuryType ?? this.mainInjuryType,
      specificInjury: specificInjury ?? this.specificInjury,
      painLevel: painLevel ?? this.painLevel,
      trainingTime: trainingTime ?? this.trainingTime,
    );
  }
}