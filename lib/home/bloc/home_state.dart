part of 'home_bloc.dart';

abstract class HomeState extends Equatable {
  const HomeState();

  @override
  List<Object?> get props => [];
}

/// {@template home_initial}
/// Начальное состояние главного экрана.
/// {@endtemplate}
class HomeInitial extends HomeState {}

/// {@template home_loading}
/// Состояние загрузки главного экрана.
/// {@endtemplate}
class HomeLoading extends HomeState {}

/// {@template home_loaded}
/// Состояние загруженного главного экрана.
/// {@endtemplate}
class HomeLoaded extends HomeState {
  final TrainingSchedule schedule;
  final RecoveryData recoveryData;

  const HomeLoaded({required this.schedule, required this.recoveryData});

  HomeLoaded copyWith({
    TrainingSchedule? schedule,
    RecoveryData? recoveryData,
  }) {
    return HomeLoaded(
      schedule: schedule ?? this.schedule,
      recoveryData: recoveryData ?? this.recoveryData,
    );
  }

  @override
  List<Object?> get props => [schedule, recoveryData];
}

/// {@template home_error}
/// Состояние ошибки главного экрана.
/// {@endtemplate}
class HomeError extends HomeState {
  final String message;

  const HomeError({required this.message});

  @override
  List<Object?> get props => [message];
}