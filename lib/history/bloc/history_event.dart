part of 'history_bloc.dart';

abstract class HistoryEvent extends Equatable {
  const HistoryEvent();

  @override
  List<Object?> get props => [];
}

/// {@template load_history}
/// Событие загрузки истории.
/// {@endtemplate}
class LoadHistory extends HistoryEvent {}

/// {@template refresh_history}
/// Событие обновления истории.
/// {@endtemplate}
class RefreshHistory extends HistoryEvent {}

/// {@template add_history_item}
/// Событие добавления записи в историю.
/// {@endtemplate}
class AddHistoryItem extends HistoryEvent {
  final ExerciseHistory item;

  const AddHistoryItem({required this.item});

  @override
  List<Object?> get props => [item];
}

/// {@template update_injury_type_filter}
/// Событие обновления фильтра по типу травмы.
/// {@endtemplate}
class UpdateInjuryTypeFilter extends HistoryEvent {
  final String filter;

  const UpdateInjuryTypeFilter({required this.filter});

  @override
  List<Object?> get props => [filter];
}

/// {@template update_time_period_filter}
/// Событие обновления фильтра по периоду времени.
/// {@endtemplate}
class UpdateTimePeriodFilter extends HistoryEvent {
  final String filter;

  const UpdateTimePeriodFilter({required this.filter});

  @override
  List<Object?> get props => [filter];
}

/// {@template select_day}
/// Событие выбора дня в календаре.
/// {@endtemplate}
class SelectDay extends HistoryEvent {
  final DateTime? day;

  const SelectDay({this.day});

  @override
  List<Object?> get props => [day];
}