import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:test_abc/commons/enums.dart';
import 'package:test_abc/commons/user_sesion.dart';
import 'package:test_abc/models/entity/learning_history_entity.dart';
import 'package:test_abc/repository/learning_history_repository.dart';
import 'package:test_abc/service/personalization_service.dart';

part 'learning_history_state.dart';

class LearningHistoryCubit extends Cubit<LearningHistoryState> {
  final LearningHistoryRepository _historyRepo;

  LearningHistoryCubit(this._historyRepo) : super(LearningHistoryState());

  final _userKey = UserSession.instance.userKey;

  /// Khởi tạo toàn bộ dữ liệu ban đầu
  Future<void> init() async {
    emit(state.copyWith(loadStatus: LOADSTATUS.LOADING));
    try {
      await _initPersonalization();
      await _loadActiveDates();
      await _loadHistoryForSelectedDate();
      emit(state.copyWith(loadStatus: LOADSTATUS.SUCCESS));
    } catch (e) {
      emit(state.copyWith(
        loadStatus: LOADSTATUS.FAILED,
        errorMessage: 'Tải dữ liệu thất bại: $e',
      ));
    }
  }

  Future<void> _initPersonalization() async {
    await PersonalizationService.instance.init();
    final dailyGoal = PersonalizationService.instance.getDailyWordTarget();
    emit(state.copyWith(dailyGoal: dailyGoal));
  }

  Future<void> _loadActiveDates() async {
    emit(state.copyWith(isLoadingActiveDates: true));
    try {
      final dates = await _historyRepo.getActiveDates(userKey: _userKey);
      emit(state.copyWith(
        activeDates:
            dates.map((d) => DateTime(d.year, d.month, d.day)).toList(),
        isLoadingActiveDates: false,
      ));
    } catch (e) {
      debugPrint('Error loading active dates: $e');
      emit(state.copyWith(isLoadingActiveDates: false));
    }
  }

  Future<void> _loadHistoryForSelectedDate() async {
    emit(state.copyWith(isLoadingHistory: true));
    try {
      final history = await _historyRepo.getHistoryByDate(
        userKey: _userKey,
        date: state.selectedDate,
        page: 1,
        pageSize: 100,
      );
      emit(state.copyWith(
        wordsStudied: history,
        isLoadingHistory: false,
      ));
    } catch (e) {
      debugPrint('Error loading history: $e');
      emit(state.copyWith(isLoadingHistory: false));
    }
  }

  /// Chọn ngày trên calendar
  void onDateSelected(DateTime date) {
    if (date.isAfter(DateTime.now())) return;
    emit(state.copyWith(selectedDate: date));
    _loadHistoryForSelectedDate();
  }

  /// Lùi tháng
  void previousMonth() {
    emit(state.copyWith(
      focusedMonth:
          DateTime(state.focusedMonth.year, state.focusedMonth.month - 1),
    ));
  }

  /// Tiến tháng
  void nextMonth() {
    final next =
        DateTime(state.focusedMonth.year, state.focusedMonth.month + 1);
    if (next.isAfter(DateTime.now()) && next.month != DateTime.now().month) {
      return;
    }
    emit(state.copyWith(focusedMonth: next));
  }
}
