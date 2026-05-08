part of 'streak_cubit.dart';

class DayStreak {
  final int weekdayIndex;
  final int date;
  final int month;
  final int year;
  final bool isCompleted;
  final bool isToday;
  final bool isFuture;

  const DayStreak({
    required this.weekdayIndex,
    required this.date,
    required this.month,
    required this.year,
    this.isCompleted = false,
    this.isToday = false,
    this.isFuture = false,
  });
}

class StreakStats {
  final int days;
  final int lessons;
  final int quizzes;
  final int minutes;
  final int insightsAvailable;

  const StreakStats({
    this.days = 0,
    this.lessons = 0,
    this.quizzes = 0,
    this.minutes = 0,
    this.insightsAvailable = 0,
  });
}

class StreakState extends Equatable {
  /// Streak hiện tại (liên tục từ hôm nay).
  final int weekStreak;

  /// Streak dài nhất từ trước đến nay.
  final int longestStreak;

  final String userName;
  final List<DayStreak> weekDays;
  final StreakStats stats;
  final LOADSTATUS loadStatus;
  final String? errorMessage;
  final UsersEntrieData? data;

  /// Offset tuần: 0 = tuần này, -1 = tuần trước, ...
  final int weekOffset;

  /// Các ngày đã mark dạng 'yyyy-MM-dd'.
  final Set<String> markedDates;

  /// Ngày đầu tiên của chuỗi streak liên tục hiện tại.
  final DateTime? streakStartDate;

  /// True khi vừa phát hiện streak bị reset do bỏ lỡ ngày.
  final bool streakWasReset;

  const StreakState({
    this.weekStreak = 0,
    this.longestStreak = 0,
    this.userName = '',
    this.weekDays = const [],
    this.stats = const StreakStats(),
    this.loadStatus = LOADSTATUS.INITAL,
    this.errorMessage,
    this.data,
    this.weekOffset = 0,
    this.markedDates = const {},
    this.streakStartDate,
    this.streakWasReset = false,
  });

  StreakState copyWith({
    int? weekStreak,
    int? longestStreak,
    String? userName,
    List<DayStreak>? weekDays,
    StreakStats? stats,
    LOADSTATUS? loadStatus,
    String? errorMessage,
    UsersEntrieData? data,
    int? weekOffset,
    Set<String>? markedDates,
    DateTime? streakStartDate,
    bool clearStreakStart = false,
    bool? streakWasReset,
  }) {
    return StreakState(
      weekStreak: weekStreak ?? this.weekStreak,
      longestStreak: longestStreak ?? this.longestStreak,
      userName: userName ?? this.userName,
      weekDays: weekDays ?? this.weekDays,
      stats: stats ?? this.stats,
      loadStatus: loadStatus ?? this.loadStatus,
      errorMessage: errorMessage ?? this.errorMessage,
      data: data ?? this.data,
      weekOffset: weekOffset ?? this.weekOffset,
      markedDates: markedDates ?? this.markedDates,
      streakStartDate:
      clearStreakStart ? null : (streakStartDate ?? this.streakStartDate),
      streakWasReset: streakWasReset ?? this.streakWasReset,
    );
  }

  bool get isTodayMarked {
    final today = DateTime.now();
    final key =
        '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
    return markedDates.contains(key);
  }

  bool get canGoNext => weekOffset < 0;

  @override
  List<Object?> get props => [
    weekStreak,
    longestStreak,
    userName,
    weekDays,
    stats,
    loadStatus,
    errorMessage,
    data,
    weekOffset,
    markedDates,
    streakStartDate,
    streakWasReset,
  ];
}