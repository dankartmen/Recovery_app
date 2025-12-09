import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';


import '../../data/models/exercise_history.dart';
import '../../data/repositories/history_repository.dart'; // RecoveryData, TrainingSchedule, Training

part 'history_event.dart';
part 'history_state.dart';

/// {@template history_bloc}
/// BLoC для управления историей выполненных упражнений.
/// Обеспечивает загрузку, обновление, фильтрацию и добавление записей истории.
/// {@endtemplate}
class HistoryBloc extends Bloc<HistoryEvent, HistoryState> {
  final HistoryRepository repository;

  HistoryBloc({required this.repository}) : super(HistoryInitial()) {
    on<LoadHistory>(_onLoadHistory);
    on<RefreshHistory>(_onRefreshHistory);
    on<AddHistoryItem>(_onAddHistoryItem);
    on<UpdateInjuryTypeFilter>(_onUpdateInjuryTypeFilter);
    on<UpdateTimePeriodFilter>(_onUpdateTimePeriodFilter);
    on<SelectDay>(_onSelectDay);
  }

  Future<void> _onLoadHistory(LoadHistory event, Emitter<HistoryState> emit) async {
    emit(HistoryLoading());
    try {
      debugPrint("Загружаю историю в history_bloc");
      final history = await repository.getAllHistory();
      emit(HistoryLoaded(
        history: history,
        selectedInjuryType: 'Все',
        selectedTimePeriod: 'За всё время',
      ));
    } catch (e) {
      debugPrint("Ошибка загрузки истории: $e");
      emit(HistoryError(message: 'Ошибка загрузки истории: $e'));
    }
  }

  Future<void> _onRefreshHistory(RefreshHistory event, Emitter<HistoryState> emit) async {
    if (state is HistoryLoaded) {
      final current = state as HistoryLoaded;
      emit(HistoryLoading());
      try {
        debugPrint("Обновляю историю в history_bloc");
        final history = await repository.getAllHistory();
        emit(current.copyWith(history: history));
      } catch (e) {
        emit(HistoryError(message: 'Ошибка обновления истории: $e'));
      }
    }
  }

  void _onAddHistoryItem(AddHistoryItem event, Emitter<HistoryState> emit) {
    if (state is HistoryLoaded) {
      final current = state as HistoryLoaded;
      emit(current.copyWith(history: [...current.history, event.item]));
    }
  }

  void _onUpdateInjuryTypeFilter(UpdateInjuryTypeFilter event, Emitter<HistoryState> emit) {
    if (state is HistoryLoaded) {
      final current = state as HistoryLoaded;
      emit(current.copyWith(selectedInjuryType: event.filter));
    }
  }

  void _onUpdateTimePeriodFilter(UpdateTimePeriodFilter event, Emitter<HistoryState> emit) {
    if (state is HistoryLoaded) {
      final current = state as HistoryLoaded;
      emit(current.copyWith(selectedTimePeriod: event.filter));
    }
  }

  void _onSelectDay(SelectDay event, Emitter<HistoryState> emit) {
    if (state is HistoryLoaded) {
      final current = state as HistoryLoaded;
      emit(current.copyWith(selectedDay: event.day));
    }
  }
}