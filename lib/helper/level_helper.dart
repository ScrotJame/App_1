class LevelHelper {
  static const double _multiplier = 1.5;
  static const int _baseXp = 30;

  static int xpRequired(int level) =>
      (_baseXp * _multiplier * (level - 1) + _baseXp).round();

  // Tính info từ tổng xp tích lũy
  static ({int level, int currentXp, int requiredXp, double progress})
  calculate(int totalXp) {
    int level = 1;
    int remaining = totalXp;

    while (remaining >= xpRequired(level)) {
      remaining -= xpRequired(level);
      level++;
    }

    final required = xpRequired(level);
    return (
    level: level,
    currentXp: remaining,
    requiredXp: required,
    progress: remaining / required,
    );
  }

  // Cộng xp
  static ({int newLevel, int newXp, bool levelUp}) addXp({
    required int currentLevel,
    required int currentXp,
    required int gainXp,
  }) {
    int xp = currentXp + gainXp;
    int level = currentLevel;
    bool levelUp = false;

    while (xp >= xpRequired(level)) {
      xp -= xpRequired(level);
      level++;
      levelUp = true;
    }

    return (newLevel: level, newXp: xp, levelUp: levelUp);
  }
}