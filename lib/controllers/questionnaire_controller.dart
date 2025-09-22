import '../data/repositories/questionnaire_repository.dart';
import '../services/auth_service.dart';
import 'package:flutter/material.dart';

import '../data/models/models.dart';

/// {@template questionnaire_controller}
/// Контроллер для управления данными анкеты пользователя.
/// Обеспечивает валидацию, сохранение и синхронизацию данных анкеты.
/// {@endtemplate}
class QuestionnaireController with ChangeNotifier{
  /// Сервис аутентификации для выполнения операций входа
  final AuthService? _authService;

  /// Репозиторий для работы с данными анкеты
  final QuestionnaireRepository? _questionnaireRepo;

  /// Данные анкеты в редактируемом формате
  EditableRecoveryData _formData = EditableRecoveryData.empty();

  QuestionnaireController(this._authService, this._questionnaireRepo);

  /// Флаг состояния загрузки данных анкеты
  bool isLoading = false;

  /// Флаг состояния сохранения данных анкеты
  bool isSaving = false;

  /// Сообщение об ошибке при операциях с анкетой 
  String? errorMessage;

  /// Флаг согласия с политикой конфиденциальности
  bool consentGiven = false;

  /// Ошибки валидации полей анкеты
  Map<String, String> fieldErrors= {}; 

  // Геттеры для доступа к данным формы
  EditableRecoveryData? get formData => _formData; 
  String get name => _formData.name;
  String get gender => _formData.gender;
  double get weight => _formData.weight;
  double get height => _formData.height;
  String get mainInjuryType => _formData.mainInjuryType;
  String get specificInjury => _formData.specificInjury;
  int get painLevel => _formData.painLevel;
  String get trainingTime => _formData.trainingTime;

  /// Получение ошибки для конкретного поля анкеты
  /// Принимает:
  /// - [fieldName] - имя поля для получения ошибки
  /// Возвращает:
  /// - текст ошибки или null если ошибок нет
  String? getErrorForField(String fieldName) {
    return fieldErrors[fieldName];
  }

  /// Инициализация контроллера данными анкеты
  /// Принимает:
  /// - [initialData] - начальные данные анкеты или null
  Future<void> initialize(RecoveryData? initialData) async{
    isLoading = true;
    notifyListeners();

    try{
      _formData = initialData != null
      ? EditableRecoveryData.fromRecoveryData(initialData)
      : EditableRecoveryData.empty();

      // Если нет initialData, пробуем загрузить из хранилища
      if (initialData == null){
        final latestData = await _questionnaireRepo!.getLatestQuestionnaire();
        if (latestData != null){
          _formData = EditableRecoveryData.fromRecoveryData(latestData);
        }
      }
    }
    catch(e){
      errorMessage = 'Ошибка загрузки данных: $e';
    }
    finally{
      isLoading = false;
      notifyListeners();
    }
  }

  /// Обновление определенного поля пользователя в анкете
  /// Принимает:
  /// - [value] - новое значение имени
  void updateName(String value) {
    _formData.name = value;
    _clearFieldError('name');
    notifyListeners();
  }

  void updateGender(String value) {
    _formData.gender = value;
    _clearFieldError('gender');
    notifyListeners();
  }

  void updateWeight(String value) {
    final parsed = double.tryParse(value);
    if (parsed != null) {
      _formData.weight = parsed;
      _clearFieldError('weight');
    }
    notifyListeners();
  }

  void updateHeight(String value) {
    final parsed = double.tryParse(value);
    if (parsed != null) {
      _formData.height = parsed;
      _clearFieldError('height');
    }
    notifyListeners();
  }

  void updateMainInjuryType(String value) {
    final oldValue = _formData.mainInjuryType;
    _formData.mainInjuryType = value;
    // При смене основной категории сбрасываем конкретную травму
    if (value != oldValue) {
      _formData.specificInjury = injuryCategories[value]?.first ?? '';
    }
    _clearFieldError('mainInjuryType');
    notifyListeners();
  }

  void updateSpecificInjury(String value) {
    _formData.specificInjury = value;
    _clearFieldError('specificInjury');
    notifyListeners();
  }

  void updatePainLevel(int value) {
    _formData.painLevel = value;
    notifyListeners();
  }

  void updateTrainingTime(String value) {
    _formData.trainingTime = value;
    _clearFieldError('trainingTime');
    notifyListeners();
  }

  void updateConsent(bool value) {
    consentGiven = value;
    _clearFieldError('consent');
    notifyListeners();
  }

  void _clearFieldError(String fieldName) {
    if (fieldErrors.containsKey(fieldName)) {
      fieldErrors.remove(fieldName);
      notifyListeners();
    }
  }

  /// Валидация всех полей анкеты
  /// Возвращает:
  /// - true если все поля валидны, false если есть ошибки
  bool validate(){
    fieldErrors.clear();

    if (_formData.name.isEmpty) {
      fieldErrors['name'] = 'Поле обязательно для заполнения';
    }
    
    if (_formData.gender.isEmpty) {
      fieldErrors['gender'] = 'Выберите пол';
    }
    
    if (_formData.weight <= 0) {
      fieldErrors['weight'] = 'Введите корректный вес';
    }
    
    if (_formData.height <= 0) {
      fieldErrors['height'] = 'Введите корректный рост';
    }
    
    if (_formData.mainInjuryType.isEmpty) {
      fieldErrors['mainInjuryType'] = 'Выберите тип травмы';
    }
    
    if (_formData.specificInjury.isEmpty) {
      fieldErrors['specificInjury'] = 'Выберите конкретную травму';
    }
    
    if (_formData.trainingTime.isEmpty) {
      fieldErrors['trainingTime'] = 'Выберите время для тренировок';
    }
    
    if (!consentGiven) {
      fieldErrors['consent'] = 'Необходимо согласие с политикой конфиденциальности';
    }

    notifyListeners();

    return fieldErrors.isEmpty;
  }
  
  /// Сохранение анкеты пользователя
  /// Возвращает:
  /// - true если сохранение успешно, false при ошибке
  Future<bool> saveQuestionnaire() async{
    if(!validate()){
      return false;
    }
    isSaving = true;
    errorMessage = null;
    notifyListeners();

    try {
      final recoveryData = _formData.toRecoveryData();
      await _questionnaireRepo?.saveQuestionnaire(recoveryData);

      final userId = _authService?.currentUser?.id;
      if(userId != null){
        await _questionnaireRepo?.saveToServer(recoveryData, _authService!.getBasicAuthHeader(), userId);
      
        await _questionnaireRepo?.syncWithServer(_authService!.getBasicAuthHeader(), userId);
      }
      return true;
    } catch (e) {
      errorMessage = 'Ошибка сохранения $e';
      return false;
    } finally{
      isSaving = false;
      notifyListeners();
    }
  }

  /// Получение списка конкретных травм для выбранной категории
  /// Возвращает:
  /// - список конкретных травм или пустой список если категория не выбрана
  List<String> getSpecificInjuries(){
    if(_formData.mainInjuryType.isEmpty){
      return [];
    }
    return injuryCategories[_formData.mainInjuryType] ?? [];
  }
  
}