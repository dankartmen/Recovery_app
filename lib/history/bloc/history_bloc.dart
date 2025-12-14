import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import '../../data/repositories/exercise_history_repository.dart';
import '../../exercises/models/exercise_history.dart';

part 'history_event.dart';
part 'history_state.dart';

/// {@template history_bloc}
/// BLoC для управления историей выполненных упражнений.
/// Обеспечивает загрузку, обновление, фильтрацию и добавление записей истории.
/// {@endtemplate}
class HistoryBloc extends Bloc<HistoryEvent, HistoryState> {
  final ExerciseHistoryRepository repository;
  List<ExerciseHistory> _cachedHistory = [];
  DateTime? _lastLoadTime;
  static const Duration _cacheDuration = Duration(minutes: 5);

  HistoryBloc({required this.repository}) : super(HistoryInitial()) {
    on<LoadHistory>(_onLoadHistory);
    on<RefreshHistory>(_onRefreshHistory);
    on<AddHistoryItem>(_onAddHistoryItem);
    on<UpdateInjuryTypeFilter>(_onUpdateInjuryTypeFilter);
    on<UpdateTimePeriodFilter>(_onUpdateTimePeriodFilter);
    on<SelectDay>(_onSelectDay);
    on<ClearFilters>(_onClearFilters);
  }

  Future<void> _onLoadHistory(LoadHistory event, Emitter<HistoryState> emit) async {
    final canUseCache = _cachedHistory.isNotEmpty && 
                       _lastLoadTime != null && 
                       DateTime.now().difference(_lastLoadTime!) < _cacheDuration;
    
    if (canUseCache) {
      emit(HistoryLoaded(
        history: _cachedHistory,
        selectedInjuryType: 'Все',
        selectedTimePeriod: 'За всё время',
        selectedDay: null,
      ));
      return;
    }

    emit(HistoryLoading());
    try {
      debugPrint("Загружаю историю в history_bloc");
      final history = await repository.getAllHistory();
      
      _cachedHistory = history;
      _lastLoadTime = DateTime.now();
      
      emit(HistoryLoaded(
        history: history,
        selectedInjuryType: 'Все',
        selectedTimePeriod: 'За всё время',
        selectedDay: null,
      ));
    } catch (e) {
      debugPrint("Ошибка загрузки истории: $e");
      emit(HistoryError(message: 'Ошибка загрузки истории: $e'));
    }
  }

  Future<void> _onRefreshHistory(RefreshHistory event, Emitter<HistoryState> emit) async {
    emit(HistoryLoading());
    try {
      debugPrint("Обновляю историю в history_bloc");
      final history = await repository.getAllHistory();
      
      _cachedHistory = history;
      _lastLoadTime = DateTime.now();
      
      if (state is HistoryLoaded) {
        final current = state as HistoryLoaded;
        emit(current.copyWith(history: history));
      } else {
        emit(HistoryLoaded(
          history: history,
          selectedInjuryType: 'Все',
          selectedTimePeriod: 'За всё время',
          selectedDay: null,
        ));
      }
    } catch (e) {
      emit(HistoryError(message: 'Ошибка обновления истории: $e'));
    }
  }

  void _onAddHistoryItem(AddHistoryItem event, Emitter<HistoryState> emit) {
    if (state is HistoryLoaded) {
      final current = state as HistoryLoaded;
      final updatedHistory = [...current.history, event.item];
      
      _cachedHistory = updatedHistory;
      _lastLoadTime = DateTime.now();
      
      emit(current.copyWith(history: updatedHistory));
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

  void _onClearFilters(ClearFilters event, Emitter<HistoryState> emit) {
    if (state is HistoryLoaded) {
      final current = state as HistoryLoaded;
      emit(current.copyWith(
        selectedInjuryType: 'Все',
        selectedTimePeriod: 'За всё время',
        selectedDay: null,
      ));
    }
  }

  // Геттер для получения истории
  List<ExerciseHistory> get history => _cachedHistory;
}