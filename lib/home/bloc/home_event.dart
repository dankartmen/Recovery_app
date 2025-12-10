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