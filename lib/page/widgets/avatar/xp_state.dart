part of 'xp_cubit.dart';

class XpState extends Equatable {
  final int level;
  final int currentXp;
  final int requiredXp;
  final double progress;
  final bool justLeveledUp;
  final Xp tab;

  const XpState({
    this.level = 1,
    this.currentXp = 0,
    this.requiredXp = 30,
    this.progress = 0.0,
    this.justLeveledUp = false,
    this.tab =Xp.levelTab,
  });

  XpState copyWith({
    int? level,
    int? currentXp,
    int? requiredXp,
    double? progress,
    bool? justLeveledUp,
    Xp? tab,
  }) {
    return XpState(
      level: level ?? this.level,
      currentXp: currentXp ?? this.currentXp,
      requiredXp: requiredXp ?? this.requiredXp,
      progress: progress ?? this.progress,
      justLeveledUp: justLeveledUp ?? this.justLeveledUp,
      tab: tab ?? this.tab
    );
  }

  @override
  List<Object?> get props => [
    level,
    currentXp,
    requiredXp,
    progress,
    justLeveledUp,
    tab
  ];
}
