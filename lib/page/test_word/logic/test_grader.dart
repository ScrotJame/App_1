/// What a graded Test answer does to its word.
enum GradeAction {
  /// `levelUpIfDue`: the word levels up when it is due.
  levelUp,

  /// The word already levelled up through Test today: only the history
  /// and the answer counter are written.
  recordOnly,

  /// `levelDown`: one level lower, the wait starts over.
  levelDown,
}

class TestGrader {
  TestGrader._();

  static GradeAction actionFor({
    required bool isCorrect,
    required bool leveledToday,
  }) {
    if (!isCorrect) return GradeAction.levelDown;
    return leveledToday ? GradeAction.recordOnly : GradeAction.levelUp;
  }
}
