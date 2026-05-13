part of 'test_cubit.dart';

// ═════════════════════════════════════════════════════════════════════════════
// ENUMS
// ═════════════════════════════════════════════════════════════════════════════

enum TestPhase { config, testing, result }

enum TimerMode {
  total,    // Một mốc giờ cho cả bài
  perWord,  // Reset giờ sau mỗi câu
}

enum QuestionType {
  wordToMeaning,  // Hiện từ → chọn nghĩa
  meaningToWord,  // Hiện nghĩa → chọn từ
  random,         // Xáo trộn ngẫu nhiên cả hai
}

enum WordFilter {
  all,        // Tất cả từ
  learned,    // Đã thuộc (isFavorite == true)
  notLearned, // Chưa thuộc (isFavorite != true)
}

enum AnswerStatus { unanswered, correct, incorrect }

// ═════════════════════════════════════════════════════════════════════════════
// TEST CONFIG
// ═════════════════════════════════════════════════════════════════════════════

class TestConfig extends Equatable {
  const TestConfig({
    this.questionCount = 10,
    this.timerMode = TimerMode.total,
    this.timeLimitSeconds = 600,
    this.enableTimer = true,
    this.wordFilter = WordFilter.all,
    this.selectedTagIds = const [],   // rỗng = tất cả tag
    this.selectedLanguage,            // null = tất cả ngôn ngữ
  });

  final int questionCount;
  final TimerMode timerMode;
  final int timeLimitSeconds;
  final bool enableTimer;
  final WordFilter wordFilter;

  /// Lọc theo tag id (unit). Rỗng = không lọc tag
  final List<int> selectedTagIds;

  /// Lọc theo ngôn ngữ của từ (vd: 'ja', 'en'). null = không lọc
  final String? selectedLanguage;

  TestConfig copyWith({
    int? questionCount,
    TimerMode? timerMode,
    int? timeLimitSeconds,
    bool? enableTimer,
    WordFilter? wordFilter,
    List<int>? selectedTagIds,
    Object? selectedLanguage = _sentinel,
  }) {
    return TestConfig(
      questionCount: questionCount ?? this.questionCount,
      timerMode: timerMode ?? this.timerMode,
      timeLimitSeconds: timeLimitSeconds ?? this.timeLimitSeconds,
      enableTimer: enableTimer ?? this.enableTimer,
      wordFilter: wordFilter ?? this.wordFilter,
      selectedTagIds: selectedTagIds ?? this.selectedTagIds,
      selectedLanguage: selectedLanguage == _sentinel
          ? this.selectedLanguage
          : selectedLanguage as String?,
    );
  }

  @override
  List<Object?> get props => [
    questionCount, timerMode, timeLimitSeconds, enableTimer,
    wordFilter, selectedTagIds, selectedLanguage,
  ];
}

// ═════════════════════════════════════════════════════════════════════════════
// TEST QUESTION
// ═════════════════════════════════════════════════════════════════════════════

class TestQuestion extends Equatable {
  const TestQuestion({
    required this.word,
    required this.questionType, // loại thực tế (wordToMeaning hoặc meaningToWord)
    required this.choices,      // 4 đáp án đã shuffle
    required this.correctIndex,
  });

  final VocabularyWithTags word;
  final QuestionType questionType;
  final List<String> choices;
  final int correctIndex;

  /// Nội dung hiển thị trên thẻ câu hỏi
  String get questionDisplay => questionType == QuestionType.wordToMeaning
      ? word.word.word
      : word.word.meaning;

  /// Câu hỏi hướng dẫn phía dưới thẻ
  String get questionLabel => questionType == QuestionType.wordToMeaning
      ? 'Nghĩa của từ trên là gì?'
      : 'Từ nào có nghĩa trên?';

  /// Label nhỏ trên thẻ
  String get cardLabel =>
      questionType == QuestionType.wordToMeaning ? 'Từ vựng' : 'Nghĩa';

  /// Phiên âm — chỉ hiện khi hỏi từ → nghĩa
  String? get pronunciationDisplay =>
      questionType == QuestionType.wordToMeaning
          ? word.word.pronunciation
          : null;

  @override
  List<Object?> get props => [word, questionType, choices, correctIndex];
}


class TestState extends Equatable {
  const TestState({
    this.phase = TestPhase.config,
    this.config = const TestConfig(),

    // Dữ liệu cho màn config
    this.allTags = const [],
    this.availableLanguages = const [],

    // Câu hỏi
    this.questions = const [],
    this.currentIndex = 0,
    this.selectedAnswerIndex,
    this.answerStatuses = const {},
    this.score = 0,

    // Timer
    this.remainingSeconds = 0,

    // Hint
    this.eliminatedIndexes = const {},
    this.hintsUsed = 0,
    this.maxHints = 3,

    // Level up — danh sách VocabularyEntry SAU KHI đã được tăng level
    // Chỉ chứa các từ có isFavorite == true và đã trả lời đúng
    this.leveledUpWords = const [],
    this.isLevelingUp = false,

    // Rewards — tính khi chuyển sang phase result
    this.xpEarned = 0,
    this.gemsEarned = 0,

    // Loading
    this.loadStatus = LOADSTATUS.INITAL,
    this.errorMessage,
  });

  final TestPhase phase;
  final TestConfig config;

  final List<Tag> allTags;
  final List<String> availableLanguages;

  final List<TestQuestion> questions;
  final int currentIndex;
  final int? selectedAnswerIndex;
  final Map<int, AnswerStatus> answerStatuses;
  final int score;

  final int remainingSeconds;

  final Map<int, List<int>> eliminatedIndexes;
  final int hintsUsed;
  final int maxHints;

  final List<VocabularyEntry> leveledUpWords;
  final bool isLevelingUp;

  final int xpEarned;
  final int gemsEarned;

  final LOADSTATUS loadStatus;
  final String? errorMessage;

  // ─── Computed ────────────────────────────────────────────────────────────────

  int get totalQuestions => questions.length;
  bool get isLastQuestion => currentIndex == totalQuestions - 1;
  bool get hasAnsweredCurrent => selectedAnswerIndex != null;
  int get hintsRemaining => maxHints - hintsUsed;

  TestQuestion? get currentQuestion =>
      questions.isEmpty ? null : questions[currentIndex];

  List<int> get currentEliminatedIndexes =>
      eliminatedIndexes[currentIndex] ?? [];

  int get correctCount =>
      answerStatuses.values.where((s) => s == AnswerStatus.correct).length;

  int get incorrectCount =>
      answerStatuses.values.where((s) => s == AnswerStatus.incorrect).length;

  double get progressPercent =>
      totalQuestions == 0 ? 0 : (currentIndex + 1) / totalQuestions;

  int gemsForLevel(int level) {
    return switch (level) {
      0 => 5,
      1 => 10,
      2 => 20,
      3 => 35,
      4 => 50,
      _ => 75,
    };
  }

  String get formattedTime {
    final m = remainingSeconds ~/ 60;
    final s = remainingSeconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  bool get isTimerWarning => remainingSeconds <= 60 && remainingSeconds > 0;
  bool get isTimerCritical => remainingSeconds <= 10 && remainingSeconds > 0;

  int get leveledUpCount => leveledUpWords.length;

  // ─── CopyWith ─────────────────────────────────────────────────────────────────

  TestState copyWith({
    TestPhase? phase,
    TestConfig? config,
    List<Tag>? allTags,
    List<String>? availableLanguages,
    List<TestQuestion>? questions,
    int? currentIndex,
    Object? selectedAnswerIndex = _sentinel,
    Map<int, AnswerStatus>? answerStatuses,
    int? score,
    int? remainingSeconds,
    Map<int, List<int>>? eliminatedIndexes,
    int? hintsUsed,
    int? maxHints,
    List<VocabularyEntry>? leveledUpWords,
    bool? isLevelingUp,
    int? xpEarned,
    int? gemsEarned,
    LOADSTATUS? loadStatus,
    Object? errorMessage = _sentinel,
  }) {
    return TestState(
      phase: phase ?? this.phase,
      config: config ?? this.config,
      allTags: allTags ?? this.allTags,
      availableLanguages: availableLanguages ?? this.availableLanguages,
      questions: questions ?? this.questions,
      currentIndex: currentIndex ?? this.currentIndex,
      selectedAnswerIndex: selectedAnswerIndex == _sentinel
          ? this.selectedAnswerIndex
          : selectedAnswerIndex as int?,
      answerStatuses: answerStatuses ?? this.answerStatuses,
      score: score ?? this.score,
      remainingSeconds: remainingSeconds ?? this.remainingSeconds,
      eliminatedIndexes: eliminatedIndexes ?? this.eliminatedIndexes,
      hintsUsed: hintsUsed ?? this.hintsUsed,
      maxHints: maxHints ?? this.maxHints,
      leveledUpWords: leveledUpWords ?? this.leveledUpWords,
      isLevelingUp: isLevelingUp ?? this.isLevelingUp,
      xpEarned: xpEarned ?? this.xpEarned,
      gemsEarned: gemsEarned ?? this.gemsEarned,
      loadStatus: loadStatus ?? this.loadStatus,
      errorMessage: errorMessage == _sentinel
          ? this.errorMessage
          : errorMessage as String?,
    );
  }

  @override
  List<Object?> get props => [
    phase, config, allTags, availableLanguages,
    questions, currentIndex, selectedAnswerIndex, answerStatuses,
    score, remainingSeconds, eliminatedIndexes, hintsUsed, maxHints,
    leveledUpWords, isLevelingUp, loadStatus, errorMessage,
    xpEarned, gemsEarned,
  ];
}

const _sentinel = Object();