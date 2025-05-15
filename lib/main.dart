import 'package:flutter/material.dart';
import 'package:recovery_app/features/sounds/sound_service.dart';
import 'data/models/sound.dart';
import 'data/repositories/questionnaire_repository.dart';
import 'features/history/history_screen.dart';
import 'features/profile/profile_screen.dart';
import 'features/questionnaire/questionnaire_screen.dart';
import 'features/home/home_screen.dart';
import 'features/exercises/exercise_detail_screen.dart';
import 'data/models/models.dart';
import 'features/sounds/sound_selection_dialog.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Загружаем сохраненные данные
  final questionnaireRepo = QuestionnaireRepository();
  final recoveryData = await questionnaireRepo.getLatestQuestionnaire();

  await SoundService.init(); // Инициализация звукового сервиса

  runApp(MyApp(recoveryData: recoveryData));
}

// Корневой виджет приложения
class MyApp extends StatelessWidget {
  final RecoveryData? recoveryData;

  const MyApp({this.recoveryData});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Recovery App',
      theme: ThemeData(primarySwatch: Colors.blue),
      initialRoute: recoveryData == null ? '/questionnaire' : '/home',
      routes: {
        // Конфигурация маршрутов приложения
        '/home':
            (context) => HomeScreen(
              recoveryData:
                  recoveryData ??
                  ModalRoute.of(context)!.settings.arguments as RecoveryData,
            ),
        '/questionnaire': (context) {
          final args =
              ModalRoute.of(context)!.settings.arguments as RecoveryData?;
          return QuestionnaireScreen(initialData: args);
        },
        '/exercise_detail': (context) {
          final exercise =
              ModalRoute.of(context)!.settings.arguments as Exercise;
          return ExerciseDetailScreen(exercise: exercise);
        },
        '/history': (context) => HistoryScreen(),
        '/profile': (context) {
          final args =
              ModalRoute.of(context)!.settings.arguments as RecoveryData;
          return ProfileScreen(recoveryData: args);
        },
        '/sound_selection': (context) {
          final sound = ModalRoute.of(context)!.settings.arguments as Sound?;
          return SoundSelectionDialog(currentSound: sound);
        },
        '/exercise': (context) {
          final exercise =
              ModalRoute.of(context)!.settings.arguments as Exercise;
          return ExerciseDetailScreen(exercise: exercise);
        },
      },
      onUnknownRoute:
          (settings) => MaterialPageRoute(
            builder:
                (context) =>
                    Scaffold(body: Center(child: Text('Страница не найдена'))),
          ),
    );
  }
}
