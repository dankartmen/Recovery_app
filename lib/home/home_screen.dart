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

  @override
  void initState() {
    super.initState();
    _currentRecoveryData = widget.recoveryData;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<HomeBloc>().add(InitializeHome(recoveryData: _currentRecoveryData));
    });
  }

 @override
  void dispose() {
    super.dispose();
  }

  /// Обновление расписания и данных
  Future<void> _refreshData() async {
    context.read<HomeBloc>().add(RefreshData());
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<HomeBloc, HomeState>(
      listener: (context, state) {
        if (state is HomeError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message)),
          );
        }
      },
      builder: (context, state) {
        if (state is HomeLoading) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        } else if (state is HomeError) {
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    state.message,
                    style: const TextStyle(color: Colors.red, fontSize: 16),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _refreshData,
                    child: const Text('Повторить'),
                  ),
                ],
              ),
            ),
          );
        } else if (state is HomeLoaded) {
          // Получаем актуальные данные из состояния
          final currentState = state;
          final hasSchedule = currentState.schedule.id != 0;

          // Определяем экраны для навигации
          final List<Widget> screens = [
            ProfileScreen(recoveryData: currentState.recoveryData),
            ExercisesListScreen(recoveryData: currentState.recoveryData),
            HistoryScreen(
              recoveryData: currentState.recoveryData, 
              schedule: hasSchedule ? currentState.schedule : null,
            ),
          ];

          return Scaffold(
            body: IndexedStack(
              index: _selectedIndex,
              children: screens,
            ),
            bottomNavigationBar: BottomNavigationBar(
              currentIndex: _selectedIndex,
              selectedItemColor: Colors.blue,
              unselectedItemColor: Colors.grey,
              selectedLabelStyle: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
              unselectedLabelStyle: const TextStyle(
                color: Colors.grey,
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
        
        // Начальное состояние
        return const Scaffold(
          body: Center(
            child: CircularProgressIndicator(),
          ),
        );
      },
    );
  }
}