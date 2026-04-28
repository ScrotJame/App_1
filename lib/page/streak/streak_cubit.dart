import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../commons/enums.dart';

part 'streak_state.dart';

class StreakCubit extends Cubit<StreakState> {
  StreakCubit() : super(const StreakState());

  Future<void> loadStreak() async {
    emit(state.copyWith(loadStatus: LOADSTATUS.LOADING));

    try {
      // TODO: thay bằng call thực từ repository
      await Future.delayed(const Duration(milliseconds: 400));

      // Mock data — thay bằng dữ liệu thực từ DB/API
      final weekDays = [
        const DayStreak(label: 'M', isCompleted: true),
        const DayStreak(label: 'T', isCompleted: true),
        const DayStreak(label: 'W', isCompleted: true),
        const DayStreak(label: 'T', isCompleted: true),
        const DayStreak(label: 'F', date: 29, isToday: true),
        const DayStreak(label: 'S', date: 30),
        const DayStreak(label: 'S', date: 31),
      ];

      const stats = StreakStats(
        days: 22,
        lessons: 36,
        quizzes: 18,
        minutes: 231,
        insightsAvailable: 2,
      );

      emit(state.copyWith(
        weekStreak: 4,
        userName: 'Anna',
        weekDays: weekDays,
        stats: stats,
        loadStatus: LOADSTATUS.SUCCESS,
      ));
    } catch (e) {
      emit(state.copyWith(
        loadStatus: LOADSTATUS.FAILED,
        errorMessage: 'Tải dữ liệu thất bại: $e',
      ));
    }
  }

  void onInsightsTapped() {
    // TODO: navigate hoặc mở bottom sheet insights
  }
}