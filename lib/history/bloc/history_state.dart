part of 'history_bloc.dart';

abstract class HistoryState extends Equatable {
  const HistoryState();

  @override
  List<Object?> get props => [];
}

/// {@template history_initial}
/// Начальное состояние истории.
/// {@endtemplate}
class HistoryInitial extends HistoryState {}

/// {@template history_loading}
/// Состояние загрузки истории.
/// {@endtemplate}
class HistoryLoading extends HistoryState {}

/// {@template history_loaded}
/// Состояние загруженной истории.
/// {@endtemplate}
class HistoryLoaded extends HistoryState {
  final List<ExerciseHistory> history;
  final String selectedInjuryType;
  final String selectedTimePeriod;
  final DateTime? selectedDay;

  const HistoryLoaded({
    required this.history,
    this.selectedInjuryType = 'Все',
    this.selectedTimePeriod = 'За всё время',
    this.selectedDay,
  });

  HistoryLoaded copyWith({
    List<ExerciseHistory>? history,
    String? selectedInjuryType,
    String? selectedTimePeriod,
    DateTime? selectedDay,
  }) {
    return HistoryLoaded(
      history: history ?? this.history,
      selectedInjuryType: selectedInjuryType ?? this.selectedInjuryType,
      selectedTimePeriod: selectedTimePeriod ?? this.selectedTimePeriod,
      selectedDay: selectedDay ?? this.selectedDay,
    );
  }

  @override
  List<Object?> get props => [history, selectedInjuryType, selectedTimePeriod, selectedDay];
}

/// {@template history_error}
/// Состояние ошибки загрузки истории.
/// {@endtemplate}
class HistoryError extends HistoryState {
  final String message;

  const HistoryError({required this.message});

  @override
  List<Object?> get props => [message];
}