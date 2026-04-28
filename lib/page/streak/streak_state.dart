part of 'streak_cubit.dart';

class DayStreak {
  final String label; // 'M', 'T', 'W', ...
  final int? date;    // số ngày trong tháng, null nếu đã check
  final bool isCompleted;
  final bool isToday;

  const DayStreak({
    required this.label,
    this.date,
    this.isCompleted = false,
    this.isToday = false,
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
  final int weekStreak;
  final String userName;
  final List<DayStreak> weekDays;
  final StreakStats stats;
  final LOADSTATUS loadStatus;
  final String? errorMessage;

  const StreakState({
    this.weekStreak = 0,
    this.userName = '',
    this.weekDays = const [],
    this.stats = const StreakStats(),
    this.loadStatus = LOADSTATUS.INITAL,
    this.errorMessage,
  });

  StreakState copyWith({
    int? weekStreak,
    String? userName,
    List<DayStreak>? weekDays,
    StreakStats? stats,
    LOADSTATUS? loadStatus,
    String? errorMessage,
  }) {
    return StreakState(
      weekStreak: weekStreak ?? this.weekStreak,
      userName: userName ?? this.userName,
      weekDays: weekDays ?? this.weekDays,
      stats: stats ?? this.stats,
      loadStatus: loadStatus ?? this.loadStatus,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [
    weekStreak,
    userName,
    weekDays,
    stats,
    loadStatus,
    errorMessage,
  ];
}