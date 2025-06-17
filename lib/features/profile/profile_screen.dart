import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/models/models.dart';
import '../../services/auth_service.dart';
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

  void _logout(BuildContext context) {
    final authService = Provider.of<AuthService>(context, listen: false);

    // Показываем диалог подтверждения
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Выход из аккаунта'),
            content: const Text('Вы уверены, что хотите выйти?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Отмена'),
              ),
              TextButton(
                onPressed: () {
                  // Закрываем диалог
                  Navigator.pop(context);

                  // Выполняем выход
                  authService.logout();

                  // Переходим на экран авторизации, очищая стек
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
        title: const Text('Профиль'),
        centerTitle: true, // Центрирование заголовка
        actions: [
          IconButton(
            onPressed: () => _logout(context),
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Cекция с персональными данными
            _buildProfileSection(
              icon: Icons.person_outline,
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
              title: 'Медицинская информация',
              children: [
                _buildInfoRow('Тип травмы', recoveryData.mainInjuryType),
                _buildInfoRow('Конкретная травма', recoveryData.specificInjury),
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
    );
  }

  // Создает карточку-секцию с иконкой и заголовком
  Widget _buildProfileSection({
    required IconData icon,
    required String title,
    required List<Widget> children,
  }) {
    return Card(
      elevation: 2, // Тень
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Colors.blue, size: 24),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            ...children,
          ],
        ),
      ),
    );
  }

  // Строит строку с меткой и значением
  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 16, color: Colors.grey[600])),
          Text(
            value,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  // Кнопка редактирования профиля
  Widget _buildEditButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        icon: const Icon(Icons.edit, size: 20),
        label: const Text(
          'Редактировать профиль',
          style: TextStyle(fontSize: 16),
        ),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12), // Скругление кнопки
          ),
          backgroundColor: Colors.blue, // Основной цвет кнопки
          foregroundColor: Colors.white, // Цвет текста и иконки
        ),
        onPressed: () => _navigateToQuestionnaire(context),
      ),
    );
  }

  // Навигация на экран редактирования анкеты
  void _navigateToQuestionnaire(BuildContext context) async {
    final updatedData = await Navigator.pushAndRemoveUntil<RecoveryData>(
      context,
      MaterialPageRoute(
        builder: (context) => QuestionnaireScreen(initialData: recoveryData),
      ),
      (Route<dynamic> route) => false, // Удаляем все предыдущие экраны
    );

    if (updatedData != null && onProfileUpdated != null) {
      onProfileUpdated!(updatedData); // Обновление данных профиля
    }
  }
}
