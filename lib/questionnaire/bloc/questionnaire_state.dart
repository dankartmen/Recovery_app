part of 'questionnaire_bloc.dart';

abstract class QuestionnaireState extends Equatable {
  const QuestionnaireState();

  @override
  List<Object?> get props => [];
}

class QuestionnaireInitial extends QuestionnaireState {}

class QuestionnaireLoading extends QuestionnaireState {}

class QuestionnaireLoaded extends QuestionnaireState {
  final EditableRecoveryData formData;
  final Map<String, String> fieldErrors;
  final bool consentGiven;

  const QuestionnaireLoaded({
    required this.formData,
    this.fieldErrors = const {},
    this.consentGiven = false,
  });

  QuestionnaireLoaded copyWith({
    EditableRecoveryData? formData,
    Map<String, String>? fieldErrors,
    bool? consentGiven,
  }) {
    return QuestionnaireLoaded(
      formData: formData ?? this.formData,
      fieldErrors: fieldErrors ?? this.fieldErrors,
      consentGiven: consentGiven ?? this.consentGiven,
    );
  }

  @override
  List<Object?> get props => [formData, fieldErrors, consentGiven];
}

class QuestionnaireSaving extends QuestionnaireState {
  final EditableRecoveryData formData;
  const QuestionnaireSaving({required this.formData});

  @override
  List<Object?> get props => [formData];
}

class QuestionnaireSaved extends QuestionnaireState {
  final EditableRecoveryData formData;
  const QuestionnaireSaved({required this.formData});

  @override
  List<Object?> get props => [formData];
}

class QuestionnaireError extends QuestionnaireState {
  final String message;
  const QuestionnaireError({required this.message});

  @override
  List<Object?> get props => [message];
}