part of 'achievement_cubit.dart';

class AchievementState extends Equatable {
  final LOADSTATUS loadStatus;
  final List<AchivementEntity> achievements;
  final String? selectedCategory;
  final UsersEntrieData? user;

  const AchievementState({
    this.loadStatus = LOADSTATUS.LOADING,
    this.achievements = const [],
    this.selectedCategory,
    this.user
  });

  // ── Computed getters ─────────────────────────────────────────
  /// Chỉ hiển thị những thành tựu isVisible = true HOẶC đã unlock
  List<AchivementEntity> get visibleAchievements => achievements
      .where((a) => (a.isVisible ?? false) || (a.isUnlocked ?? false))
      .toList();

  /// Lọc theo category đang chọn, null = All
  List<AchivementEntity> get filteredAchievements {
    final base = visibleAchievements;
    if (selectedCategory == null) return base;
    return base.where((a) => a.category == selectedCategory).toList();
  }

  int get unlockedCount =>
      achievements.where((a) => a.isUnlocked ?? false).length;

  int get totalVisible => visibleAchievements.length;

  /// Phần trăm hoàn thành (0–100), dùng cho progress ring
  int get completionPercent =>
      totalVisible == 0 ? 0 : ((unlockedCount / totalVisible) * 100).round();

  // ── copyWith ─────────────────────────────────────────────────
  AchievementState copyWith({
    LOADSTATUS? loadStatus,
    List<AchivementEntity>? achievements,
    String? selectedCategory,
    bool clearCategory = false,
    UsersEntrieData? user
  }) {
    return AchievementState(
      loadStatus: loadStatus ?? this.loadStatus,
      achievements: achievements ?? this.achievements,
      selectedCategory:
      clearCategory ? null : selectedCategory ?? this.selectedCategory,
      user: user ?? this.user
    );
  }

  @override
  List<Object?> get props => [loadStatus, achievements, selectedCategory, user];
}