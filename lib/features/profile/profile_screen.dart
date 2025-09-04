import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/models/models.dart';
import '../../services/auth_service.dart';
import '../../styles/style.dart';
import '../questionnaire/questionnaire_screen.dart';

class ProfileScreen extends StatelessWidget {
  final RecoveryData recoveryData;
  final Function(RecoveryData)? onProfileUpdated;

  const ProfileScreen({
    required this.recoveryData,
    this.onProfileUpdated,
    super.key,
  });

  void _logout(BuildContext context) {
    final authService = Provider.of<AuthService>(context, listen: false);

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text(
              'Выход из аккаунта',
              style: TextStyle(color: healthTextColor),
            ),
            content: const Text(
              'Вы уверены, что хотите выйти?',
              style: TextStyle(color: healthSecondaryTextColor),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'Отмена',
                  style: TextStyle(color: healthSecondaryColor),
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  authService.logout();
                  Navigator.pushNamedAndRemoveUntil(
                    context,
                    '/auth',
                    (route) => false,
                  );
                },
                child: const Text('Выйти', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Профиль',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: healthPrimaryColor,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            onPressed: () => _logout(context),
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: Container(
        color: healthBackgroundColor,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // Аватар и приветствие
              _buildProfileHeader(),
              const SizedBox(height: 24),

              // Cекция с персональными данными
              _buildProfileSection(
                icon: Icons.person_outline,
                iconColor: healthPrimaryColor,
                title: 'Персональные данные',
                children: [
                  _buildInfoRow('Полное имя', recoveryData.name),
                  _buildInfoRow('Пол', recoveryData.gender),
                  _buildInfoRow('Рост', '${recoveryData.height} см'),
                  _buildInfoRow('Вес', '${recoveryData.weight} кг'),
                ],
              ),
              const SizedBox(height: 20),

              // Секция с медицинской информацией
              _buildProfileSection(
                icon: Icons.healing,
                iconColor: healthSecondaryColor,
                title: 'Медицинская информация',
                children: [
                  _buildInfoRow('Тип травмы', recoveryData.mainInjuryType),
                  _buildInfoRow(
                    'Конкретная травма',
                    recoveryData.specificInjury,
                  ),
                  _buildInfoRow(
                    'Уровень дискомфорта',
                    '${recoveryData.painLevel}/10',
                  ),
                ],
              ),
              const SizedBox(height: 30),

              // Кнопка редактирования профиля
              _buildEditButton(context),
            ],
          ),
        ),
      ),
    );
  }

  // Шапка профиля
  Widget _buildProfileHeader() {
    return Column(
      children: [
        CircleAvatar(
          radius: 50,
          backgroundColor: healthPrimaryColor.withValues(alpha: 0.2),
          child: Icon(Icons.person, size: 50, color: healthPrimaryColor),
        ),
        const SizedBox(height: 16),
        Text(
          recoveryData.name,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: healthTextColor,
          ),
        ),
      ],
    );
  }

  // Создает карточку-секцию
  Widget _buildProfileSection({
    required IconData icon,
    required Color iconColor,
    required String title,
    required List<Widget> children,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: iconColor, size: 28),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: healthTextColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  // Строит строку с меткой и значением
  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(fontSize: 16, color: healthSecondaryTextColor),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: healthTextColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Кнопка редактирования профиля
  Widget _buildEditButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () => _navigateToQuestionnaire(context),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          backgroundColor: healthPrimaryColor,
          foregroundColor: Colors.white,
        ),
        child: const Text(
          'Редактировать профиль',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  // Навигация на экран редактирования анкеты
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
}
