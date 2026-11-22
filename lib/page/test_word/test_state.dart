part of 'test_cubit.dart';

class TestState extends Equatable {
  const TestState({
    this.phase = TestPhase.config,
    this.config = const TestConfig(),

    // Config screen data.
    this.allWords = const [],
    this.allTags = const [],
    this.availableLanguages = const [],
    this.voiceLanguages = const {},

    // Questions and answers.
    this.questions = const [],
    this.currentIndex = 0,
    this.answers = const {},
    this.answerStatuses = const {},
    this.score = 0,
    this.remainingSeconds = 0,

    // Hints.
    this.eliminatedIndexes = const {},
    this.revealedChars = const {},
    this.hintsUsed = 0,
    this.maxHints = 3,

    // Result. leveledUpWords holds each word as stored after it levelled up.
    this.leveledUpWords = const [],
    this.notDueCount = 0,
    this.isLevelingUp = false,
    this.xpEarned = 0,
    this.gemsEarned = 0,

    this.loadStatus = LOADSTATUS.INITAL,
    this.errorMessage,
  });

  final TestPhase phase;
  final TestConfig config;

  /// Every word of the user, for the "N words match" counter.
  final List<VocabularyWithTags> allWords;
  final List<Tag> allTags;
  final List<String> availableLanguages;

  /// Languages the device has a TTS voice for.
  final Set<String> voiceLanguages;

  final List<TestQuestion> questions;
  final int currentIndex;

  /// Answers by question index.
  final Map<int, TestAnswer> answers;
  final Map<int, AnswerStatus> answerStatuses;
  final int score;
  final int remainingSeconds;

  /// Choices removed by hints, by question index.
  final Map<int, List<int>> eliminatedIndexes;

  /// Characters shown by hints on typing questions, by question index.
  final Map<int, int> revealedChars;
  final int hintsUsed;
  final int maxHints;

  final List<VocabularyEntry> leveledUpWords;

  /// Correct answers on words that were not due, so the level stayed.
  final int notDueCount;
  final bool isLevelingUp;
  final int xpEarned;
  final int gemsEarned;

  final LOADSTATUS loadStatus;
  final String? errorMessage;

  // ─── Computed ──────────────────────────────────────────────────────────────

  int get totalQuestions => questions.length;
  bool get isLastQuestion => currentIndex == totalQuestions - 1;

  TestQuestion? get currentQuestion =>
      questions.isEmpty ? null : questions[currentIndex];

  TestAnswer? get currentAnswer => answers[currentIndex];
  bool get hasAnsweredCurrent => answers.containsKey(currentIndex);
  bool get isCurrentCorrect =>
      answerStatuses[currentIndex] == AnswerStatus.correct;

  int get hintsRemaining => maxHints - hintsUsed;
  List<int> get currentEliminatedIndexes =>
      eliminatedIndexes[currentIndex] ?? const [];
  int get currentRevealedChars => revealedChars[currentIndex] ?? 0;

  /// Whether the hint button does something on the current question.
  bool get canUseHint {
    if (hintsRemaining <= 0 || hasAnsweredCurrent) return false;
    return switch (currentQuestion) {
      final MultipleChoiceQuestion q =>
        q.choices.length - 1 - currentEliminatedIndexes.length > 0,
      final TypingQuestion q => currentRevealedChars < q.hintLength,
      TrueFalseQuestion() => false,
      null => false,
    };
  }

  int get correctCount =>
      answerStatuses.values.where((s) => s == AnswerStatus.correct).length;

  int get incorrectCount =>
      answerStatuses.values.where((s) => s == AnswerStatus.incorrect).length;

  double get progressPercent =>
      totalQuestions == 0 ? 0 : (currentIndex + 1) / totalQuestions;

  int get matchingWordCount => config.filterWords(allWords).length;

  /// Questions the start button announces. The test can have fewer when
  /// some words cannot be used for the selected kinds.
  int get plannedQuestionCount => min(config.questionCount, matchingWordCount);

  /// Whether a word in the current scope can be read aloud.
  bool get hasVoiceForScope => config
      .filterWords(allWords)
      .any((w) => voiceLanguages.contains(w.word.language));

  /// Correct and total answers by kind, for the kinds in this test.
  Map<TestKind, ({int correct, int total})> get kindStats {
    final stats = <TestKind, ({int correct, int total})>{};
    for (var i = 0; i < questions.length; i++) {
      final kind = questions[i].kind;
      final before = stats[kind] ?? (correct: 0, total: 0);
      final right = answerStatuses[i] == AnswerStatus.correct ? 1 : 0;
      stats[kind] = (correct: before.correct + right, total: before.total + 1);
    }
    return stats;
  }

  /// Gems paid for a word that reached [level] in this test.
  static int gemsForLevel(int level) {
    return switch (level) {
      0 => 5,
      1 => 10,
      2 => 20,
      3 => 35,
      4 => 50,
      _ => 75,
    };
  }

  /// XP paid for a word that reached [level] in this test. It has its own
  /// scale: XP feeds the user's level, gems are the shop currency.
  static int xpForLevel(int level) {
    return switch (level) {
      0 => 5,
      1 => 5,
      2 => 10,
      3 => 15,
      4 => 25,
      _ => 40,
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

  // ─── CopyWith ──────────────────────────────────────────────────────────────

  TestState copyWith({
    TestPhase? phase,
    TestConfig? config,
    List<VocabularyWithTags>? allWords,
    List<Tag>? allTags,
    List<String>? availableLanguages,
    Set<String>? voiceLanguages,
    List<TestQuestion>? questions,
    int? currentIndex,
    Map<int, TestAnswer>? answers,
    Map<int, AnswerStatus>? answerStatuses,
    int? score,
    int? remainingSeconds,
    Map<int, List<int>>? eliminatedIndexes,
    Map<int, int>? revealedChars,
    int? hintsUsed,
    int? maxHints,
    List<VocabularyEntry>? leveledUpWords,
    int? notDueCount,
    bool? isLevelingUp,
    int? xpEarned,
    int? gemsEarned,
    LOADSTATUS? loadStatus,
    Object? errorMessage = _sentinel,
  }) {
    return TestState(
      phase: phase ?? this.phase,
      config: config ?? this.config,
      allWords: allWords ?? this.allWords,
      allTags: allTags ?? this.allTags,
      availableLanguages: availableLanguages ?? this.availableLanguages,
      voiceLanguages: voiceLanguages ?? this.voiceLanguages,
      questions: questions ?? this.questions,
      currentIndex: currentIndex ?? this.currentIndex,
      answers: answers ?? this.answers,
      answerStatuses: answerStatuses ?? this.answerStatuses,
      score: score ?? this.score,
      remainingSeconds: remainingSeconds ?? this.remainingSeconds,
      eliminatedIndexes: eliminatedIndexes ?? this.eliminatedIndexes,
      revealedChars: revealedChars ?? this.revealedChars,
      hintsUsed: hintsUsed ?? this.hintsUsed,
      maxHints: maxHints ?? this.maxHints,
      leveledUpWords: leveledUpWords ?? this.leveledUpWords,
      notDueCount: notDueCount ?? this.notDueCount,
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
        phase, config, allWords, allTags, availableLanguages, voiceLanguages,
        questions, currentIndex, answers, answerStatuses, score,
        remainingSeconds, eliminatedIndexes, revealedChars, hintsUsed,
        maxHints, leveledUpWords, notDueCount, isLevelingUp, xpEarned,
        gemsEarned, loadStatus, errorMessage,
      ];
}

const _sentinel = Object();
