import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/styles/style.dart';
import '../../data/models/models.dart';
import '../bloc/questionnaire_bloc.dart';
import '../models/editable_recovery_data.dart';

/// {@template questionnaire_screen}
/// Экран анкеты пользователя.
/// Обеспечивает заполнение и редактирование данных восстановления.
/// {@endtemplate}
class QuestionnaireScreen extends StatefulWidget {
  final RecoveryData? initialData;

  const QuestionnaireScreen({super.key, this.initialData});

  @override
  QuestionnaireScreenState createState() => QuestionnaireScreenState();
}

class QuestionnaireScreenState extends State<QuestionnaireScreen> {
  late TextEditingController _nameController;
  late TextEditingController _weightController;
  late TextEditingController _heightController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _weightController = TextEditingController();
    _heightController = TextEditingController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<QuestionnaireBloc>().add(InitializeQuestionnaire(initialData: widget.initialData));
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _weightController.dispose();
    _heightController.dispose();
    super.dispose();
  }

  void _syncControllersWithData(EditableRecoveryData data) {
    _nameController.text = data.name;
    _weightController.text = data.weight > 0 ? data.weight.toStringAsFixed(0) : '';
    _heightController.text = data.height > 0 ? data.height.toStringAsFixed(0) : '';
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<QuestionnaireBloc, QuestionnaireState>(
      listener: (context, state) {
        if (state is QuestionnaireLoaded) {
          _syncControllersWithData(state.formData);
        } else if (state is QuestionnaireSaved && context.mounted) {
          debugPrint('Navigating to /home...');
          Navigator.pushReplacementNamed(context, '/home', arguments: state.formData.toRecoveryData());
        } else if (state is QuestionnaireError && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.message)));
        }
      },
      child: BlocBuilder<QuestionnaireBloc, QuestionnaireState>(
        builder: (context, state) {
          if (state is QuestionnaireLoading) {
            return const Scaffold(body: Center(child: CircularProgressIndicator()));
          }

          final loadedState = state is QuestionnaireLoaded ? state : null;
          final saving = state is QuestionnaireSaving;
          final formData = loadedState?.formData ?? EditableRecoveryData.empty();
          final fieldErrors = loadedState?.fieldErrors ?? {};
          final consentGiven = loadedState?.consentGiven ?? false;

          return Scaffold(
            appBar: AppBar(
              title: Text(
                widget.initialData == null ? 'Новая анкета' : 'Редактирование профиля',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              backgroundColor: healthPrimaryColor,
              iconTheme: const IconThemeData(color: Colors.white),
            ),
            body: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
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

                  // Поле для имени
                  TextFormField(
                    controller: _nameController,
                    onChanged: (value) => context.read<QuestionnaireBloc>().add(UpdateName(value)),
                    decoration: buildHealthInputDecoration('ФИО', fieldErrors['name']),
                  ),
                  const SizedBox(height: 20),

                  // Выбор пола
                  DropdownButtonFormField<String>(
                    value: formData.gender.isNotEmpty ? formData.gender : null,
                    onChanged: (value) => context.read<QuestionnaireBloc>().add(UpdateGender(value ?? '')),
                    items: const [
                      DropdownMenuItem(value: 'Мужской', child: Text('Мужской')),
                      DropdownMenuItem(value: 'Женский', child: Text('Женский')),
                    ],
                    decoration: buildHealthInputDecoration('Пол', fieldErrors['gender']),
                    hint: const Text('Выберите пол'),
                  ),
                  const SizedBox(height: 20),

                  // Поле веса
                  TextFormField(
                    controller: _weightController,
                    keyboardType: TextInputType.number,
                    onChanged: (value) => context.read<QuestionnaireBloc>().add(UpdateWeight(value)),
                    decoration: buildHealthInputDecoration('Вес (кг)', fieldErrors['weight']),
                  ),
                  const SizedBox(height: 20),

                  // Поле роста
                  TextFormField(
                    controller: _heightController,
                    keyboardType: TextInputType.number,
                    onChanged: (value) => context.read<QuestionnaireBloc>().add(UpdateHeight(value)),
                    decoration: buildHealthInputDecoration('Рост (см)', fieldErrors['height']),
                  ),
                  const SizedBox(height: 30),

                  // Секция травмы
                  _buildSectionTitle('Информация о травме'),
                  const SizedBox(height: 16),

                  // Выбор типа травмы
                  DropdownButtonFormField<String>(
                    value: formData.mainInjuryType.isNotEmpty ? formData.mainInjuryType : null,
                    onChanged: (value) => context.read<QuestionnaireBloc>().add(UpdateMainInjuryType(value ?? '')),
                    items: injuryCategories.keys
                        .map((category) => DropdownMenuItem(value: category, child: Text(category)))
                        .toList(),
                    decoration: buildHealthInputDecoration('Тип травмы', fieldErrors['mainInjuryType']),
                    hint: const Text('Выберите тип травмы'),
                  ),
                  const SizedBox(height: 20),

                  // Конкретная травма (зависит от типа)
                  DropdownButtonFormField<String>(
                    value: formData.specificInjury.isNotEmpty ? formData.specificInjury : null,
                    onChanged: (value) => context.read<QuestionnaireBloc>().add(UpdateSpecificInjury(value ?? '')),
                    items: (injuryCategories[formData.mainInjuryType] ?? [])
                        .map((injury) => DropdownMenuItem(value: injury, child: Text(injury)))
                        .toList(),
                    decoration: buildHealthInputDecoration('Конкретная травма', fieldErrors['specificInjury']),
                    hint: const Text('Выберите конкретную травму'),
                  ),
                  const SizedBox(height: 20),

                  // Уровень боли
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Уровень боли',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: healthTextColor),
                      ),
                      const SizedBox(height: 8),
                      Slider(
                        value: formData.painLevel.toDouble(),
                        min: 0,
                        max: 10,
                        divisions: 10,
                        label: formData.painLevel.toString(),
                        activeColor: _getPainColor(formData.painLevel),
                        onChanged: (value) => context.read<QuestionnaireBloc>().add(UpdatePainLevel(value.toInt())),
                      ),
                    ],
                  ),
                  const SizedBox(height: 30),

                  // Секция предпочтений
                  _buildSectionTitle('Предпочтения тренировок'),
                  const SizedBox(height: 16),

                  // Время тренировок
                  DropdownButtonFormField<String>(
                    value: formData.trainingTime.isNotEmpty ? formData.trainingTime : null,
                    onChanged: (value) => context.read<QuestionnaireBloc>().add(UpdateTrainingTime(value ?? '')),
                    items: const [
                      DropdownMenuItem(value: 'Утро', child: Text('Утро')),
                      DropdownMenuItem(value: 'День', child: Text('День')),
                      DropdownMenuItem(value: 'Вечер', child: Text('Вечер')),
                      DropdownMenuItem(value: 'Любое время', child: Text('Любое время')),
                    ],
                    decoration: buildHealthInputDecoration('Предпочтительное время тренировок', fieldErrors['trainingTime']),
                    hint: const Text('Выберите время'),
                  ),
                  const SizedBox(height: 30),

                  // Согласие с политикой
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Checkbox(
                          value: consentGiven,
                          onChanged: (value) => context.read<QuestionnaireBloc>().add(UpdateConsent(value ?? false)),
                          activeColor: healthPrimaryColor,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: RichText(
                            text: TextSpan(
                              style: const TextStyle(
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
                  if (fieldErrors['consent'] != null)
                    Padding(
                      padding: const EdgeInsets.only(left: 16),
                      child: Text(
                        fieldErrors['consent']!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  const SizedBox(height: 30),

                  // Кнопка сохранения
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: saving ? null : () {
                        debugPrint('Button pressed, starting save...');
                        context.read<QuestionnaireBloc>().add(ValidateForm());
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: healthPrimaryColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: saving
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
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
          );
        },
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