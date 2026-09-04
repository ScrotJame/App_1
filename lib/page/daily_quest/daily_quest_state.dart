part of 'daily_quest_cubit.dart';

/// ─── STATE ──────────────────────────────────────────────────────────
/// State là "ảnh chụp" tại 1 thời điểm: chứa TẤT CẢ data mà UI cần.
/// Mỗi khi Cubit emit state mới → BlocBuilder rebuild widget.
///
/// ĐIỂM PHỎNG VẤN:
/// Q: "Tại sao dùng Equatable?"
/// A: BlocBuilder so sánh state cũ vs mới. Nếu KHÔNG dùng Equatable,
///    Dart so sánh bằng reference (==) → luôn khác → luôn rebuild.
///    Equatable so sánh bằng VALUE (props) → chỉ rebuild khi data thật sự đổi.
class DailyQuestState extends Equatable {
  final LOADSTATUS loadStatus;
  final List<DailyQuestModel> quests;
  final String? errorMessage;

  const DailyQuestState({
    this.loadStatus = LOADSTATUS.INITAL,
    this.quests = const [],
    this.errorMessage,
  });

  // ─── Computed Properties ────────────────────────────────────
  // UI đọc trực tiếp từ state, không cần tính lại trong widget.

  /// Tất cả quest đã hoàn thành?
  bool get allCompleted =>
      quests.isNotEmpty && quests.every((q) => q.isCompleted);

  /// Đếm số quest đã xong
  int get completedCount => quests.where((q) => q.isCompleted).length;

  /// Tổng gems thưởng từ các quest đã hoàn thành
  int get totalRewardGems =>
      quests.where((q) => q.isCompleted).fold(0, (s, q) => s + q.rewardGems);

  /// Tiến độ tổng thể: 0.0 → 1.0
  double get overallProgress =>
      quests.isEmpty ? 0.0 : completedCount / quests.length;

  // ─── CopyWith ──────────────────────────────────────────────

  DailyQuestState copyWith({
    LOADSTATUS? loadStatus,
    List<DailyQuestModel>? quests,
    String? errorMessage,
  }) {
    return DailyQuestState(
      loadStatus: loadStatus ?? this.loadStatus,
      quests: quests ?? this.quests,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [loadStatus, quests, errorMessage];
}
