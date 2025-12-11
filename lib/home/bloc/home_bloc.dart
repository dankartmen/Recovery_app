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

  HomeBloc({
    required this.trainingBloc,
    required this.authService,
  }) : super(HomeInitial()) {
    on<InitializeHome>(_onInitializeHome);
  }

  Future<void> _onInitializeHome(InitializeHome event, Emitter<HomeState> emit) async {
    emit(HomeLoading());
    try {
      final userId = authService.currentUser?.id;
      if (userId == null || userId == 0) {
        // Если пользователь не найден, используем пустое расписание
        emit(HomeLoaded(schedule: TrainingSchedule.empty(), recoveryData: event.recoveryData));
        return;
      }

      // Инициализация: загрузка schedule из TrainingBloc
      trainingBloc.add(LoadTrainingSchedule(userId: userId)); // Используем реальный ID
      
      // Ждем либо загрузки, либо ошибки
      final state = await trainingBloc.stream.firstWhere(
        (state) => state is TrainingLoaded || state is TrainingError,
        orElse: () => TrainingLoaded(schedule: TrainingSchedule.empty()),
      );

      if (state is TrainingLoaded) {
        emit(HomeLoaded(schedule: state.schedule, recoveryData: event.recoveryData));
      } else if (state is TrainingError) {
        // При ошибке используем пустое расписание
        emit(HomeLoaded(schedule: TrainingSchedule.empty(), recoveryData: event.recoveryData));
      }
    } catch (e) {
      // При любой ошибке используем пустое расписание, но не падаем
      emit(HomeLoaded(schedule: TrainingSchedule.empty(), recoveryData: event.recoveryData));
    }
  }
}
