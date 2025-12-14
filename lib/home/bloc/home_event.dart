part of 'home_bloc.dart';

abstract class HomeEvent extends Equatable {
  const HomeEvent();

  @override
  List<Object?> get props => [];
}

/// {@template initialize_home}
/// Событие инициализации главного экрана.
/// {@endtemplate}
class InitializeHome extends HomeEvent {
  final RecoveryData recoveryData;

  const InitializeHome({required this.recoveryData});

  @override
  List<Object?> get props => [recoveryData];
}

/// Обновление расписания
class UpdateSchedule extends HomeEvent {
  final TrainingSchedule schedule;

  const UpdateSchedule({required this.schedule});

  @override
  List<Object> get props => [schedule];
}

/// Обновление данных
class RefreshData extends HomeEvent {
  const RefreshData();
}