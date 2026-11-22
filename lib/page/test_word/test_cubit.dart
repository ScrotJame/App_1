import 'dart:async';
import 'dart:math';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:test_abc/database/app_db.dart';

import '../../commons/enums.dart';
import '../../commons/status_comon.dart';
import '../../commons/user_sesion.dart';
import '../../models/tag_vocab.dart';
import '../../repository/vocabulary_repository.dart';
import '../../repository/learning_history_repository.dart';
import '../../service/alarm_service.dart';
import 'package:test_abc/generated/l10n.dart';

import 'logic/test_config.dart';

export 'logic/test_config.dart';

part 'test_state.dart';

class TestCubit extends Cubit<TestState> {
  final VocabularyRepository _repo;
  final LearningHistoryRepository _repoHistory;
  Timer? _timer;
  final _rng = Random();

  TestCubit(this._repo, this._repoHistory) : super(const TestState()) {
    _loadConfigData();
  }

  String get currentWord => "";

  // ─────────────────────────────────────────────────────────────────────────────
  // INIT — tải tags + ngôn ngữ để hiện ở màn Config
  // ─────────────────────────────────────────────────────────────────────────────

  Future<void> _loadConfigData() async {
    try {
      final allWords = await _repo.watchAllWordsWithTags().first;

      final tagMap = <int, Tag>{};
      for (final wt in allWords) {
        for (final t in wt.tags ?? []) {
          tagMap[t.id] = t;
        }
      }

      final langs = allWords
          .map((w) => w.word.language)
          .where((l) => l != null && l.isNotEmpty)
          .toSet()
          .cast<String>()
          .toList()
        ..sort();

      emit(state.copyWith(
        allTags: tagMap.values.toList(),
        availableLanguages: langs,
      ));
    } catch (_) {
      // Config data load lỗi không critical, bỏ qua
    }
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // CONFIG SETTERS
  // ─────────────────────────────────────────────────────────────────────────────

  void setQuestionCount(int count) =>
      emit(state.copyWith(config: state.config.copyWith(questionCount: count)));

  void setTimerMode(TimerMode mode) =>
      emit(state.copyWith(config: state.config.copyWith(timerMode: mode)));

  void setTimeLimit(int seconds) =>
      emit(state.copyWith(
          config: state.config.copyWith(timeLimitSeconds: seconds)));

  void toggleTimer(bool enabled) =>
      emit(state.copyWith(
          config: state.config.copyWith(enableTimer: enabled)));

  void setWordFilter(WordFilter filter) =>
      emit(state.copyWith(
          config: state.config.copyWith(wordFilter: filter)));

  void toggleTagFilter(int tagId) {
    final current = List<int>.from(state.config.selectedTagIds);
    if (current.contains(tagId)) {
      current.remove(tagId);
    } else {
      current.add(tagId);
    }
    emit(state.copyWith(
        config: state.config.copyWith(selectedTagIds: current)));
  }

  void setLanguageFilter(String? language) =>
      emit(state.copyWith(
          config: state.config.copyWith(selectedLanguage: language)));

  // ─────────────────────────────────────────────────────────────────────────────
  // START TEST
  // ─────────────────────────────────────────────────────────────────────────────

  Future<void> startTest() async {
    emit(state.copyWith(loadStatus: LOADSTATUS.LOADING));
    try {
      final allWords = await _repo.watchAllWordsWithTags().first;
      final cfg = state.config;

      final pool = cfg.filterWords(allWords);

      if (pool.length < 4) {
        emit(state.copyWith(
          loadStatus: LOADSTATUS.FAILED,
          errorMessage: S.current.test_not_enough_words,
        ));
        return;
      }

      final shuffled = List<VocabularyWithTags>.from(pool)..shuffle(_rng);
      final count = min(cfg.questionCount, pool.length);
      final selected = shuffled.take(count).toList();

      final questions = selected.map((w) => _buildQuestion(w, allWords, cfg)).toList();

      emit(state.copyWith(
        phase: TestPhase.testing,
        questions: questions,
        currentIndex: 0,
        selectedAnswerIndex: null,
        answerStatuses: {},
        score: 0,
        hintsUsed: 0,
        eliminatedIndexes: {},
        leveledUpWords: [],
        notDueCount: 0,
        xpEarned: 0,
        gemsEarned: 0,
        isLevelingUp: false,
        remainingSeconds: cfg.timeLimitSeconds,
        loadStatus: LOADSTATUS.SUCCESS,
        errorMessage: null,
      ));

      if (cfg.enableTimer) _startTimer();
    } catch (e) {
      emit(state.copyWith(
        loadStatus: LOADSTATUS.FAILED,
        errorMessage: S.current.error_load_data(e.toString()),
      ));
    }
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // BUILD QUESTION
  // ─────────────────────────────────────────────────────────────────────────────

  TestQuestion _buildQuestion(
      VocabularyWithTags word,
      List<VocabularyWithTags> allWords,
      TestConfig cfg,
      ) {
    final actualType = _rng.nextBool()
        ? QuestionType.wordToMeaning
        : QuestionType.meaningToWord;

    final correctAnswer = actualType == QuestionType.wordToMeaning
        ? word.word.meaning
        : word.word.word;

    final others = allWords.where((w) => w.word.id != word.word.id).toList()
      ..shuffle(_rng);

    final distractors = others
        .take(3)
        .map((w) => actualType == QuestionType.wordToMeaning
        ? w.word.meaning
        : w.word.word)
        .toList();

    final allChoices = [correctAnswer, ...distractors]..shuffle(_rng);
    final correctIndex = allChoices.indexOf(correctAnswer);

    return TestQuestion(
      word: word,
      questionType: actualType,
      choices: allChoices,
      correctIndex: correctIndex,
    );
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // ANSWER
  // ─────────────────────────────────────────────────────────────────────────────

  void selectAnswer(int choiceIndex) {
    if (state.phase != TestPhase.testing || state.isLevelingUp) return;
    if (state.hasAnsweredCurrent) return;
    final question = state.currentQuestion;
    if (question == null) return;

    final isCorrect = choiceIndex == question.correctIndex;
    final newStatuses = Map<int, AnswerStatus>.from(state.answerStatuses)
      ..[state.currentIndex] =
      isCorrect ? AnswerStatus.correct : AnswerStatus.incorrect;

    emit(state.copyWith(
      selectedAnswerIndex: choiceIndex,
      answerStatuses: newStatuses,
      score: state.score + (isCorrect ? 10 : 0),
    ));

    if (state.config.timerMode == TimerMode.perWord) _stopTimer();
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // NAVIGATION
  // ─────────────────────────────────────────────────────────────────────────────

  void nextQuestion() {
    if (state.phase != TestPhase.testing || state.isLevelingUp) return;
    if (!state.hasAnsweredCurrent) return;

    if (state.isLastQuestion) {
      _stopTimer();
      _finishTest();
      return;
    }

    emit(state.copyWith(
      currentIndex: state.currentIndex + 1,
      selectedAnswerIndex: null,
      remainingSeconds: state.config.timerMode == TimerMode.perWord
          ? state.config.timeLimitSeconds
          : state.remainingSeconds,
    ));

    if (state.config.enableTimer &&
        state.config.timerMode == TimerMode.perWord) {
      _startTimer();
    }
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // FINISH → LEVEL UP
  // Một câu đúng chỉ +1 level khi từ đã đến hạn ôn; câu sai tính lại thời
  // gian chờ. Level, status và totalLearned đều do repository ghi.
  // Phần thưởng chỉ tính trên các từ vừa lên level.
  // ─────────────────────────────────────────────────────────────────────────────

  Future<void> _finishTest() async {
    // The timer running out and a tap on "next" can both end the test. Only
    // the first one may write levels and history.
    if (state.phase != TestPhase.testing || state.isLevelingUp) return;
    _stopTimer();
    emit(state.copyWith(isLevelingUp: true));

    final userKey = UserSession.instance.userKey;

    if (userKey.isEmpty) {
      // Without a user nothing can be saved, but the score is still shown.
      emit(state.copyWith(
        phase: TestPhase.result,
        leveledUpWords: const [],
        notDueCount: 0,
        xpEarned: 0,
        gemsEarned: 0,
        isLevelingUp: false,
      ));
      return;
    }

    final leveledUpWords = <VocabularyEntry>[];
    int notDueCount = 0;

    for (final entry in state.answerStatuses.entries) {
      final vocabEntry = state.questions[entry.key].word.word;

      try {
        if (entry.value == AnswerStatus.correct) {
          final change = await _repo.levelUpIfDue(vocabEntry.id, userKey);
          if (change == null) continue;
          if (change.leveledUp) {
            leveledUpWords.add(change.word);
          } else {
            notDueCount++;
          }
        } else {
          await _repo.restartReviewWait(vocabEntry.id, userKey);
        }
      } catch (_) {
        // Một từ lỗi không được chặn các từ còn lại.
      }
    }

    await AlarmService.syncReviewReminder(_repo);

    // ── Ghi log lịch sử học (Test) ──────────────────────────────────────────
    try {
      for (final entry in state.answerStatuses.entries) {
        final vocabEntry = state.questions[entry.key].word.word;
        final isCorrect = entry.value == AnswerStatus.correct;

        // Also bumps the word's correct/wrong counter.
        await _repoHistory.recordAnswer(
          userKey: userKey,
          wordId: vocabEntry.id,
          wordLevelSnapshot: vocabEntry.level,
          sessionType: SessionType.test,
          isCorrect: isCorrect,
        );
      }
    } catch (_) {
      // Không block flow chính nếu log history thất bại
    }

    if (isClosed) return;

    // Each entry holds the level the word has just reached.
    final xpEarned = leveledUpWords.fold<int>(
        0, (sum, word) => sum + TestState.xpForLevel(word.level));
    final gemsEarned = leveledUpWords.fold<int>(
        0, (sum, word) => sum + TestState.gemsForLevel(word.level));

    emit(state.copyWith(
      phase: TestPhase.result,
      leveledUpWords: leveledUpWords,
      notDueCount: notDueCount,
      xpEarned: xpEarned,
      gemsEarned: gemsEarned,
      isLevelingUp: false,
    ));
  }
  // ─────────────────────────────────────────────────────────────────────────────
  // HINT
  // ─────────────────────────────────────────────────────────────────────────────

  void useHint() {
    if (state.hintsRemaining <= 0 || state.hasAnsweredCurrent) return;
    final question = state.currentQuestion;
    if (question == null) return;

    final eliminated = List<int>.from(state.currentEliminatedIndexes);
    final wrongIndexes = List.generate(question.choices.length, (i) => i)
        .where((i) =>
    i != question.correctIndex && !eliminated.contains(i))
        .toList()
      ..shuffle(_rng);

    if (wrongIndexes.isEmpty) return;
    eliminated.add(wrongIndexes.first);

    final newEliminated = Map<int, List<int>>.from(state.eliminatedIndexes)
      ..[state.currentIndex] = eliminated;

    emit(state.copyWith(
      eliminatedIndexes: newEliminated,
      hintsUsed: state.hintsUsed + 1,
    ));
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // RESET / RETRY
  // ─────────────────────────────────────────────────────────────────────────────

  void goToConfig() {
    _stopTimer();
    emit(state.copyWith(
      phase: TestPhase.config,
      questions: [],
      currentIndex: 0,
      selectedAnswerIndex: null,
      answerStatuses: {},
      score: 0,
      eliminatedIndexes: {},
      hintsUsed: 0,
      leveledUpWords: [],
      notDueCount: 0,
      xpEarned: 0,
      gemsEarned: 0,
      isLevelingUp: false,
      remainingSeconds: state.config.timeLimitSeconds,
      loadStatus: LOADSTATUS.INITAL,
      errorMessage: null,
    ));
  }

  Future<void> retryTest() async {
    _stopTimer();
    await startTest();
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // TIMER
  // ─────────────────────────────────────────────────────────────────────────────

  void _startTimer() {
    _stopTimer();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _onTick());
  }

  void _onTick() {
    if (state.phase != TestPhase.testing || state.isLevelingUp) {
      _stopTimer();
      return;
    }
    if (state.remainingSeconds <= 0) {
      _stopTimer();
      _onTimeUp();
      return;
    }
    emit(state.copyWith(remainingSeconds: state.remainingSeconds - 1));
  }

  void _onTimeUp() {
    if (state.config.timerMode == TimerMode.perWord) {
      final newStatuses = Map<int, AnswerStatus>.from(state.answerStatuses)
        ..[state.currentIndex] = AnswerStatus.incorrect;

      if (state.isLastQuestion) {
        emit(state.copyWith(answerStatuses: newStatuses));
        _finishTest();
      } else {
        emit(state.copyWith(
          answerStatuses: newStatuses,
          currentIndex: state.currentIndex + 1,
          selectedAnswerIndex: null,
          remainingSeconds: state.config.timeLimitSeconds,
        ));
        _startTimer();
      }
    } else {
      _finishTest();
    }
  }

  void _stopTimer() {
    _timer?.cancel();
    _timer = null;
  }

  @override
  Future<void> close() {
    _stopTimer();
    return super.close();
  }
}