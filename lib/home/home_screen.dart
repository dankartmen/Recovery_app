import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../data/models/models.dart';
import '../exercises/screens/exercises_list_screen.dart';
import '../features/profile/profile_screen.dart';
import '../history/screens/history_screen.dart';
import 'bloc/home_bloc.dart';


/// {@template home_screen}
/// Главный экран с навигацией между разделами.
/// Обеспечивает переключение между профилем, упражнениями и историей.
/// {@endtemplate}
class HomeScreen extends StatefulWidget {
  final RecoveryData recoveryData;

  const HomeScreen({required this.recoveryData, super.key});

  @override
  HomeScreenState createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  late RecoveryData _currentRecoveryData;
  final List<Widget> _screens = [];

  @override
  void initState() {
    super.initState();
    _currentRecoveryData = widget.recoveryData;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<HomeBloc>().add(InitializeHome(recoveryData: _currentRecoveryData));
    });
    _initializeScreens();
  }

  void _initializeScreens() {
    _screens.addAll([
      ProfileScreen(recoveryData: _currentRecoveryData),
      ExercisesListScreen(recoveryData: _currentRecoveryData),
      HistoryScreen(recoveryData: _currentRecoveryData, schedule: null), // Schedule из HomeBloc state
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HomeBloc, HomeState>(
      builder: (context, state) {
        if (state is HomeLoading) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        } else if (state is HomeError) {
          return Scaffold(body: Center(child: Text(state.message)));
        } else if (state is HomeLoaded) {
          // Проверяем, есть ли расписание
          final loadedState = state;
          final hasSchedule = loadedState.schedule.id != 0;

          // Обновляем HistoryScreen с расписанием или без него
          _screens[2] = HistoryScreen(
            recoveryData: _currentRecoveryData, 
            schedule: hasSchedule ? loadedState.schedule : null,
          );
          
          return Scaffold(
            body: _screens[_selectedIndex],
            bottomNavigationBar: BottomNavigationBar(
              currentIndex: _selectedIndex,
              selectedItemColor: Colors.blue,
              unselectedItemColor: Colors.grey,
              selectedLabelStyle: const TextStyle(
                fontWeight: FontWeight.bold, // более жирный шрифт на выбранной метке
              ),
              unselectedLabelStyle: const TextStyle(
                color: Colors.grey, // серый шрифт на не выбранной метке
              ),
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
              ],
            ),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }
}