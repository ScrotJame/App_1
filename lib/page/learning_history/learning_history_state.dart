part of 'learning_history_cubit.dart';

class LearningHistoryState extends Equatable {
  final LOADSTATUS loadStatus;
  final DateTime focusedMonth;
  final DateTime selectedDate;
  final List<DateTime> activeDates;
  final List<LearningHistoryEntity> wordsStudied;
  final bool isLoadingHistory;
  final bool isLoadingActiveDates;
  final int dailyGoal;
  final String? errorMessage;

  LearningHistoryState({
    this.loadStatus = LOADSTATUS.INITAL,
    DateTime? focusedMonth,
    DateTime? selectedDate,
    this.activeDates = const [],
    this.wordsStudied = const [],
    this.isLoadingHistory = false,
    this.isLoadingActiveDates = false,
    this.dailyGoal = 20,
    this.errorMessage,
  })  : focusedMonth = focusedMonth ?? DateTime.now(),
        selectedDate = selectedDate ?? DateTime.now();

  // ── Computed ────────────────────────────────
  int get correctCount =>
      wordsStudied.where((w) => w.isCorrect ?? false).length;

  int get accuracy => wordsStudied.isEmpty
      ? 0
      : ((correctCount / wordsStudied.length) * 100).toInt();

  double get dailyProgress {
    if (wordsStudied.isEmpty) return 0.0;
    final raw = wordsStudied.length / dailyGoal;
    return raw > 1.0 ? 1.0 : raw;
  }

  // ── copyWith ────────────────────────────────
  LearningHistoryState copyWith({
    LOADSTATUS? loadStatus,
    DateTime? focusedMonth,
    DateTime? selectedDate,
    List<DateTime>? activeDates,
    List<LearningHistoryEntity>? wordsStudied,
    bool? isLoadingHistory,
    bool? isLoadingActiveDates,
    int? dailyGoal,
    String? errorMessage,
  }) {
    return LearningHistoryState(
      loadStatus: loadStatus ?? this.loadStatus,
      focusedMonth: focusedMonth ?? this.focusedMonth,
      selectedDate: selectedDate ?? this.selectedDate,
      activeDates: activeDates ?? this.activeDates,
      wordsStudied: wordsStudied ?? this.wordsStudied,
      isLoadingHistory: isLoadingHistory ?? this.isLoadingHistory,
      isLoadingActiveDates: isLoadingActiveDates ?? this.isLoadingActiveDates,
      dailyGoal: dailyGoal ?? this.dailyGoal,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        loadStatus,
        focusedMonth,
        selectedDate,
        activeDates,
        wordsStudied,
        isLoadingHistory,
        isLoadingActiveDates,
        dailyGoal,
        errorMessage,
      ];
}
