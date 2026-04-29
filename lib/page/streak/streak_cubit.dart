import 'package:bloc/bloc.dart';
import 'package:drift/drift.dart';
import 'package:equatable/equatable.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../commons/enums.dart';
import '../../database/app_db.dart';
import '../../repository/user_repository.dart';

part 'streak_state.dart';

class StreakCubit extends Cubit<StreakState> {
  final UserRepository _userRepository;

  static const String _prefKey = 'streak_marked_dates';

  StreakCubit(this._userRepository) : super(const StreakState());

  // ─── Helpers ──────────────────────────────────────────────────────

  static const List<String> _dayLabels = [
    'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun',
  ];

  static String _dateKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  static DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  List<DayStreak> _buildWeekDays(int offset, Set<String> markedDates) {
    final now = DateTime.now();
    final todayWeekday = now.weekday;
    final thisMonday =
    DateTime(now.year, now.month, now.day - (todayWeekday - 1));
    final weekMonday = thisMonday.add(Duration(days: offset * 7));

    return List.generate(7, (i) {
      final day = weekMonday.add(Duration(days: i));
      final isToday = day.year == now.year &&
          day.month == now.month &&
          day.day == now.day;
      final isFuture = day.isAfter(now);

      return DayStreak(
        label: _dayLabels[i],
        date: day.day,
        month: day.month,
        year: day.year,
        isCompleted: markedDates.contains(_dateKey(day)),
        isToday: isToday,
        isFuture: isFuture,
      );
    });
  }

  /// Đếm streak liên tục từ hôm nay lùi về quá khứ.
  int _calcCurrentStreak(Set<String> markedDates) {
    final today = _dateOnly(DateTime.now());
    int streak = 0;
    DateTime cursor = today;
    while (markedDates.contains(_dateKey(cursor))) {
      streak++;
      cursor = cursor.subtract(const Duration(days: 1));
    }
    return streak;
  }

  /// Ngày đầu tiên của chuỗi streak liên tục hiện tại.
  DateTime? _calcStreakStartDate(Set<String> markedDates) {
    final today = _dateOnly(DateTime.now());
    DateTime cursor = today;
    DateTime? startDate;
    while (markedDates.contains(_dateKey(cursor))) {
      startDate = cursor;
      cursor = cursor.subtract(const Duration(days: 1));
    }
    return startDate;
  }

  // ─── SharedPreferences ────────────────────────────────────────────

  Future<Set<String>> _loadMarkedDates() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_prefKey) ?? [];
    return list.toSet();
  }

  Future<void> _saveMarkedDates(Set<String> markedDates) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_prefKey, markedDates.toList());
  }

  // ─── DB streak sync ───────────────────────────────────────────────

  Future<void> _syncStreakToDB({
    required int currentStreak,
    required int longestStreak,
    required DateTime? lastActiveDate,
  }) async {
    await _userRepository.updateUser(
      UsersEntrieCompanion(
        currentStreak: Value(currentStreak),
        longestStreak: Value(longestStreak),
        lastActiveDate: Value(lastActiveDate),
      ),
    );
  }

  // ─── Load ─────────────────────────────────────────────────────────

  Future<void> loadProfile() async {
    emit(state.copyWith(loadStatus: LOADSTATUS.INITAL));
    try {
      final user = await _userRepository.getCurrentUser();
      if (user == null) {
        emit(state.copyWith(
          loadStatus: LOADSTATUS.FAILED,
          errorMessage: 'Không tìm thấy user',
        ));
        return;
      }

      final today = _dateOnly(DateTime.now());
      final yesterday = today.subtract(const Duration(days: 1));
      final lastActive = user.lastActiveDate != null
          ? _dateOnly(user.lastActiveDate!)
          : null;

      // ── Kiểm tra streak bị gián đoạn ──────────────────────────────
      // lastActiveDate không phải hôm nay và không phải hôm qua
      // → bỏ lỡ ≥ 1 ngày → reset currentStreak = 0
      bool streakWasReset = false;
      int dbCurrentStreak = user.currentStreak;
      final int dbLongestStreak = user.longestStreak;

      if (lastActive != null &&
          lastActive.isBefore(yesterday) &&
          dbCurrentStreak > 0) {
        dbCurrentStreak = 0;
        streakWasReset = true;
        await _syncStreakToDB(
          currentStreak: 0,
          longestStreak: dbLongestStreak,
          lastActiveDate: user.lastActiveDate,
        );
      }

      final markedDates = await _loadMarkedDates();
      final currentStreak = _calcCurrentStreak(markedDates);
      final streakStart = _calcStreakStartDate(markedDates);
      final weekDays = _buildWeekDays(0, markedDates);

      emit(state.copyWith(
        loadStatus: LOADSTATUS.SUCCESS,
        data: user,
        weekOffset: 0,
        markedDates: markedDates,
        weekDays: weekDays,
        weekStreak: currentStreak,
        longestStreak: dbLongestStreak,
        streakStartDate: streakStart,
        streakWasReset: streakWasReset,
      ));
    } catch (e) {
      emit(state.copyWith(
        loadStatus: LOADSTATUS.FAILED,
        errorMessage: e.toString(),
      ));
    }
  }

  // ─── Mark today ───────────────────────────────────────────────────

  Future<void> markToday() async {
    final now = DateTime.now();
    final today = _dateOnly(now);
    final key = _dateKey(today);
    final updated = Set<String>.from(state.markedDates);

    final wasMarked = updated.contains(key);
    if (wasMarked) {
      updated.remove(key);
    } else {
      updated.add(key);
    }

    final newStreak = _calcCurrentStreak(updated);
    final streakStart = _calcStreakStartDate(updated);
    final weekDays = _buildWeekDays(state.weekOffset, updated);

    // longestStreak chỉ tăng khi mark, không giảm khi unmark
    final newLongest = wasMarked
        ? state.longestStreak
        : (newStreak > state.longestStreak ? newStreak : state.longestStreak);

    // Cập nhật UI ngay lập tức
    emit(state.copyWith(
      markedDates: updated,
      weekDays: weekDays,
      weekStreak: newStreak,
      longestStreak: newLongest,
      streakStartDate: streakStart,
      clearStreakStart: streakStart == null,
      streakWasReset: false,
    ));

    // Lưu SharedPreferences + DB song song
    await Future.wait([
      _saveMarkedDates(updated),
      _syncStreakToDB(
        currentStreak: newStreak,
        longestStreak: newLongest,
        // Nếu unmark hết streak thì xóa lastActiveDate
        lastActiveDate: streakStart != null ? now : null,
      ),
    ]);
  }

  // ─── Week navigation ──────────────────────────────────────────────

  void previousWeek() {
    final newOffset = state.weekOffset - 1;
    emit(state.copyWith(
      weekOffset: newOffset,
      weekDays: _buildWeekDays(newOffset, state.markedDates),
    ));
  }

  void nextWeek() {
    if (!state.canGoNext) return;
    final newOffset = state.weekOffset + 1;
    emit(state.copyWith(
      weekOffset: newOffset,
      weekDays: _buildWeekDays(newOffset, state.markedDates),
    ));
  }

  void goToCurrentWeek() {
    emit(state.copyWith(
      weekOffset: 0,
      weekDays: _buildWeekDays(0, state.markedDates),
    ));
  }

  // ─── Insights ─────────────────────────────────────────────────────

  void onInsightsTapped() {
    // TODO: navigate hoặc mở bottom sheet insights
  }
}