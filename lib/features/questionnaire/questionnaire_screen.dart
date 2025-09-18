import 'package:auth_test/controllers/questionnaire_controller.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/models/models.dart';
import '../../styles/style.dart';


class QuestionnaireScreen extends StatefulWidget {
  final RecoveryData? initialData;

  const QuestionnaireScreen({super.key, this.initialData});

  @override
  QuestionnaireScreenState createState() => QuestionnaireScreenState();
}

class QuestionnaireScreenState extends State<QuestionnaireScreen> {

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_){
      final controller = Provider.of<QuestionnaireController>(context, listen: false);
      controller.initialize(widget.initialData);
    });
  }

  @override
  Widget build(BuildContext context) {
    final controller = Provider.of<QuestionnaireController>(context);

    if(controller.isLoading){
      return Scaffold(body: Center(child: CircularProgressIndicator(),),);
    }


    return Scaffold(
      appBar: AppBar(
        title: Text(
          controller.formData == null
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
      body: SingleChildScrollView(
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

            // Поле для имени
            TextFormField(
              initialValue: controller.name,
              onChanged: controller.updateName,
              decoration: buildHealthInputDecoration('ФИО',controller.getErrorForField('name')),
            ),
            const SizedBox(height: 20),

            // Выбор пола
            DropdownButtonFormField<String>(
              initialValue: controller.gender.isNotEmpty ? controller.gender : null,
              decoration: buildHealthInputDecoration('Пол',controller.getErrorForField('gender')),
              items:
                  ['Мужской', 'Женский'].map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
              onChanged: (value) => controller.updateGender(value!),
            ),
            const SizedBox(height: 20),

            // Вес и рост в одной строке
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    initialValue: controller.weight > 0 ? controller.weight.toString() : '',
                    keyboardType: TextInputType.number,
                    decoration: buildHealthInputDecoration('Вес (кг)', controller.getErrorForField('weight'),),
                    onChanged: (value) {
                      controller.updateWeight(value);
                      /*if (value == null || value.isEmpty) {
                        return 'Обязательно';
                      }
                      final val = double.tryParse(value);
                      if (val == null) return 'Некорректно';
                      if (val < 30 || val > 250) return 'Недопустимо';
                      return null;
                    },*/
                   }
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    initialValue: controller.height > 0 ? controller.height.toString() : '',
                    keyboardType: TextInputType.number,
                    decoration: buildHealthInputDecoration('Рост (см)',controller.getErrorForField('height'),),
                    onChanged: (value) {
                      controller.updateHeight(value);
                      /*
                      if (value == null || value.isEmpty) {
                        return 'Обязательно';
                      }
                      final val = double.tryParse(value);
                      if (val == null || val <= 0) return 'Некорректно';
                      return null;
                    },
                    onSaved: (value) => _height = double.parse(value!),*/
                    }
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
              value: controller.mainInjuryType.isNotEmpty ? controller.mainInjuryType : null,
              decoration: buildHealthInputDecoration(
                'Основной тип травмы/операции',
                controller.getErrorForField('mainInjuryType'),
              ),
              items:
                  injuryCategories.keys.map((String key) {
                    return DropdownMenuItem<String>(
                      value: key,
                      child: Text(key),
                    );
                  }).toList(),
              onChanged: (value) {
                controller.updateMainInjuryType(value!);
              },
            ),
            const SizedBox(height: 20),

            // Выбор конкретной травмы
            if (controller.mainInjuryType.isNotEmpty)
              DropdownButtonFormField<String>(
                value: controller.specificInjury,
                decoration: buildHealthInputDecoration(
                  'Конкретный вид травмы',controller.getErrorForField('specificInjury'),
                ),
                isExpanded: true,
                items:
                    injuryCategories[controller.mainInjuryType]!.map((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                onChanged: (value) => controller.updateSpecificInjury(value!),
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
                        value: controller.painLevel.toDouble(),
                        min: 0,
                        max: 10,
                        divisions: 9,
                        label: controller.painLevel.toString(),
                        activeColor: _getPainColor(controller.painLevel),
                        inactiveColor: Colors.grey[300],
                        onChanged: (value) {
                          controller.updatePainLevel(value.toInt());
                        },
                      ),
                    ),
                    Container(
                      width: 40,
                      alignment: Alignment.center,
                      child: Text(
                        '${controller.painLevel}',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: _getPainColor(controller.painLevel),
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
              initialValue: controller.trainingTime.isNotEmpty ? controller.trainingTime : null,
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
              onChanged: (value) => controller.updateTrainingTime(value!),
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
                    value: controller.consentGiven,
                    onChanged: (value) => controller.updateConsent(value!),
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
                onPressed: controller.isSaving ? null : () async {
                  final success = await controller.saveQuestionnaire();
                  if (success && context.mounted){
                    Navigator.pushReplacementNamed(context, '/home');
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: healthPrimaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: controller.isSaving ? CircularProgressIndicator()
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
