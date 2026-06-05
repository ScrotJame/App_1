part of 'quiz_game_cubit.dart';



// ═══════════════════════════════════════════════════════════════
// QUIZ GAME STATE
// ═══════════════════════════════════════════════════════════════

class QuizGameState extends Equatable {
  const QuizGameState({
    this.loadStatus = LOADSTATUS.INITAL,
    this.quizStatus = QuizStatus.initial,
    this.questions = const [],
    this.currentIndex = 0,
    this.selectedAnswerId,
    this.correctCount = 0,
    this.wrongCount = 0,
    this.remainingSeconds = 45,
    this.errorMessage,
    this.battleAnimState = BattleAnimState.idle,
  });

  final LOADSTATUS loadStatus;
  final QuizStatus quizStatus;
  final List<QuizQuestion> questions;
  final int currentIndex;
  final String? selectedAnswerId;
  final int correctCount;
  final int wrongCount;
  final int remainingSeconds;
  final String? errorMessage;
  final BattleAnimState battleAnimState;

  // ── Computed ────────────────────────────────
  QuizQuestion? get currentQuestion =>
      currentIndex < questions.length ? questions[currentIndex] : null;

  int get totalQuestions => questions.length;

  /// 1-based cho display (e.g. "Question 4 of 12")
  int get displayIndex => currentIndex + 1;

  double get progress =>
      totalQuestions == 0 ? 0 : (currentIndex) / totalQuestions;

  bool get isAnswered => selectedAnswerId != null;

  bool get isCorrectAnswer {
    if (selectedAnswerId == null || currentQuestion == null) return false;
    return currentQuestion!.options
        .any((o) => o.id == selectedAnswerId && o.isCorrect);
  }

  String get timerDisplay {
    final minutes = (remainingSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (remainingSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  // ── copyWith ────────────────────────────────
  QuizGameState copyWith({
    LOADSTATUS? loadStatus,
    QuizStatus? quizStatus,
    List<QuizQuestion>? questions,
    int? currentIndex,
    Object? selectedAnswerId = _sentinel,
    int? correctCount,
    int? wrongCount,
    int? remainingSeconds,
    Object? errorMessage = _sentinel,
    BattleAnimState? battleAnimState,
  }) {
    return QuizGameState(
      loadStatus: loadStatus ?? this.loadStatus,
      quizStatus: quizStatus ?? this.quizStatus,
      questions: questions ?? this.questions,
      currentIndex: currentIndex ?? this.currentIndex,
      selectedAnswerId: selectedAnswerId == _sentinel
          ? this.selectedAnswerId
          : selectedAnswerId as String?,
      correctCount: correctCount ?? this.correctCount,
      wrongCount: wrongCount ?? this.wrongCount,
      remainingSeconds: remainingSeconds ?? this.remainingSeconds,
      errorMessage: errorMessage == _sentinel
          ? this.errorMessage
          : errorMessage as String?,
      battleAnimState: battleAnimState ?? this.battleAnimState,
    );
  }

  @override
  List<Object?> get props => [
        loadStatus,
        quizStatus,
        questions,
        currentIndex,
        selectedAnswerId,
        correctCount,
        wrongCount,
        remainingSeconds,
        errorMessage,
        battleAnimState,
      ];
}

const _sentinel = Object();
