enum TabItem { travel, favorite, home, message, user }
enum FlashcardArenaStatus { initial, inProgress, flipped, completed }

enum DifficultyRating { again, hard, good, easy }

enum LOADSTATUS {INITAL ,LOADING, SUCCESS, FAILED}
enum VocabLevel { basic, intermediate, advanced }

///JP
enum VocabTagJP { noun, verb, adjI, adjNa, adverb, expression}
enum VocabLevelJP { N1, N2, N3, N4, N5 }
enum QuizStatus { initial, inProgress, answered, completed }
enum BattleAnimState { idle, attack, hurt, faint }
enum TtsSpeakResult { ok, empty, languageUnavailable }

enum AuthStatus { unauthenticated, loading, authenticated, error }

enum BackupMode { file, server }

enum BackupStatus { initial, loading, success, failed }

enum PageType { Add, Put }

enum TokenRole { none, word, pronunciation, meaning, language }

enum SCANSTATUS { idle, scanning, scanned, error }

enum CompanionStatus {
  initial,
  loading,
  awaitingChoice,
  browsing,
  active,
  confirmingDelete,
  error,
}

enum LearningPhase { config, flashCard, wordMatching, quizGame, comingSoon }

enum LearningType {
  flashCard,
  wordMatching,
  quizGame,
  comingSoon,
}

enum WordMatchingItemStatus { idle, selected, correct, wrong }

enum WordMatchingGameStatus {
  initial,
  loading,
  playing,
  wrongAnimation,
  roundComplete,
  completed,
  gameOver,
}

enum UnitSortOrder { byId, byTitle, byWordCount }

enum ProfileStatus { initial, loading, loaded, error }

enum Xp { xpTab, levelTab }

enum SplashStatus { initial, loading, newUser, returning, error }

enum ShopStatus { initial, loading, success, error }

enum TestPhase { config, testing, result }

enum TimerMode { total, perWord }

enum QuestionType { wordToMeaning, meaningToWord, random }

enum WordFilter { all, learned, notLearned }

enum AnswerStatus { unanswered, correct, incorrect }
