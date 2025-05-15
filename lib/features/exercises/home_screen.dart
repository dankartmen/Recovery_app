import 'package:flutter/material.dart';
import '../../data/models/models.dart';
import '../../data/repositories/questionnaire_repository.dart';
import '../history/history_screen.dart';
import '../profile/profile_screen.dart';
import '../questionnaire/questionnaire_screen.dart';
import 'exercises_screen.dart';

// Главный экран с навигацией между разделами
class HomeScreen extends StatefulWidget {
  final RecoveryData recoveryData;

  const HomeScreen({required this.recoveryData, Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  late RecoveryData _recoveryData;
  final List<Widget> _screens = [];
  final QuestionnaireRepository _repository = QuestionnaireRepository();

  @override
  void initState() {
    super.initState();
    _recoveryData = widget.recoveryData;
    _initializeScreens();
    _loadLatestData();
  }

  void _initializeScreens() {
    _screens.addAll([
      ProfileScreen(
        recoveryData: _recoveryData,
        onProfileUpdated: _updateProfileData,
      ),
      ExercisesScreen(recoveryData: _recoveryData),
      HistoryScreen(),
    ]);
  }

  Future<void> _loadLatestData() async {
    final data = await _repository.getLatestQuestionnaire();
    if (data != null) {
      setState(() {
        _recoveryData = data;
        _screens[0] = ProfileScreen(
          recoveryData: _recoveryData,
          onProfileUpdated: _updateProfileData,
        );
      });
    }
  }

  void _updateProfileData(RecoveryData newData) async {
    await _repository.saveQuestionnaire(newData);
    setState(() {
      _recoveryData = newData;
      _screens[0] = ProfileScreen(
        recoveryData: _recoveryData,
        onProfileUpdated: _updateProfileData,
      );
    });
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Future<void> _editProfile() async {
    final updatedData = await Navigator.push<RecoveryData>(
      context,
      MaterialPageRoute(
        builder: (context) => QuestionnaireScreen(initialData: _recoveryData),
        settings: RouteSettings(arguments: _recoveryData),
      ),
    );

    if (updatedData != null) {
      await _repository.saveQuestionnaire(updatedData);
      setState(() {
        _recoveryData = updatedData;
        _screens[0] = ProfileScreen(
          recoveryData: _recoveryData,
          onProfileUpdated: _updateProfileData,
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _selectedIndex, children: _screens),
      bottomNavigationBar: BottomNavigationBar(
        // Переключение между экранами
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Профиль'),
          BottomNavigationBarItem(
            icon: Icon(Icons.fitness_center),
            label: 'Упражнения',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: 'История'),
        ],
      ),
    );
  }
}
