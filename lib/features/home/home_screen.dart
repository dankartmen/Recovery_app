import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:provider/provider.dart';
import '../../data/models/history_model.dart';
import '../../data/models/home_screen_model.dart';
import '../../data/models/models.dart';
import '../../data/models/training_schedule.dart';
import '../../data/repositories/questionnaire_repository.dart';
import '../history/history_screen.dart';
import '../profile/profile_screen.dart';
import '../exercises/exercises_screen.dart';
import '../training_calendar/training_calendar_screen.dart';

// Главный экран с навигацией между разделами
class HomeScreen extends StatefulWidget {
  final RecoveryData recoveryData;

  const HomeScreen({required this.recoveryData, Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  late RecoveryData _currentRecoveryData;
  late List<Widget> _screens = [];
  final QuestionnaireRepository _repository = QuestionnaireRepository();
  late HomeScreenModel _homeModel;
  bool _isAppInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeApp();
    _loadLatestData();
    _loadTrainingSchedule(); // Загружаем расписание
  }

  Future<void> _initializeApp() async {
    await _loadTrainingSchedule();
    await _loadLatestData();
    _homeModel = Provider.of<HomeScreenModel>(context, listen: false);
    _currentRecoveryData = widget.recoveryData;
    _initializeScreens();
    // Загрузка истории сразу при открытии приложения
    final historyModel = Provider.of<HistoryModel>(context, listen: false);
    await historyModel.loadHistory();

    setState(() => _isAppInitialized = true);
  }

  Future<void> _loadTrainingSchedule() async {
    try {
      final box = await Hive.openBox<TrainingSchedule>('training_schedule');
      final schedule = box.get('schedule');
      if (schedule != null) {
        _homeModel.updateSchedule(schedule); // ОБНОВЛЯЕМ МОДЕЛЬ
      }
    } catch (e) {
      debugPrint('Ошибка загрузки расписания: $e');
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
  }

  void _initializeScreens() {
    _screens.addAll([
      ProfileScreen(
        recoveryData: _currentRecoveryData,
        onProfileUpdated: _updateProfileData,
      ),
      ExercisesScreen(recoveryData: _currentRecoveryData),
      // ИСПОЛЬЗУЕМ Consumer ДЛЯ ПОЛУЧЕНИЯ АКТУАЛЬНОГО РАСПИСАНИЯ
      Consumer<HomeScreenModel>(
        builder: (context, model, child) {
          return HistoryScreen(
            recoveryData: _currentRecoveryData,
            schedule: model.schedule,
          );
        },
      ),
      TrainingCalendarScreen(recoveryData: _currentRecoveryData),
    ]);
  }

  Future<void> _loadLatestData() async {
    final data = await _repository.getLatestQuestionnaire();
    if (data != null) {
      setState(() {
        _currentRecoveryData = data;
        _screens[0] = ProfileScreen(
          recoveryData: _currentRecoveryData,
          onProfileUpdated: _updateProfileData,
        );
      });
    }
  }

  void _updateProfileData(RecoveryData newData) async {
    await _repository.saveQuestionnaire(newData);
    setState(() {
      _currentRecoveryData = newData;
      // Пересоздаем экраны с новыми данными
      _initializeScreens();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_isAppInitialized) {
      return Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return Scaffold(
      body: IndexedStack(index: _selectedIndex, children: _screens),
      bottomNavigationBar: BottomNavigationBar(
        // Переключение между экранами
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        selectedLabelStyle: TextStyle(
          fontWeight: FontWeight.bold,
        ), // более жирный шрифт на выбранной метке
        unselectedLabelStyle: TextStyle(
          color: Colors.grey,
        ), // серый шрифт на не выбранной метке
        type: BottomNavigationBarType.fixed,
        onTap: (index) => setState(() => _selectedIndex = index),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person, color: Colors.blue),
            label: 'Профиль',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.fitness_center),
            activeIcon: Icon(Icons.fitness_center, color: Colors.blue),
            label: 'Упражнения',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history),
            activeIcon: Icon(Icons.history, color: Colors.blue),
            label: 'История',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today),
            activeIcon: Icon(Icons.calendar_today, color: Colors.blue),
            label: 'Календарь',
          ),
        ],
      ),
    );
  }
}
