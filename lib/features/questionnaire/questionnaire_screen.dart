import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:provider/provider.dart';
import '../../data/models/models.dart';
import '../../data/models/training_calendar_model.dart';
import '../../data/models/training_schedule.dart';
import '../../data/repositories/questionnaire_repository.dart';
import '../../services/auth_service.dart';
import '../../styles/style.dart';
import '../home/home_screen.dart';

class QuestionnaireScreen extends StatefulWidget {
  final RecoveryData? initialData;

  const QuestionnaireScreen({super.key, this.initialData});

  @override
  QuestionnaireScreenState createState() => QuestionnaireScreenState();
}

class QuestionnaireScreenState extends State<QuestionnaireScreen> {
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
  late RecoveryData? _existingData = widget.initialData;

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
      await questionnaireRepo.saveQuestionnaire(updatedData);
      await questionnaireRepo.saveToServer(
        updatedData,
        authService.getBasicAuthHeader(),
        authService.currentUser!.id!,
      );
      await questionnaireRepo.syncWithServer(
        authService.getBasicAuthHeader(),
        authService.currentUser!.id!,
      );

      final scheduleBox = await Hive.openBox<TrainingSchedule>(
        'training_schedule',
      );
      await scheduleBox.clear();
      if (!mounted) return;

      final calendarModel = Provider.of<TrainingCalendarModel>(
        context,
        listen: false,
      );
      await calendarModel.generateAndSaveSchedule(updatedData);
      if (!mounted) return;

      calendarModel.refresh();
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => HomeScreen(recoveryData: updatedData),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ошибка сохранения: ${e.toString()}'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
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
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: healthPrimaryColor,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Container(color: healthBackgroundColor, child: _buildForm()),
    );
  }

  Widget _buildForm() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Заголовок
              Center(
                child: Text(
                  widget.initialData == null
                      ? 'Заполните анкету для персонализации'
                      : 'Обновите ваши данные',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: healthTextColor,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 20),
              const Divider(),
              const SizedBox(height: 20),

              // Секция персональных данных
              _buildSectionTitle('Персональные данные'),
              const SizedBox(height: 16),

              // Поле ФИО
              TextFormField(
                initialValue: _name,
                decoration: buildHealthInputDecoration('ФИО',null),
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
                initialValue: _gender.isNotEmpty ? _gender : null,
                decoration: buildHealthInputDecoration('Пол',null),
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

              // Вес и рост в одной строке
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      initialValue: _weight > 0 ? _weight.toString() : '',
                      keyboardType: TextInputType.number,
                      decoration: buildHealthInputDecoration('Вес (кг)', null,),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Обязательно';
                        }
                        final val = double.tryParse(value);
                        if (val == null) return 'Некорректно';
                        if (val < 30 || val > 250) return 'Недопустимо';
                        return null;
                      },
                      onSaved: (value) => _weight = double.parse(value!),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      initialValue: _height > 0 ? _height.toString() : '',
                      keyboardType: TextInputType.number,
                      decoration: buildHealthInputDecoration('Рост (см)',null,),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Обязательно';
                        }
                        final val = double.tryParse(value);
                        if (val == null || val <= 0) return 'Некорректно';
                        return null;
                      },
                      onSaved: (value) => _height = double.parse(value!),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 30),

              // Секция медицинской информации
              _buildSectionTitle('Медицинская информация'),
              const SizedBox(height: 16),

              // Выбор типа травмы
              DropdownButtonFormField<String>(
                initialValue: _mainInjuryType.isNotEmpty ? _mainInjuryType : null,
                decoration: buildHealthInputDecoration(
                  'Основной тип травмы/операции',
                  null,
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
                  initialValue: _specificInjury,
                  decoration: buildHealthInputDecoration(
                    'Конкретный вид травмы',null,
                  ),
                  isExpanded: true,
                  items:
                      injuryCategories[_mainInjuryType]!.map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                  validator:
                      (value) => value == null ? 'Выберите травму' : null,
                  onChanged: (value) => _specificInjury = value!,
                ),
              const SizedBox(height: 20),

              // Уровень дискомфорта с визуальной шкалой
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Уровень дискомфорта:',
                    style: TextStyle(
                      fontSize: 16,
                      color: healthSecondaryTextColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: Slider(
                          value: _painLevel.toDouble(),
                          min: 0,
                          max: 10,
                          divisions: 9,
                          label: _painLevel.toString(),
                          activeColor: _getPainColor(_painLevel),
                          inactiveColor: Colors.grey[300],
                          onChanged: (value) {
                            setState(() {
                              _painLevel = value.toInt();
                            });
                          },
                        ),
                      ),
                      Container(
                        width: 40,
                        alignment: Alignment.center,
                        child: Text(
                          '$_painLevel',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: _getPainColor(_painLevel),
                          ),
                        ),
                      ),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '1',
                        style: TextStyle(color: healthSecondaryTextColor),
                      ),
                      Text(
                        '5',
                        style: TextStyle(color: healthSecondaryTextColor),
                      ),
                      Text(
                        '10',
                        style: TextStyle(color: healthSecondaryTextColor),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Время на тренировки
              DropdownButtonFormField<String>(
                initialValue: _trainingTime.isNotEmpty ? _trainingTime : null,
                decoration: buildHealthInputDecoration('Время на тренировки',null,),
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
                validator: (value) => value == null ? 'Выберите время' : null,
                onChanged: (value) => _trainingTime = value!,
              ),
              const SizedBox(height: 30),

              // Согласие с политикой
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: healthPrimaryColor.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Checkbox(
                      value: _consent,
                      onChanged: (value) => setState(() => _consent = value!),
                      activeColor: healthPrimaryColor,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: RichText(
                        text: TextSpan(
                          style: TextStyle(
                            fontSize: 14,
                            color: healthTextColor,
                          ),
                          children: [
                            const TextSpan(text: 'Я согласен с '),
                            TextSpan(
                              text: 'политикой конфиденциальности',
                              style: TextStyle(
                                color: healthPrimaryColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),

              // Кнопка сохранения
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _submitQuestionnaire,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: healthPrimaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Сохранить данные',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: healthPrimaryColor,
      ),
    );
  }

  Color _getPainColor(int level) {
    if (level <= 3) return Colors.green;
    if (level <= 6) return Colors.orange;
    return Colors.red;
  }
}
