import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import '../../data/models/models.dart';
import '../../data/repositories/questionnaire_repository.dart';
import '../../services/auth_service.dart';
import '../models/editable_recovery_data.dart'; 

part 'questionnaire_event.dart';
part 'questionnaire_state.dart';

/// BLoC для управления данными анкеты пользователя.
/// Обеспечивает валидацию, сохранение и синхронизацию данных анкеты.
class QuestionnaireBloc extends Bloc<QuestionnaireEvent, QuestionnaireState> {
  final AuthService authService;
  final QuestionnaireRepository repository;

  QuestionnaireBloc({required this.authService, required this.repository}) : super(QuestionnaireInitial()) {
    // Регистрация обработчиков событий
    on<InitializeQuestionnaire>(_onInitialize);
    on<UpdateName>(_onUpdateName);
    on<UpdateGender>(_onUpdateGender);
    on<UpdateWeight>(_onUpdateWeight);
    on<UpdateHeight>(_onUpdateHeight);
    on<UpdateMainInjuryType>(_onUpdateMainInjuryType);
    on<UpdateSpecificInjury>(_onUpdateSpecificInjury);
    on<UpdatePainLevel>(_onUpdatePainLevel);
    on<UpdateTrainingTime>(_onUpdateTrainingTime);
    on<UpdateConsent>(_onUpdateConsent);
    on<ValidateForm>(_onValidateForm);
    on<SaveQuestionnaire>(_onSaveQuestionnaire);
    on<ClearError>(_onClearError);
  }

  /// Инициализация анкеты
  /// Принимает:
  /// - [event] - событие инициализации
  /// - [emit] - функция для эмиттинга состояния
  Future<void> _onInitialize(InitializeQuestionnaire event, Emitter<QuestionnaireState> emit) async {
    emit(QuestionnaireLoading());
    try {
      RecoveryData? initialData = event.initialData ?? await repository.getLatestQuestionnaire();
      final formData = initialData != null
          ? EditableRecoveryData.fromRecoveryData(initialData)
          : EditableRecoveryData.empty();

      final userId = authService.currentUser?.id;
      if (userId != null) {
        await repository.syncWithServer(authService.getBasicAuthHeader(), userId);
        // Перезагрузка после sync
        initialData = await repository.getLatestQuestionnaire();
        final syncedFormData = initialData != null
            ? EditableRecoveryData.fromRecoveryData(initialData)
            : formData;
        emit(QuestionnaireLoaded(formData: syncedFormData));
      } else {
        emit(QuestionnaireLoaded(formData: formData));
      }
    } catch (e) {
      emit(QuestionnaireError(message: 'Ошибка загрузки данных: $e'));
    }
  }

  /// Обновление имени
  /// Принимает:
  /// - [event] - событие с новым значением имени
  /// - [emit] - функция для эмиттинга состояния
  void _onUpdateName(UpdateName event, Emitter<QuestionnaireState> emit) {
    if (state is QuestionnaireLoaded) {
      final current = (state as QuestionnaireLoaded);
      emit(current.copyWith(
        formData: current.formData.copyWith(name: event.value),
        fieldErrors: _clearFieldError(current.fieldErrors, 'name'),
      ));
    }
  }

  /// Обновление пола
  /// Принимает:
  /// - [event] - событие с новым значением пола
  /// - [emit] - функция для эмиттинга состояния
  void _onUpdateGender(UpdateGender event, Emitter<QuestionnaireState> emit) {
    if (state is QuestionnaireLoaded) {
      final current = (state as QuestionnaireLoaded);
      emit(current.copyWith(
        formData: current.formData.copyWith(gender: event.value),
        fieldErrors: _clearFieldError(current.fieldErrors, 'gender'),
      ));
    }
  }

  /// Обновление веса
  /// Принимает:
  /// - [event] - событие с новым значением веса
  /// - [emit] - функция для эмиттинга состояния
  void _onUpdateWeight(UpdateWeight event, Emitter<QuestionnaireState> emit) {
    if (state is QuestionnaireLoaded) {
      final current = (state as QuestionnaireLoaded);
      final parsed = double.tryParse(event.value) ?? 0;
      emit(current.copyWith(
        formData: current.formData.copyWith(weight: parsed),
        fieldErrors: _clearFieldError(current.fieldErrors, 'weight'),
      ));
    }
  }

  /// Обновление роста
  /// Принимает:
  /// - [event] - событие с новым значением роста
  /// - [emit] - функция для эмиттинга состояния
  void _onUpdateHeight(UpdateHeight event, Emitter<QuestionnaireState> emit) {
    if (state is QuestionnaireLoaded) {
      final current = (state as QuestionnaireLoaded);
      final parsed = double.tryParse(event.value) ?? 0;
      emit(current.copyWith(
        formData: current.formData.copyWith(height: parsed),
        fieldErrors: _clearFieldError(current.fieldErrors, 'height'),
      ));
    }
  }

  /// Обновление основного типа травмы
  /// Принимает:
  /// - [event] - событие с новым значением типа травмы
  /// - [emit] - функция для эмиттинга состояния
  void _onUpdateMainInjuryType(UpdateMainInjuryType event, Emitter<QuestionnaireState> emit) {
    if (state is QuestionnaireLoaded) {
      final current = (state as QuestionnaireLoaded);
      final newSpecific = event.value != current.formData.mainInjuryType
          ? injuryCategories[event.value]?.first ?? ''
          : current.formData.specificInjury;
      emit(current.copyWith(
        formData: current.formData.copyWith(
          mainInjuryType: event.value,
          specificInjury: newSpecific,
        ),
        fieldErrors: _clearFieldError(current.fieldErrors, 'mainInjuryType'),
      ));
    }
  }

  /// Обновление конкретной травмы
  /// Принимает:
  /// - [event] - событие с новым значением конкретной травмы
  /// - [emit] - функция для эмиттинга состояния
  void _onUpdateSpecificInjury(UpdateSpecificInjury event, Emitter<QuestionnaireState> emit) {
    if (state is QuestionnaireLoaded) {
      final current = (state as QuestionnaireLoaded);
      emit(current.copyWith(
        formData: current.formData.copyWith(specificInjury: event.value),
        fieldErrors: _clearFieldError(current.fieldErrors, 'specificInjury'),
      ));
    }
  }

  /// Обновление уровня боли
  /// Принимает:
  /// - [event] - событие с новым значением уровня боли
  /// - [emit] - функция для эмиттинга состояния
  void _onUpdatePainLevel(UpdatePainLevel event, Emitter<QuestionnaireState> emit) {
    if (state is QuestionnaireLoaded) {
      final current = (state as QuestionnaireLoaded);
      emit(current.copyWith(
        formData: current.formData.copyWith(painLevel: event.value),
      ));
    }
  }

  /// Обновление времени тренировок
  /// Принимает:
  /// - [event] - событие с новым значением времени тренировок
  /// - [emit] - функция для эмиттинга состояния
  void _onUpdateTrainingTime(UpdateTrainingTime event, Emitter<QuestionnaireState> emit) {
    if (state is QuestionnaireLoaded) {
      final current = (state as QuestionnaireLoaded);
      emit(current.copyWith(
        formData: current.formData.copyWith(trainingTime: event.value),
        fieldErrors: _clearFieldError(current.fieldErrors, 'trainingTime'),
      ));
    }
  }

  /// Обновление согласия с политикой конфиденциальности
  /// Принимает:
  /// - [event] - событие с новым значением согласия
  /// - [emit] - функция для эмиттинга состояния
  void _onUpdateConsent(UpdateConsent event, Emitter<QuestionnaireState> emit) {
    if (state is QuestionnaireLoaded) {
      final current = (state as QuestionnaireLoaded);
      emit(current.copyWith(
        consentGiven: event.value,
        fieldErrors: _clearFieldError(current.fieldErrors, 'consent'),
      ));
    }
  }

  /// Валидация формы анкеты
  /// Принимает:
  /// - [event] - событие валидации
  /// - [emit] - функция для эмиттинга состояния
  void _onValidateForm(ValidateForm event, Emitter<QuestionnaireState> emit) {
    if (state is QuestionnaireLoaded) {
      final current = (state as QuestionnaireLoaded);
      final errors = <String, String>{};

      if (current.formData.name.isEmpty) errors['name'] = 'Поле обязательно для заполнения';
      if (current.formData.gender.isEmpty) errors['gender'] = 'Выберите пол';
      if (current.formData.weight <= 0) errors['weight'] = 'Введите корректный вес';
      if (current.formData.height <= 0) errors['height'] = 'Введите корректный рост';
      if (current.formData.mainInjuryType.isEmpty) errors['mainInjuryType'] = 'Выберите тип травмы';
      if (current.formData.specificInjury.isEmpty) errors['specificInjury'] = 'Выберите конкретную травму';
      if (current.formData.trainingTime.isEmpty) errors['trainingTime'] = 'Выберите время для тренировок';
      if (!current.consentGiven) errors['consent'] = 'Необходимо согласие с политикой конфиденциальности';

      emit(current.copyWith(fieldErrors: errors));

      if (errors.isEmpty) {
        add(SaveQuestionnaire());
      }
    }
  }

  /// Сохранение анкеты
  /// Принимает:
  /// - [event] - событие сохранения
  /// - [emit] - функция для эмиттинга состояния
  Future<void> _onSaveQuestionnaire(SaveQuestionnaire event, Emitter<QuestionnaireState> emit) async {
    if (state is QuestionnaireLoaded) {
      final current = (state as QuestionnaireLoaded);
      emit(QuestionnaireSaving(formData: current.formData));

      try {
        final recoveryData = current.formData.toRecoveryData();
        await repository.saveQuestionnaire(recoveryData);
        final userId = authService.currentUser?.id;
        if (userId != null) {
          await repository.saveToServer(recoveryData, authService.getBasicAuthHeader(), userId);
          await repository.syncWithServer(authService.getBasicAuthHeader(), userId);
        }
        emit(QuestionnaireSaved(formData: current.formData));
      } catch (e) {
        emit(QuestionnaireError(message: 'Ошибка сохранения $e'));
      }
    }
  }

  /// Очистка ошибки
  /// Принимает:
  /// - [event] - событие очистки ошибки
  /// - [emit] - функция для эмиттинга состояния
  void _onClearError(ClearError event, Emitter<QuestionnaireState> emit) {
    if (state is QuestionnaireError) {
      emit(QuestionnaireLoaded(formData: EditableRecoveryData.empty()));
    }
  }

  /// Очистка ошибки для конкретного поля
  /// Принимает:
  /// - [errors] - текущий словарь ошибок
  /// - [field] - поле для очистки
  /// Возвращает:
  /// - [Map<String, String>] - обновленный словарь ошибок
  Map<String, String> _clearFieldError(Map<String, String> errors, String field) {
    final newErrors = Map<String, String>.from(errors);
    newErrors.remove(field);
    return newErrors;
  }
}