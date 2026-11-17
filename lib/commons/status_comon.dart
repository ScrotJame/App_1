/// Status of a word for a user. It is never set on its own: it is always
/// derived from the word's level, which is the only progress measure.
class WordStatus {
  static const int notStarted = 0;
  static const int learning = 1;
  static const int mastered = 2;

  /// Level from which a word counts as mastered.
  static const int masteredLevel = 5;

  static int fromLevel(int level) {
    if (level >= masteredLevel) return mastered;
    if (level >= 1) return learning;
    return notStarted;
  }
}

/// Learning mode labels, stored in LearningHistoryLogs.sessionType.
class SessionType {
  static const String test = 'Test';
  static const String feed = 'Feed';
  static const String quiz = 'Quiz';
  static const String matching = 'Matching';
  static const String flashcard = 'Flashcard';
}