
import 'package:auth_test/home/bloc/home_bloc.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'auth/bloc/auth_bloc.dart';
import 'auth/bloc/registration_bloc.dart';
import 'data/repositories/history_repository.dart';
import 'auth/screens/login_screen.dart';
import 'exercises/bloc/exercise_list_bloc.dart';
import 'exercises/models/exercise.dart';
import 'history/bloc/history_bloc.dart';
import 'questionnaire/bloc/questionnaire_bloc.dart';
import 'core/services/auth_service.dart';
import 'core/services/exercise_service.dart';
import 'core/styles/style.dart';
import 'package:flutter/material.dart';
import 'features/sounds/sound_service.dart';
import 'package:provider/provider.dart';


import 'data/models/sound.dart';

import 'data/repositories/questionnaire_repository.dart';
import 'history/screens/history_screen.dart';
import 'features/profile/profile_screen.dart';
import 'questionnaire/screens/questionnaire_screen.dart';
import 'home/home_screen.dart';
import 'exercises/screens/exercise_detail_screen.dart';
import 'data/models/models.dart';
import 'features/sounds/sound_selection_dialog.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/services/questionnaire_service.dart';
import 'core/services/training_service.dart';
import 'training/bloc/training_bloc.dart';
import 'training/models/training_schedule.dart';

/* bulat bulат1000T$ */
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await _initializeApp();

  // Создание и инициализация сервисов и моделей
  final authService = AuthService();
  await authService.initialize(); // Асинхронная авторизация пользователя

  final historyRepository = HistoryRepository(authService);
  final questionnaireRepository = QuestionnaireRepository();
  final questionnaireService = QuestionnaireService(); // Создан экземпляр
  final trainingService = TrainingService(authService); // Создан экземпляр
  final exerciseService = ExerciseService(authService: authService); // Создан экземпляр

  // Запуск приложения с MultiProvider для управления состоянием
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthService>.value(value: authService),
        
        // Репозитории
        Provider<HistoryRepository>.value(value: historyRepository),
        Provider<QuestionnaireRepository>.value(value: questionnaireRepository),
        
        // Сервисы
        Provider<QuestionnaireService>.value(value: questionnaireService), // Добавлено
        Provider<TrainingService>.value(value: trainingService), // Добавлено
        Provider<ExerciseService>.value(value: exerciseService), // Добавлено
        
        // BLoCs
        BlocProvider<AuthBloc>(
          create: (context) => AuthBloc(authService: Provider.of<AuthService>(context, listen: false)),
        ),
        BlocProvider<RegistrationBloc>(
          create: (context) => RegistrationBloc(
            authService: Provider.of<AuthService>(context, listen: false),
          ),
        ),
        BlocProvider<HistoryBloc>(
          create: (context) => HistoryBloc(
            repository: Provider.of<HistoryRepository>(context, listen: false),
          ),
        ),
        BlocProvider<TrainingBloc>(
          create: (context) => TrainingBloc(
            historyRepository: Provider.of<HistoryRepository>(context, listen: false),
            trainingService: Provider.of<TrainingService>(context, listen: false), // Исправлено
          ),
        ),
        BlocProvider<ExerciseListBloc>(
          create: (context) => ExerciseListBloc(
            exerciseService: Provider.of<ExerciseService>(context, listen: false),
          ),
        ),
        BlocProvider<QuestionnaireBloc>(
          create: (context) => QuestionnaireBloc(
            authService: Provider.of<AuthService>(context, listen: false),
            repository: Provider.of<QuestionnaireRepository>(context, listen: false),
          ),
        ),
        BlocProvider<HomeBloc>(
          create: (context) => HomeBloc(
            trainingBloc: BlocProvider.of<TrainingBloc>(context),
            authService: Provider.of<AuthService>(context, listen: false),
          ),
        ),
      ],
      child: MyApp(),
    ),
  );
}

// Инициализация Hive и сервисов
Future<void> _initializeApp() async {
  await SoundService.init(); // Инициализация звукового сервиса
}

// Корневой виджет приложения
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Получение экземпляров моделей из Provider
    final authService = Provider.of<AuthService>(context, listen: false);
    // Определение стартового экрана в зависимости от состояния авторизации
    Widget startScreen;
    if (authService.isLoading) {
      // Показываем индикатор загрузки, пока идет авторизация
      startScreen = Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: healthPrimaryColor),
        ),
      );
    } else if (authService.currentUser != null) {
      // Если пользователь авторизован, сразу переходим на HomeScreen
      startScreen = FutureBuilder<RecoveryData?>(
        future: authService.fetchQuestionnaire(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Scaffold(body: Center(child: CircularProgressIndicator()));
          }
          // Если есть ошибка или данные пустые - показываем анкету
          if (snapshot.hasError || snapshot.data == null) {
            debugPrint('Ошибка загрузки анкеты: ${snapshot.error}');
            debugPrint('Данные анкеты: ${snapshot.data}');
            return QuestionnaireScreen();
          }
          
          // Если анкета успешно загружена - показываем главный экран
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
        '/home': (context) {
          final args = ModalRoute.of(context)!.settings.arguments;
          if (args == null) {
            return QuestionnaireScreen();
          }
          return HomeScreen(recoveryData: args as RecoveryData);
        },
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
          
          // Получаем schedule из HomeBloc, если он загружен
          final homeBloc = BlocProvider.of<HomeBloc>(context);
          TrainingSchedule? schedule;
          
          if (homeBloc.state is HomeLoaded) {
            schedule = (homeBloc.state as HomeLoaded).schedule;
          }
          
          return HistoryScreen(
            recoveryData: args,
            schedule: schedule,
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
