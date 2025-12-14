import 'dart:async';
import 'dart:developer';

import 'package:auth_test/core/services/auth_service.dart';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../data/models/models.dart';
import '../../training/models/training_schedule.dart';
import '../../training/bloc/training_bloc.dart';


part 'home_event.dart';
part 'home_state.dart';

/// {@template home_bloc}
/// BLoC для главного экрана.
/// Управляет инициализацией, расписанием и данными восстановления.
/// {@endtemplate}
class HomeBloc extends Bloc<HomeEvent, HomeState> {
  final AuthService authService;
  final TrainingBloc trainingBloc;  
  StreamSubscription? _trainingBlocSubscription;

  HomeBloc({
    required this.trainingBloc,
    required this.authService,
  }) : super(HomeInitial()) {
    on<InitializeHome>(_onInitializeHome);
    on<UpdateSchedule>(_onUpdateSchedule);
    on<RefreshData>(_onRefreshData);

    // Подписываемся на изменения в TrainingBloc
    _trainingBlocSubscription = trainingBloc.stream.listen((state) {
      if (state is TrainingLoaded) {
        add(UpdateSchedule(schedule: state.schedule));
      }
    });
  }

  Future<void> _onInitializeHome(InitializeHome event, Emitter<HomeState> emit) async {
    emit(HomeLoading());
    try {
      final userId = authService.currentUser?.id;
      if (userId == null || userId == 0) {
        // Если пользователь не найден, используем пустое расписание
        emit(HomeLoaded(
          schedule: TrainingSchedule.empty(), 
          recoveryData: event.recoveryData
        ));
        return;
      }

      // Инициализация: загрузка schedule из TrainingBloc
      trainingBloc.add(LoadCurrentSchedule());
      
      // Ждем загрузки расписания или используем текущее состояние
      final currentState = trainingBloc.state;
      if (currentState is TrainingLoaded) {
        emit(HomeLoaded(
          schedule: currentState.schedule,
          recoveryData: event.recoveryData,
        ));
      } else if (currentState is TrainingError) {
        // При ошибке используем пустое расписание
        emit(HomeLoaded(
          schedule: TrainingSchedule.empty(),
          recoveryData: event.recoveryData,
        ));
      } else {
        // Если еще не загружено, продолжаем с пустым расписанием
        // TrainingBloc уведомит нас позже через UpdateSchedule
        emit(HomeLoaded(
          schedule: TrainingSchedule.empty(),
          recoveryData: event.recoveryData,
        ));
      }
    } catch (e) {
      log('Ошибка инициализации HomeBloc: $e');
      // При любой ошибке используем пустое расписание
      emit(HomeLoaded(
        schedule: TrainingSchedule.empty(),
        recoveryData: event.recoveryData,
      ));
    }
  }

  void _onUpdateSchedule(UpdateSchedule event, Emitter<HomeState> emit) {
    if (state is HomeLoaded) {
      final currentState = state as HomeLoaded;
      emit(currentState.copyWith(schedule: event.schedule));
    } else if (state is HomeInitial || state is HomeLoading) {
      // Если Home еще не инициализирован, создаем новое состояние
      emit(HomeLoaded(
        schedule: event.schedule,
        recoveryData: RecoveryData.empty(),
      ));
    }
  }

  Future<void> _onRefreshData(RefreshData event, Emitter<HomeState> emit) async {
    if (state is HomeLoaded) {
      final currentState = state as HomeLoaded;
      emit(HomeLoading());
      
      try {
        // Перезагружаем расписание
        trainingBloc.add(LoadCurrentSchedule());
        
        // Сохраняем текущие данные
        emit(HomeLoaded(
          schedule: currentState.schedule,
          recoveryData: currentState.recoveryData,
        ));
      } catch (e) {
        log('Ошибка обновления данных: $e');
        emit(currentState);
      }
    }
  }

  /// Метод для получения текущего расписания
  TrainingSchedule? get currentSchedule {
    if (state is HomeLoaded) {
      return (state as HomeLoaded).schedule;
    }
    return null;
  }

  /// Метод для получения данных восстановления
  RecoveryData? get recoveryData {
    if (state is HomeLoaded) {
      return (state as HomeLoaded).recoveryData;
    }
    return null;
  }

  @override
  Future<void> close() {
    _trainingBlocSubscription?.cancel();
    return super.close();
  }
}


