part of 'xp_cubit.dart';

class XpState extends Equatable {
  final int level;
  final int currentXp;
  final int requiredXp;
  final double progress;
  final bool justLeveledUp;

  const XpState({
    this.level = 1,
    this.currentXp = 0,
    this.requiredXp = 30,
    this.progress = 0.0,
    this.justLeveledUp = false,
  });

  XpState copyWith({
    int? level,
    int? currentXp,
    int? requiredXp,
    double? progress,
    bool? justLeveledUp,
  }) {
    return XpState(
      level: level ?? this.level,
      currentXp: currentXp ?? this.currentXp,
      requiredXp: requiredXp ?? this.requiredXp,
      progress: progress ?? this.progress,
      justLeveledUp: justLeveledUp ?? false,
    );
  }

  @override
  List<Object?> get props => [level, currentXp, requiredXp, progress, justLeveledUp];
}