import 'package:flutter/material.dart';
import 'package:recovery_app/data/repositories/questionnaire_repository.dart';
import '../../data/models/models.dart';
import '../questionnaire/questionnaire_screen.dart';

// Экран профиля пользователя с отображением анкетных данных
class ProfileScreen extends StatelessWidget {
  final RecoveryData recoveryData;
  final Function(RecoveryData)? onProfileUpdated;

  const ProfileScreen({
    required this.recoveryData,
    this.onProfileUpdated,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Профиль'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => _navigateToQuestionnaire(context),
          ),
        ],
      ),
      body: _buildProfileInfo(),
    );
  }

  void _navigateToQuestionnaire(BuildContext context) async {
    final updatedData = await Navigator.push<RecoveryData>(
      context,
      MaterialPageRoute(
        builder: (context) => QuestionnaireScreen(initialData: recoveryData),
      ),
    );

    if (updatedData != null && onProfileUpdated != null) {
      onProfileUpdated!(updatedData);
    }
  }

  Widget _buildProfileInfo() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoRow('ФИО', recoveryData.name),
          _buildInfoRow('Пол', recoveryData.gender),
          _buildInfoRow('Вес', '${recoveryData.weight} кг'),
          _buildInfoRow('Рост', '${recoveryData.height} см'),
          _buildInfoRow('Тип травмы', recoveryData.mainInjuryType),
          _buildInfoRow('Конкретная травма', recoveryData.specificInjury),
          _buildInfoRow('Уровень боли', '${recoveryData.painLevel}/10'),
          _buildInfoRow('Время на тренировки', recoveryData.trainingTime),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Text('$title: ', style: const TextStyle(fontWeight: FontWeight.bold)),
          Text(value),
        ],
      ),
    );
  }
}
