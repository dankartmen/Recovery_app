import 'package:auth_test/data/repositories/history_repository.dart';
import 'package:auth_test/features/login/login_screen.dart';
import 'package:auth_test/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:auth_test/features/sounds/sound_service.dart';
import 'package:auth_test/features/training_calendar/training_calendar_screen.dart';
import 'package:provider/provider.dart';
import 'adapters/exercise_adapter.dart';
import 'adapters/time_of_day_adapter.dart';
import 'adapters/training_adapter.dart';
import 'adapters/training_schedule_adapter.dart';
import 'data/models/history_model.dart';
import 'data/models/home_screen_model.dart';
import 'data/models/sound.dart';
import 'data/models/training_calendar_model.dart';
import 'data/models/training_schedule.dart';
import 'data/repositories/questionnaire_repository.dart';
import 'features/history/history_screen.dart';
import 'features/profile/profile_screen.dart';
import 'features/questionnaire/questionnaire_screen.dart';
import 'features/home/home_screen.dart';
import 'features/exercises/exercise_detail_screen.dart';
import 'data/models/models.dart';
import 'features/sounds/sound_selection_dialog.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:hive_flutter/hive_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(
    FutureBuilder(
      future: _initializeApp(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          return MultiProvider(
            providers: [
              ChangeNotifierProvider(create: (_) => AuthService()),
              ChangeNotifierProvider(create: (_) => HomeScreenModel()),
              Provider(create: (_) => QuestionnaireRepository()),
              ProxyProvider<AuthService, HistoryRepository>(
                update: (_, authService, __) => HistoryRepository(authService),
              ),
              ChangeNotifierProvider(
                create: (context) {
                  debugPrint("Создание HistoryModel...");
                  final repo = Provider.of<HistoryRepository>(
                    context,
                    listen: false,
                  );
                  final model = HistoryModel(repo);
                  model.loadHistory();
                  return model;
                },
              ),
              ProxyProvider2<
                AuthService,
                HistoryRepository,
                TrainingCalendarModel
              >(
                update:
                    (_, authService, historyRepo, __) =>
                        TrainingCalendarModel(authService, historyRepo),
              ),
            ],
            child: MyApp(),
          );
        }
        return MaterialApp(
          home: Scaffold(body: Center(child: CircularProgressIndicator())),
        ); // nenen94D
      },
    ),
  );
}

Future<void> _initializeApp() async {
  // Инициализация Hive
  await Hive.initFlutter();

  // Регистрация адаптеров
  Hive.registerAdapter(TrainingScheduleAdapter());
  Hive.registerAdapter(TrainingAdapter());
  Hive.registerAdapter(ExerciseAdapter());
  Hive.registerAdapter(TimeOfDayAdapter());

  await Hive.openBox<TrainingSchedule>('training_schedule');

  // Инициализация репозиториев и загрузка данных
  final authService = AuthService();
  await authService.initialize();
  await SoundService.init(); // Инициализация звукового сервиса
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
      initialRoute: '/auth',
      localizationsDelegates: [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: [
        const Locale('ru', 'RU'), // Русская локальлизация
      ],
      routes: {
        // Конфигурация маршрутов приложения
        '/auth': (context) => LoginScreen(),
        '/home':
            (context) => HomeScreen(
              recoveryData:
                  recoveryData ??
                  ModalRoute.of(context)!.settings.arguments as RecoveryData,
            ),
        '/questionnaire':
            (context) => QuestionnaireScreen(
              initialData:
                  ModalRoute.of(context)?.settings.arguments as RecoveryData?,
            ),
        '/exercise_detail': (context) {
          final exercise =
              ModalRoute.of(context)!.settings.arguments as Exercise;
          return ExerciseDetailScreen(exercise: exercise);
        },
        '/history': (context) {
          final args =
              ModalRoute.of(context)!.settings.arguments as RecoveryData;
          return HistoryScreen(
            recoveryData: args,
            schedule:
                Provider.of<HomeScreenModel>(context).schedule, // Добавлено
          );
        },
        '/profile':
            (context) => ProfileScreen(
              recoveryData:
                  ModalRoute.of(context)!.settings.arguments as RecoveryData,
            ),
        '/sound_selection': (context) {
          final sound = ModalRoute.of(context)!.settings.arguments as Sound?;
          return SoundSelectionDialog(currentSound: sound);
        },
        '/exercise': (context) {
          final exercise =
              ModalRoute.of(context)!.settings.arguments as Exercise;
          return ExerciseDetailScreen(exercise: exercise);
        },
        '/calendar': (context) {
          final args =
              ModalRoute.of(context)!.settings.arguments as RecoveryData;
          return TrainingCalendarScreen(recoveryData: args);
        },
      },
      onUnknownRoute:
          (settings) => MaterialPageRoute(
            builder:
                (context) =>
                    Scaffold(body: Center(child: Text('Страница не найдена'))),
          ),
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case '/home':
            return MaterialPageRoute(
              builder:
                  (context) => HomeScreen(
                    recoveryData: settings.arguments as RecoveryData,
                  ),
            );
        }
        return null;
      },
    );
  }
}
