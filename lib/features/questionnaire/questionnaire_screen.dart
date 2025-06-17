import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/models/models.dart';
import '../../data/repositories/questionnaire_repository.dart';
import '../../services/auth_service.dart';
import '../home/home_screen.dart';

// Экран заполнения анкеты
class QuestionnaireScreen extends StatefulWidget {
  final RecoveryData? initialData;

  const QuestionnaireScreen({super.key, this.initialData});

  @override
  _QuestionnaireScreenState createState() => _QuestionnaireScreenState();
}

class _QuestionnaireScreenState extends State<QuestionnaireScreen> {
  final _formKey = GlobalKey<FormState>();
  late String _name = widget.initialData?.name ?? '';
  late String _gender = widget.initialData?.gender ?? '';
  late double _weight = widget.initialData?.weight ?? 0.0;
  late double _height = widget.initialData?.height ?? 0.0;
  late String _mainInjuryType = widget.initialData?.mainInjuryType ?? '';
  late String _specificInjury = widget.initialData?.specificInjury ?? '';
  late int _painLevel = widget.initialData?.painLevel ?? 0;
  late String _trainingTime = widget.initialData?.trainingTime ?? '';
  bool _consent = false;
  late RecoveryData? _existingData = widget.initialData ?? null;

  @override
  void initState() {
    super.initState();
    _loadExistingData();
  }

  Future<void> _loadExistingData() async {
    if (widget.initialData != null) {
      setState(() {
        _existingData = widget.initialData;
        _name = widget.initialData!.name;
        _gender = widget.initialData!.gender;
        _weight = widget.initialData!.weight;
        _height = widget.initialData!.height;
        _mainInjuryType = widget.initialData!.mainInjuryType;
        _specificInjury = widget.initialData!.specificInjury;
        _painLevel = widget.initialData!.painLevel;
        _trainingTime = widget.initialData!.trainingTime;
      });
    }
  }

  Future<void> _submitQuestionnaire() async {
    if (!_formKey.currentState!.validate() || !_consent) return;

    final authService = Provider.of<AuthService>(context, listen: false);
    final questionnaireRepo = Provider.of<QuestionnaireRepository>(
      context,
      listen: false,
    );

    _formKey.currentState!.save();

    final updatedData = RecoveryData(
      id: _existingData?.id,
      name: _name,
      gender: _gender,
      weight: _weight,
      height: _height,
      mainInjuryType: _mainInjuryType,
      specificInjury: _specificInjury,
      painLevel: _painLevel,
      trainingTime: _trainingTime,
    );

    try {
      // Сохраняем анкету локально
      await questionnaireRepo.saveQuestionnaire(updatedData);

      //  Сохраняем анкету на сервере
      await questionnaireRepo.saveToServer(
        updatedData,
        authService.getBasicAuthHeader(),
        authService.currentUser!.id!,
      );

      //  Синхронизируем локальные данные с сервером
      await questionnaireRepo.syncWithServer(
        authService.getBasicAuthHeader(),
        authService.currentUser!.id!,
      );

      // Переходим на домашний экран
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => HomeScreen(recoveryData: updatedData),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка сохранения: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.initialData == null
              ? 'Новая анкета'
              : 'Редактирование профиля',
        ),
      ),
      body: _buildForm(),
      floatingActionButton: FloatingActionButton(
        onPressed: _submitQuestionnaire,
        child: const Icon(Icons.save),
      ),
    );
  }

  Widget _buildForm() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Поле ФИО
              TextFormField(
                initialValue: _name,
                decoration: const InputDecoration(
                  labelText: 'ФИО',
                  hintText: 'Введите ваше полное имя',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Поле обязательно для заполнения';
                  }
                  return null;
                },
                onSaved: (value) => _name = value!,
              ),
              const SizedBox(height: 20),

              // Выбор пола
              DropdownButtonFormField<String>(
                value: _gender.isNotEmpty ? _gender : null,
                decoration: const InputDecoration(
                  labelText: 'Пол',
                  border: OutlineInputBorder(),
                ),
                items:
                    ['Мужской', 'Женский'].map((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                validator: (value) => value == null ? 'Выберите ваш пол' : null,
                onChanged: (value) => _gender = value!,
              ),
              const SizedBox(height: 20),

              // Поле Вес
              TextFormField(
                initialValue: _weight > 0 ? _weight.toString() : '',
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Вес (кг)',
                  hintText: 'Введите ваш вес',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Поле обязательно для заполнения';
                  }
                  final weight = double.tryParse(value);
                  if (weight == null || weight <= 0) {
                    return 'Введите корректное значение';
                  }
                  return null;
                },
                onSaved: (value) => _weight = double.parse(value!),
              ),
              const SizedBox(height: 20),

              // Поле Рост
              TextFormField(
                initialValue: _height > 0 ? _height.toString() : '',
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Рост (см)',
                  hintText: 'Введите ваш рост',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Поле обязательно для заполнения';
                  }
                  final height = double.tryParse(value);
                  if (height == null || height <= 0) {
                    return 'Введите корректное значение';
                  }
                  return null;
                },
                onSaved: (value) => _height = double.parse(value!),
              ),
              const SizedBox(height: 20),

              // Выбор типа травмы
              DropdownButtonFormField<String>(
                value: _mainInjuryType.isNotEmpty ? _mainInjuryType : null,
                decoration: const InputDecoration(
                  labelText: 'Основной тип травмы/операции',
                  border: OutlineInputBorder(),
                ),
                items:
                    injuryCategories.keys.map((String key) {
                      return DropdownMenuItem<String>(
                        value: key,
                        child: Text(key),
                      );
                    }).toList(),
                validator:
                    (value) => value == null ? 'Выберите тип травмы' : null,
                onChanged: (value) {
                  setState(() {
                    _mainInjuryType = value!;
                    _specificInjury = injuryCategories[value]!.first;
                  });
                },
              ),
              const SizedBox(height: 20),

              // Выбор конкретной травмы
              if (_mainInjuryType.isNotEmpty)
                DropdownButtonFormField<String>(
                  value: _specificInjury,
                  decoration: const InputDecoration(
                    labelText: 'Конкретный вид травмы',
                    border: OutlineInputBorder(),
                  ),
                  items:
                      injuryCategories[_mainInjuryType]!.map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                  validator:
                      (value) =>
                          value == null ? 'Выберите конкретную травму' : null,
                  onChanged: (value) => _specificInjury = value!,
                ),
              const SizedBox(height: 20),

              // Уровень дискомфорта
              TextFormField(
                initialValue: _painLevel > 0 ? _painLevel.toString() : '',
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Уровень дискомфорта (1-10)',
                  hintText: 'Оцените по шкале от 1 до 10',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Поле обязательно для заполнения';
                  }
                  final pain = int.tryParse(value);
                  if (pain == null || pain < 1 || pain > 10) {
                    return 'Введите значение от 1 до 10';
                  }
                  return null;
                },
                onSaved: (value) => _painLevel = int.parse(value!),
              ),
              const SizedBox(height: 20),

              // Время на тренировки
              DropdownButtonFormField<String>(
                value: _trainingTime.isNotEmpty ? _trainingTime : null,
                decoration: const InputDecoration(
                  labelText: 'Время на тренировки',
                  border: OutlineInputBorder(),
                ),
                items:
                    [
                      '15 минут/день',
                      '30 минут/день',
                      '1 час/день',
                      'Более часа/день',
                    ].map((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                validator:
                    (value) =>
                        value == null ? 'Выберите время тренировок' : null,
                onChanged: (value) => _trainingTime = value!,
              ),
              const SizedBox(height: 20),

              // Согласие с политикой
              CheckboxListTile(
                title: const Text(
                  'Я согласен с политикой конфиденциальности',
                  style: TextStyle(fontSize: 16),
                ),
                value: _consent,
                onChanged: (value) => setState(() => _consent = value!),
                controlAffinity: ListTileControlAffinity.leading,
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}
