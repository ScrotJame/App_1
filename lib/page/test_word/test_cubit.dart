import 'dart:async';
import 'dart:math';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:rxdart/rxdart.dart';
import 'package:test_abc/database/app_db.dart';
import 'package:test_abc/generated/l10n.dart';

import '../../commons/enums.dart';
import '../../commons/status_comon.dart';
import '../../commons/user_sesion.dart';
import '../../models/tag_vocab.dart';
import '../../repository/learning_history_repository.dart';
import '../../repository/vocabulary_repository.dart';
import '../../service/alarm_service.dart';
import '../../service/tts_service.dart';
import 'data/test_config_store.dart';
import 'logic/test_answer.dart';
import 'logic/test_config.dart';
import 'logic/test_kind_question.dart';
import 'logic/test_planner.dart';
import 'test_kind_text.dart';

export 'logic/test_answer.dart';
export 'logic/test_config.dart';
export 'logic/test_kind_question.dart';

part 'test_state.dart';

class TestCubit extends Cubit<TestState> {
  TestCubit(
    this._repo,
    this._repoHistory, {
    required TtsService tts,
    TestConfigStore? configStore,
    Random? random,
    Duration? autoAdvanceDelay = const Duration(seconds: 1),
  })  : _tts = tts,
        _configStore = configStore ?? TestConfigStore(),
        _rng = random ?? Random(),
        _autoAdvanceDelay = autoAdvanceDelay,
        super(const TestState()) {
    ready = _loadConfigData();
  }

  final VocabularyRepository _repo;
  final LearningHistoryRepository _repoHistory;
  final TtsService _tts;
  final TestConfigStore _configStore;
  final Random _rng;

  /// Wait after a correct answer before moving on. Null: wait for "next".
  final Duration? _autoAdvanceDelay;

  /// One-shot messages: toasts and warnings.
  final PublishSubject<String> messageController = PublishSubject();

  /// Completes once the config screen data and the saved setup are loaded.
  late final Future<void> ready;

  Timer? _timer;
  Timer? _autoNext;

  /// Set by every setter, so a saved setup that loads late never replaces a
  /// choice the user has already made.
  bool _configTouched = false;

  // ─── INIT ──────────────────────────────────────────────────────────────────

  Future<void> _loadConfigData() async {
    try {
      final allWords = await _repo.watchAllWordsWithTags().first;

      final tagMap = <int, Tag>{};
      for (final wt in allWords) {
        for (final t in wt.tags ?? const <Tag>[]) {
          tagMap[t.id] = t;
        }
      }
      final languages = _languagesOf(allWords).toList()..sort();
      final voices = await _voiceLanguagesFor(languages);
      final saved = await _configStore.load();
      if (isClosed) return;

      final base = !_configTouched && saved != null ? saved : state.config;
      emit(state.copyWith(
        allWords: allWords,
        allTags: tagMap.values.toList(),
        availableLanguages: languages,
        voiceLanguages: voices,
        config: base.sanitize(
          tagIds: tagMap.keys.toSet(),
          languages: languages.toSet(),
        ),
      ));
    } catch (_) {
      // Without this data the default setup still works.
    }
  }

  Set<String> _languagesOf(List<VocabularyWithTags> words) => {
        for (final w in words)
          if ((w.word.language?.trim() ?? '').isNotEmpty)
            w.word.language?.trim() ?? '',
      };

  Future<Set<String>> _voiceLanguagesFor(Iterable<String> languages) async {
    final voices = <String>{};
    for (final language in languages) {
      if (await _tts.isLanguageAvailable(language)) voices.add(language);
    }
    return voices;
  }

  /// Checks the voices again, e.g. when the user is back from installing one.
  Future<void> refreshVoices() async {
    final voices = await _voiceLanguagesFor(state.availableLanguages);
    if (isClosed) return;
    emit(state.copyWith(voiceLanguages: voices));
  }

  // ─── CONFIG SETTERS ────────────────────────────────────────────────────────

  void _updateConfig(TestConfig config) {
    _configTouched = true;
    emit(state.copyWith(
      config: config,
      loadStatus: LOADSTATUS.INITAL,
      errorMessage: null,
    ));
  }

  void toggleKind(TestKind kind) {
    final kinds = Set<TestKind>.of(state.config.kinds);
    if (kinds.contains(kind)) {
      if (kinds.length == 1) {
        messageController.add(S.current.test_kind_keep_one);
        return;
      }
      kinds.remove(kind);
    } else {
      kinds.add(kind);
    }
    _updateConfig(state.config.copyWith(kinds: kinds));
  }

  void setQuestionCount(int count) =>
      _updateConfig(state.config.copyWith(questionCount: count));

  /// Keeps the time when it is one of the new mode's options, otherwise
  /// takes the mode's default.
  void setTimerMode(TimerMode mode) {
    final cfg = state.config;
    final options = mode == TimerMode.total
        ? TestConfig.totalTimeOptions
        : TestConfig.perQuestionTimeOptions;
    final fallback = mode == TimerMode.total
        ? TestConfig.defaultTotalSeconds
        : TestConfig.defaultPerQuestionSeconds;
    final limit = options.contains(cfg.timeLimitSeconds)
        ? cfg.timeLimitSeconds
        : fallback;
    _updateConfig(cfg.copyWith(timerMode: mode, timeLimitSeconds: limit));
  }

  void setTimeLimit(int seconds) =>
      _updateConfig(state.config.copyWith(timeLimitSeconds: seconds));

  void toggleTimer(bool enabled) =>
      _updateConfig(state.config.copyWith(enableTimer: enabled));

  void setWordFilter(WordFilter filter) =>
      _updateConfig(state.config.copyWith(wordFilter: filter));

  void toggleTagFilter(int tagId) {
    final current = List<int>.from(state.config.selectedTagIds);
    if (current.contains(tagId)) {
      current.remove(tagId);
    } else {
      current.add(tagId);
    }
    _updateConfig(state.config.copyWith(selectedTagIds: current));
  }

  void setLanguageFilter(String? language) =>
      _updateConfig(state.config.copyWith(selectedLanguage: language));

  // ─── START TEST ────────────────────────────────────────────────────────────

  Future<void> startTest() async {
    await ready;
    if (isClosed) return;
    _stopTimers();
    emit(state.copyWith(loadStatus: LOADSTATUS.LOADING, errorMessage: null));
    try {
      final allWords = await _repo.watchAllWordsWithTags().first;
      final cfg = state.config;
      final pool = cfg.filterWords(allWords);
      final voices = cfg.kinds.contains(TestKind.listening)
          ? await _voiceLanguagesFor(_languagesOf(pool))
          : <String>{};

      final plan = TestPlanner.plan(
        pool: pool,
        allWords: allWords,
        kinds: cfg.kinds,
        questionCount: cfg.questionCount,
        voiceLanguages: voices,
        random: _rng,
      );
      if (isClosed) return;

      if (plan.questions.isEmpty) {
        emit(state.copyWith(
          loadStatus: LOADSTATUS.FAILED,
          errorMessage: S.current.test_not_enough_words,
        ));
        return;
      }

      await _configStore.save(cfg);
      if (isClosed) return;

      emit(state.copyWith(
        phase: TestPhase.testing,
        allWords: allWords,
        questions: plan.questions,
        currentIndex: 0,
        answers: const {},
        answerStatuses: const {},
        score: 0,
        hintsUsed: 0,
        eliminatedIndexes: const {},
        revealedChars: const {},
        leveledUpWords: const [],
        notDueCount: 0,
        xpEarned: 0,
        gemsEarned: 0,
        isLevelingUp: false,
        remainingSeconds: _secondsFor(plan.questions.first, cfg),
        loadStatus: LOADSTATUS.SUCCESS,
        errorMessage: null,
      ));

      for (final warning in plan.warnings) {
        messageController.add(_warningText(warning));
      }
      if (cfg.enableTimer) _startTimer();
    } catch (e) {
      if (isClosed) return;
      emit(state.copyWith(
        loadStatus: LOADSTATUS.FAILED,
        errorMessage: S.current.error_load_data(e.toString()),
      ));
    }
  }

  int _secondsFor(TestQuestion question, TestConfig cfg) =>
      cfg.timerMode == TimerMode.perWord
          ? cfg.perQuestionSeconds(question.kind)
          : cfg.timeLimitSeconds;

  String _warningText(TestPlanWarning warning) =>
      warning.missingVoiceLanguages.isNotEmpty
          ? S.current
              .test_warning_no_voice(warning.missingVoiceLanguages.join(', '))
          : S.current.test_warning_kind_dropped(warning.kind.title);

  // ─── ANSWER ────────────────────────────────────────────────────────────────

  void submitAnswer(TestAnswer answer) {
    if (state.phase != TestPhase.testing || state.isLevelingUp) return;
    if (state.hasAnsweredCurrent) return;
    final question = state.currentQuestion;
    if (question == null) return;

    final isCorrect = question.grade(answer);
    emit(state.copyWith(
      answers: {...state.answers, state.currentIndex: answer},
      answerStatuses: {
        ...state.answerStatuses,
        state.currentIndex:
            isCorrect ? AnswerStatus.correct : AnswerStatus.incorrect,
      },
      score: state.score + (isCorrect ? 10 : 0),
    ));

    if (state.config.timerMode == TimerMode.perWord) _stopTimer();

    final delay = _autoAdvanceDelay;
    if (isCorrect && delay != null) {
      _autoNext?.cancel();
      _autoNext = Timer(delay, nextQuestion);
    }
  }

  // ─── NAVIGATION ────────────────────────────────────────────────────────────

  void nextQuestion() {
    _autoNext?.cancel();
    _autoNext = null;
    if (state.phase != TestPhase.testing || state.isLevelingUp) return;
    if (!state.hasAnsweredCurrent) return;

    if (state.isLastQuestion) {
      _stopTimer();
      _finishTest();
      return;
    }

    final cfg = state.config;
    final next = state.questions[state.currentIndex + 1];
    final perQuestion = cfg.timerMode == TimerMode.perWord;
    emit(state.copyWith(
      currentIndex: state.currentIndex + 1,
      remainingSeconds:
          perQuestion ? _secondsFor(next, cfg) : state.remainingSeconds,
    ));

    if (cfg.enableTimer && perQuestion) _startTimer();
  }

  // ─────────────────────────────────────────────────────────────────────────
  // FINISH → LEVEL UP
  // Một câu đúng chỉ +1 level khi từ đã đến hạn ôn; câu sai tính lại thời
  // gian chờ. Level, status và totalLearned đều do repository ghi.
  // Phần thưởng chỉ tính trên các từ vừa lên level.
  // ─────────────────────────────────────────────────────────────────────────

  Future<void> _finishTest() async {
    // The timer running out and a tap on "next" can both end the test. Only
    // the first one may write levels and history.
    if (state.phase != TestPhase.testing || state.isLevelingUp) return;
    _stopTimers();
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
      final vocabEntry = state.questions[entry.key].entry;

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

    try {
      for (final entry in state.answerStatuses.entries) {
        final vocabEntry = state.questions[entry.key].entry;
        // Also bumps the word's correct/wrong counter.
        await _repoHistory.recordAnswer(
          userKey: userKey,
          wordId: vocabEntry.id,
          wordLevelSnapshot: vocabEntry.level,
          sessionType: SessionType.test,
          isCorrect: entry.value == AnswerStatus.correct,
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

  // ─── HINT ──────────────────────────────────────────────────────────────────

  void useHint() {
    if (!state.canUseHint) return;
    final question = state.currentQuestion;
    switch (question) {
      case final MultipleChoiceQuestion q:
        final eliminated = List<int>.of(state.currentEliminatedIndexes);
        final wrong = [
          for (var i = 0; i < q.choices.length; i++)
            if (i != q.correctIndex && !eliminated.contains(i)) i,
        ]..shuffle(_rng);
        if (wrong.isEmpty) return;
        eliminated.add(wrong.first);
        emit(state.copyWith(
          eliminatedIndexes: {
            ...state.eliminatedIndexes,
            state.currentIndex: eliminated,
          },
          hintsUsed: state.hintsUsed + 1,
        ));
      case TypingQuestion():
        emit(state.copyWith(
          revealedChars: {
            ...state.revealedChars,
            state.currentIndex: state.currentRevealedChars + 1,
          },
          hintsUsed: state.hintsUsed + 1,
        ));
      case TrueFalseQuestion():
      case null:
        return;
    }
  }

  // ─── RESET / RETRY ─────────────────────────────────────────────────────────

  void goToConfig() {
    _stopTimers();
    emit(state.copyWith(
      phase: TestPhase.config,
      questions: const [],
      currentIndex: 0,
      answers: const {},
      answerStatuses: const {},
      score: 0,
      eliminatedIndexes: const {},
      revealedChars: const {},
      hintsUsed: 0,
      leveledUpWords: const [],
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
    _stopTimers();
    await startTest();
  }

  // ─── TIMER ─────────────────────────────────────────────────────────────────

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
      // Counts as wrong; the user reads the answer, then taps "next".
      if (!state.hasAnsweredCurrent) submitAnswer(const TimedOut());
    } else {
      _finishTest();
    }
  }

  void _stopTimer() {
    _timer?.cancel();
    _timer = null;
  }

  void _stopTimers() {
    _stopTimer();
    _autoNext?.cancel();
    _autoNext = null;
  }

  @override
  Future<void> close() {
    _stopTimers();
    messageController.close();
    return super.close();
  }
}
