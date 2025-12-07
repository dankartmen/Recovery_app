part of 'questionnaire_bloc.dart';

/// Базовый класс для событий анкеты
abstract class QuestionnaireEvent extends Equatable {
  const QuestionnaireEvent();

  @override
  List<Object?> get props => [];
}

/// Событие инициализации анкеты
/// Принимает:
/// - [initialData] - начальные данные анкеты (опционально)
class InitializeQuestionnaire extends QuestionnaireEvent {
  final RecoveryData? initialData;
  const InitializeQuestionnaire({this.initialData});
  @override
  List<Object?> get props => [initialData];
}

/// Событие обновления имени
/// Принимает:
/// - [value] - новое значение имени
class UpdateName extends QuestionnaireEvent {
  final String value;
  const UpdateName(this.value);
  @override
  List<Object?> get props => [value];
}

/// Событие обновления пола
/// Принимает:
/// - [value] - новое значение пола
class UpdateGender extends QuestionnaireEvent {
  final String value;
  const UpdateGender(this.value);
  @override
  List<Object?> get props => [value];
}

/// Событие обновления веса
/// Принимает:
/// - [value] - новое значение веса
class UpdateWeight extends QuestionnaireEvent {
  final String value;
  const UpdateWeight(this.value);
  @override
  List<Object?> get props => [value];
}

/// Событие обновления роста
/// Принимает:
/// - [value] - новое значение роста
class UpdateHeight extends QuestionnaireEvent {
  final String value;
  const UpdateHeight(this.value);
  @override
  List<Object?> get props => [value];
}

/// Событие обновления основного типа травмы
/// Принимает:
/// - [value] - новое значение основного типа травмы
class UpdateMainInjuryType extends QuestionnaireEvent {
  final String value;
  const UpdateMainInjuryType(this.value);
  @override
  List<Object?> get props => [value];
}

/// Событие обновления конкретной травмы
/// Принимает:
/// - [value] - новое значение конкретной травмы
class UpdateSpecificInjury extends QuestionnaireEvent {
  final String value;
  const UpdateSpecificInjury(this.value);
  @override
  List<Object?> get props => [value];
}

/// Событие обновления уровня боли
/// Принимает:
/// - [value] - новое значение уровня боли
class UpdatePainLevel extends QuestionnaireEvent {
  final int value;
  const UpdatePainLevel(this.value);
  @override
  List<Object?> get props => [value];
}

/// Событие обновления времени тренировок
/// Принимает:
/// - [value] - новое значение времени тренировок
class UpdateTrainingTime extends QuestionnaireEvent {
  final String value;
  const UpdateTrainingTime(this.value);
  @override
  List<Object?> get props => [value];
}

/// Событие обновления согласия с политикой конфиденциальности
/// Принимает:
/// - [value] - новое значение согласия
class UpdateConsent extends QuestionnaireEvent {
  final bool value;
  const UpdateConsent(this.value);
  @override
  List<Object?> get props => [value];
}

/// Событие валидации формы анкеты
class ValidateForm extends QuestionnaireEvent {}

/// Событие сохранения анкеты
class SaveQuestionnaire extends QuestionnaireEvent {}

/// Событие очистки ошибки
class ClearError extends QuestionnaireEvent {}