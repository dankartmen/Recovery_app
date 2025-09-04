import 'package:auth_test/data/models/exercise_list_model.dart';
import 'package:auth_test/data/repositories/history_repository.dart';
import 'package:auth_test/features/login/login_screen.dart';
import 'package:auth_test/services/auth_service.dart';
import 'package:auth_test/services/exercise_service.dart';
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
  await _initializeApp();

  // Создание и инициализация сервисов и моделей
  final authService = AuthService();
  await authService.initialize(); // Асинхронная авторизация пользователя

  final historyModel = HistoryModel(HistoryRepository(authService));
  final trainingCalendarModel = TrainingCalendarModel();
  final questionnaireRepository = QuestionnaireRepository();
  final homeScreenModel = HomeScreenModel();
  final exerciseService = ExerciseService(authService: authService);

  // Запуск приложения с MultiProvider для управления состоянием
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthService>.value(value: authService),
        ChangeNotifierProvider<HistoryModel>.value(value: historyModel),
        ChangeNotifierProvider<TrainingCalendarModel>.value(
          value: trainingCalendarModel,
        ),
        Provider<QuestionnaireRepository>.value(value: questionnaireRepository),
        ChangeNotifierProvider.value(value: homeScreenModel),
        ChangeNotifierProvider<ExerciseListModel>(
          create: (_) => ExerciseListModel(exerciseService: exerciseService),
        ),
      ],
      child: MyApp(),
    ),
  );
}

// Инициализация Hive и сервисов
Future<void> _initializeApp() async {
  await Hive.initFlutter();

  // Регистрация адаптеров для хранения моделей в Hive
  Hive.registerAdapter(TrainingScheduleAdapter());
  Hive.registerAdapter(TrainingAdapter());
  Hive.registerAdapter(ExerciseAdapter());
  Hive.registerAdapter(TimeOfDayAdapter());
  await Hive.openBox<TrainingSchedule>('training_schedule');

  await SoundService.init(); // Инициализация звукового сервиса
}

// Корневой виджет приложения
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Получение экземпляров моделей из Provider
    final authService = Provider.of<AuthService>(context, listen: false);
    final historyModel = Provider.of<HistoryModel>(context, listen: false);
    final trainingCalendarModel = Provider.of<TrainingCalendarModel>(
      context,
      listen: false,
    );
    final exerciseListModel = Provider.of<ExerciseListModel>(
      context,
      listen: false,
    );

    // Инициализация TrainingCalendarModel с зависимостями
    trainingCalendarModel.initialize(
      authService,
      historyModel,
      exerciseListModel,
    );

    // Определение стартового экрана в зависимости от состояния авторизации
    Widget startScreen;
    if (authService.isLoading) {
      // Показываем индикатор загрузки, пока идет авторизация
      startScreen = Scaffold(body: Center(child: CircularProgressIndicator()));
    } else if (authService.currentUser != null) {
      // Если пользователь авторизован, сразу переходим на HomeScreen
      startScreen = FutureBuilder<RecoveryData?>(
        future: authService.fetchQuestionnaire(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Scaffold(body: Center(child: CircularProgressIndicator()));
          }
          return HomeScreen(recoveryData: snapshot.data!);
        },
      );
    } else {
      // Если не авторизован — экран входа
      startScreen = LoginScreen();
    }

    return MaterialApp(
      title: 'Recovery App',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: startScreen, // Динамический стартовый экран
      localizationsDelegates: [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: [
        const Locale('ru', 'RU'), // Русская локализация
      ],
      routes: {
        // Конфигурация маршрутов приложения
        '/auth': (context) => LoginScreen(),
        '/home':
            (context) => HomeScreen(
              recoveryData:
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
                Provider.of<HomeScreenModel>(
                  context,
                ).schedule, // Передача расписания
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
      // Обработка неизвестных маршрутов
      onUnknownRoute:
          (settings) => MaterialPageRoute(
            builder:
                (context) =>
                    Scaffold(body: Center(child: Text('Страница не найдена'))),
          ),
      // Генерация маршрутов для передачи аргументов
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
