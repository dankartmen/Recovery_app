import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../data/models/models.dart';
import '../../data/models/training_schedule.dart';
import '../../training/bloc/training_bloc.dart';


part 'home_event.dart';
part 'home_state.dart';

/// {@template home_bloc}
/// BLoC для главного экрана.
/// Управляет инициализацией, расписанием и данными восстановления.
/// {@endtemplate}
class HomeBloc extends Bloc<HomeEvent, HomeState> {
  final TrainingBloc trainingBloc; 

  HomeBloc({required this.trainingBloc}) : super(HomeInitial()) {
    on<InitializeHome>(_onInitializeHome);
  }

  Future<void> _onInitializeHome(InitializeHome event, Emitter<HomeState> emit) async {
    emit(HomeLoading());
    try {
      // Инициализация: загрузка schedule из TrainingBloc
      trainingBloc.add(LoadTrainingSchedule(userId: 0)); // Замените на реальный userId
      final schedule = await trainingBloc.stream.firstWhere((state) => state is TrainingLoaded).then((state) => (state as TrainingLoaded).schedule);
      emit(HomeLoaded(schedule: schedule, recoveryData: event.recoveryData));
    } catch (e) {
      emit(HomeError(message: 'Ошибка инициализации: $e'));
    }
  }
}