import 'package:hive/hive.dart';

class RecoveryData {
  final int? id;
  final String name;
  final String gender;
  final double weight;
  final double height;
  final String mainInjuryType;
  final String specificInjury;
  final int painLevel;
  final String trainingTime;

  RecoveryData({
    this.id,
    required this.name,
    required this.gender,
    required this.weight,
    required this.height,
    required this.mainInjuryType,
    required this.specificInjury,
    required this.painLevel,
    required this.trainingTime,
  });

  static RecoveryData empty() {
    return RecoveryData(
      name: 'Не указано',
      gender: 'Не указано',
      weight: 0,
      height: 0,
      mainInjuryType: 'Не указано',
      specificInjury: 'Не указано',
      painLevel: 0,
      trainingTime: 'Не указано',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'gender': gender,
      'weight': weight,
      'height': height,
      'mainInjuryType': mainInjuryType,
      'specificInjury': specificInjury,
      'painLevel': painLevel,
      'trainingTime': trainingTime,
    };
  }

  RecoveryData copy() {
    return RecoveryData(
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

  factory RecoveryData.fromMap(Map<String, dynamic> map) {
    return RecoveryData(
      id: map['id'],
      name: map['name'],
      gender: map['gender'],
      weight: map['weight'],
      height: map['height'],
      mainInjuryType: map['mainInjuryType'],
      specificInjury: map['specificInjury'],
      painLevel: map['painLevel'],
      trainingTime: map['trainingTime'],
    );
  }

  factory RecoveryData.fromJson(Map<String, dynamic> json) {
    return RecoveryData(
      id: json['id'] as int?,
      name: json['name'] as String,
      gender: json['gender'] as String,
      weight: json['weight'] as double,
      height: json['height'] as double,
      mainInjuryType: json['main_injury_type'] as String,
      specificInjury: json['specific_injury'] as String,
      painLevel: json['pain_level'] as int,
      trainingTime: json['training_time'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'gender': gender,
      'weight': weight,
      'height': height,
      'main_injury_type': mainInjuryType,
      'specific_injury': specificInjury,
      'pain_level': painLevel,
      'training_time': trainingTime,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RecoveryData &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          gender == other.gender &&
          weight == other.weight &&
          height == other.height &&
          mainInjuryType == other.mainInjuryType &&
          specificInjury == other.specificInjury &&
          painLevel == other.painLevel &&
          trainingTime == other.trainingTime;

  @override
  int get hashCode =>
      id.hashCode ^
      name.hashCode ^
      gender.hashCode ^
      weight.hashCode ^
      height.hashCode ^
      mainInjuryType.hashCode ^
      specificInjury.hashCode ^
      painLevel.hashCode ^
      trainingTime.hashCode;
}

class EditableRecoveryData {
  int? id;
  String name;
  String gender;
  double weight;
  double height;
  String mainInjuryType;
  String specificInjury;
  int painLevel;
  String trainingTime;

  EditableRecoveryData({
    this.id,
    required this.name,
    required this.gender,
    required this.weight,
    required this.height,
    required this.mainInjuryType,
    required this.specificInjury,
    required this.painLevel,
    required this.trainingTime,
  });

  factory EditableRecoveryData.fromRecoveryData(RecoveryData data) {
    return EditableRecoveryData(
      id: data.id,
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

  RecoveryData toRecoveryData() {
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
}

@HiveType(typeId: 2)
class Exercise {
  @HiveField(0)
  final int? id;
  @HiveField(1)
  final String title;
  @HiveField(2)
  final String generalDescription;
  @HiveField(3)
  final Map<String, String> injurySpecificInfo;
  @HiveField(4)
  final List<String> suitableFor;
  @HiveField(5)
  final int maxPainLevel;
  @HiveField(6)
  final List<String> steps;
  @HiveField(7)
  final List<String> tags;
  @HiveField(8)
  final String? imageUrl;

  Exercise({
    this.id,
    required this.title,
    required this.generalDescription,
    this.injurySpecificInfo = const {},
    required this.suitableFor,
    required this.maxPainLevel,
    required this.steps,
    required this.tags,
    this.imageUrl,
  });

  factory Exercise.fromJson(Map<String, dynamic> json) {
    return Exercise(
      id: json['id'],
      title: json['title'],
      generalDescription: json['general_description'],
      injurySpecificInfo: _parseInjuryInfo(json['injury_specific_info']),
      suitableFor: List<String>.from(json['suitable_for']),
      maxPainLevel: json['max_pain_level'],
      steps: List<String>.from(json['steps']),
      tags: List<String>.from(json['tags']),
      imageUrl: json['image_url'],
    );
  }
  // Вспомогательный метод для обработки injury_specific_info
  static Map<String, String> _parseInjuryInfo(dynamic data) {
    if (data == null) return {};
    if (data is Map<String, dynamic>) {
      return data.map((key, value) => MapEntry(key, value.toString()));
    }
    return {};
  }
}

// категории травм
final injuryCategories = {
  'Ортопедические': [
    'Перелом конечностей',
    'Эндопротезирование сустава',
    'Разрыв связок',
    'Другая ортопедическая травма',
  ],
  'Нейрохирургические': [
    'Инсульт',
    'Операция на позвоночнике',
    'Черепно-мозговая травма',
    'Другая нейрохирургическая проблема',
  ],
  'Спортивные травмы': [
    'Разрыв ахиллова сухожилия',
    'Вывих плеча',
    'Повреждение мениска',
    'Другая спортивная травма',
  ],
  'Послеоперационная реабилитация': [
    'Аппендэктомия',
    'Кесарево сечение',
    'Лапароскопические операции',
    'Другая послеоперационная реабилитация',
  ],
  'Хронические заболевания': [
    'Артрит',
    'Рассеянный склероз',
    'Остеохондроз',
    'Другое хроническое заболевание',
  ],
};
