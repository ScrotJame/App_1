part of 'daily_review_cubit.dart';

enum DailyReviewPhase { loading, empty, intro, testing, result }

enum DailyReviewMode { official, practice }

/// A word whose level changed in the official run.
class DailyReviewWordChange extends Equatable {
  const DailyReviewWordChange({
    required this.wordId,
    required this.word,
    required this.meaning,
    required this.before,
    required this.after,
  });

  final int wordId;
  final String word;
  final String meaning;
  final int before;
  final int after;

  bool get isUp => after > before;

  @override
  List<Object?> get props => [wordId, word, meaning, before, after];
}

class DailyReviewState extends Equatable {
  const DailyReviewState({
    this.phase = DailyReviewPhase.loading,
    this.mode = DailyReviewMode.official,
    this.loadStatus = LOADSTATUS.INITAL,
    this.session,
    this.preset = DailyTarget.defaultPreset,
    this.questions = const [],
    this.currentIndex = 0,
    this.selectedAnswerIndex,
    this.practiceAnswers = const {},
    this.isSubmitting = false,
    this.wordChanges = const [],
    this.reward = DailyReviewRewardBreakdown.none,
  });

  final DailyReviewPhase phase;
  final DailyReviewMode mode;
  final LOADSTATUS loadStatus;

  /// Today's review. Null before loading and on the empty screen.
  final DailyReviewSession? session;

  /// The preset the user has chosen (applies from the next review).
  final int preset;
  final List<DailyReviewQuestion> questions;
  final int currentIndex;
  final int? selectedAnswerIndex;

  /// Answers of a practice run, by word id. Never stored.
  final Map<int, bool> practiceAnswers;
  final bool isSubmitting;
  final List<DailyReviewWordChange> wordChanges;
  final DailyReviewRewardBreakdown reward;

  DailyReviewQuestion? get currentQuestion =>
      currentIndex < questions.length ? questions[currentIndex] : null;

  bool get hasAnsweredCurrent => selectedAnswerIndex != null;

  bool get isLastQuestion => currentIndex >= questions.length - 1;

  bool get isPractice => mode == DailyReviewMode.practice;

  double get progress => questions.isEmpty
      ? 0
      : (currentIndex + (hasAnsweredCurrent ? 1 : 0)) / questions.length;

  int get resultCorrect => isPractice
      ? practiceAnswers.values.where((isCorrect) => isCorrect).length
      : (session?.correctCount ?? 0);

  int get resultTotal =>
      isPractice ? practiceAnswers.length : (session?.answeredCount ?? 0);

  List<DailyReviewWordChange> get leveledUp =>
      wordChanges.where((change) => change.isUp).toList();

  List<DailyReviewWordChange> get leveledDown =>
      wordChanges.where((change) => !change.isUp).toList();

  DailyReviewState copyWith({
    DailyReviewPhase? phase,
    DailyReviewMode? mode,
    LOADSTATUS? loadStatus,
    Object? session = _sentinel,
    int? preset,
    List<DailyReviewQuestion>? questions,
    int? currentIndex,
    Object? selectedAnswerIndex = _sentinel,
    Map<int, bool>? practiceAnswers,
    bool? isSubmitting,
    List<DailyReviewWordChange>? wordChanges,
    DailyReviewRewardBreakdown? reward,
  }) {
    return DailyReviewState(
      phase: phase ?? this.phase,
      mode: mode ?? this.mode,
      loadStatus: loadStatus ?? this.loadStatus,
      session: session == _sentinel
          ? this.session
          : session as DailyReviewSession?,
      preset: preset ?? this.preset,
      questions: questions ?? this.questions,
      currentIndex: currentIndex ?? this.currentIndex,
      selectedAnswerIndex: selectedAnswerIndex == _sentinel
          ? this.selectedAnswerIndex
          : selectedAnswerIndex as int?,
      practiceAnswers: practiceAnswers ?? this.practiceAnswers,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      wordChanges: wordChanges ?? this.wordChanges,
      reward: reward ?? this.reward,
    );
  }

  @override
  List<Object?> get props => [
        phase,
        mode,
        loadStatus,
        session,
        preset,
        questions,
        currentIndex,
        selectedAnswerIndex,
        practiceAnswers,
        isSubmitting,
        wordChanges,
        reward,
      ];
}

const _sentinel = Object();
