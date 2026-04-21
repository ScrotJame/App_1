part of 'xp_cubit.dart';

class XpState extends Equatable {
  final int currentXp;
  final int maxXp;
  final int level;

  const XpState({
    required this.currentXp,
    required this.maxXp,
    required this.level,
  });

  factory XpState.initial() => const XpState(
    currentXp: 0,
    maxXp: 36,
    level: 1,
  );

  double get progress => (currentXp / maxXp).clamp(0.0, 1.0);

  XpState copyWith({int? currentXp, int? maxXp, int? level}) => XpState(
    currentXp: currentXp ?? this.currentXp,
    maxXp: maxXp ?? this.maxXp,
    level: level ?? this.level,
  );

  @override
  List<Object> get props => [currentXp, maxXp, level];
}