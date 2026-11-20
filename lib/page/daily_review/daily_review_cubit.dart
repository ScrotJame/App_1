import 'dart:async';
import 'dart:math';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:rxdart/rxdart.dart';
import 'package:test_abc/generated/l10n.dart';

import '../../commons/enums.dart';
import '../../commons/status_comon.dart';
import '../../commons/user_sesion.dart';
import '../../database/app_db.dart';
import '../../repository/learning_history_repository.dart';
import '../../repository/vocabulary_repository.dart';
import '../../service/alarm_service.dart';
import '../daily_quest/daily_quest_cubit.dart';
import '../daily_quest/models/daily_quest_model.dart';
import '../widgets/avatar/xp_cubit.dart';
import 'data/daily_review_repository.dart';
import 'data/daily_review_session.dart';
import 'logic/daily_review_question.dart';
import 'logic/daily_review_rewards.dart';
import 'logic/daily_target.dart';

part 'daily_review_state.dart';

class DailyReviewCubit extends Cubit<DailyReviewState> {
  DailyReviewCubit(
    this._reviews,
    this._vocabulary,
    this._history,
    this._xpCubit,
    this._questCubit, {
    Random? random,
  })  : _random = random ?? Random(),
        super(const DailyReviewState());

  final DailyReviewRepository _reviews;
  final IVocabularyRepository _vocabulary;
  final ILearningHistoryRepository _history;
  final XpCubit _xpCubit;
  final DailyQuestCubit _questCubit;
  final Random _random;

  /// One-shot messages: toasts and errors.
  final PublishSubject<String> messageController = PublishSubject();

  /// Partly saved answers by word id, so a retry never grades a word twice.
  final Map<int, _Attempt> _attempts = {};

  String get _userKey => UserSession.instance.userKey;

  // ── Load ──────────────────────────────────────────────────────────────────

  Future<void> load() async {
    emit(state.copyWith(
      phase: DailyReviewPhase.loading,
      loadStatus: LOADSTATUS.LOADING,
    ));
    try {
      final userKey = _userKey;
      final preset = await _reviews.readPreset(userKey);
      var session = await _reviews.openToday(userKey);
      if (session != null && session.allAnswered && !session.isCompleted) {
        // The app was closed after the last answer, before the review closed.
        session = await _reviews.complete(userKey, session);
      }
      if (session != null) session = await _grantRewardIfNeeded(session);
      final words = session == null
          ? const <VocabularyEntry>[]
          : await _vocabulary.getAllWords();
      if (isClosed) return;

      if (session == null) {
        emit(state.copyWith(
          phase: DailyReviewPhase.empty,
          loadStatus: LOADSTATUS.SUCCESS,
          preset: preset,
          session: null,
        ));
        return;
      }
      emit(state.copyWith(
        phase: DailyReviewPhase.intro,
        mode: DailyReviewMode.official,
        loadStatus: LOADSTATUS.SUCCESS,
        preset: preset,
        session: session,
        wordChanges: _wordChanges(session, words),
        reward: DailyReviewRewards.of(session),
        isSubmitting: false,
      ));
    } catch (e) {
      if (isClosed) return;
      emit(state.copyWith(loadStatus: LOADSTATUS.FAILED));
      messageController.add(S.current.error_load_data(e.toString()));
    }
  }

  // ── Start ─────────────────────────────────────────────────────────────────

  /// Starts or resumes the official run at the first open question.
  Future<void> start() async {
    final session = state.session;
    if (session == null || session.isCompleted || state.isSubmitting) return;
    await _startRound(session, DailyReviewMode.official);
  }

  /// Runs today's words again. Writes nothing and pays nothing.
  Future<void> practice() async {
    final session = state.session;
    if (session == null || !session.isCompleted || state.isSubmitting) return;
    await _startRound(session, DailyReviewMode.practice);
  }

  Future<void> _startRound(
      DailyReviewSession session, DailyReviewMode mode) async {
    emit(state.copyWith(isSubmitting: true));
    try {
      final words = await _vocabulary.getAllWords();
      final byId = {for (final word in words) word.id: word};
      final questions = <DailyReviewQuestion>[];
      for (final id in session.wordIds) {
        final word = byId[id];
        if (word != null) {
          questions.add(DailyReviewQuestion.build(word, words, _random));
        }
      }
      if (isClosed) return;

      final firstOpen = mode == DailyReviewMode.official
          ? questions.indexWhere((q) => !session.answers.containsKey(q.word.id))
          : 0;
      if (questions.isEmpty || firstOpen < 0) {
        // Words were deleted, or nothing is left to answer: reopen the review.
        emit(state.copyWith(isSubmitting: false));
        await load();
        return;
      }

      emit(state.copyWith(
        phase: DailyReviewPhase.testing,
        mode: mode,
        questions: questions,
        currentIndex: firstOpen,
        selectedAnswerIndex: null,
        practiceAnswers: const {},
        isSubmitting: false,
      ));
    } catch (e) {
      if (isClosed) return;
      emit(state.copyWith(isSubmitting: false));
      messageController.add(S.current.error_load_data(e.toString()));
    }
  }

  // ── Answer ────────────────────────────────────────────────────────────────

  Future<void> selectAnswer(int index) async {
    if (state.phase != DailyReviewPhase.testing ||
        state.isSubmitting ||
        state.hasAnsweredCurrent) {
      return;
    }
    final question = state.currentQuestion;
    if (question == null) return;
    final isCorrect = index == question.correctIndex;
    final wordId = question.word.id;

    if (state.isPractice) {
      emit(state.copyWith(
        selectedAnswerIndex: index,
        practiceAnswers: {...state.practiceAnswers, wordId: isCorrect},
      ));
      return;
    }

    final session = state.session;
    // A word already in the review is never graded again.
    if (session == null || session.answers.containsKey(wordId)) return;
    emit(state.copyWith(selectedAnswerIndex: index, isSubmitting: true));
    try {
      final userKey = _userKey;
      // A word is graded once. If an earlier attempt got past a step, that
      // step is never repeated; a retry only finishes the missing ones.
      final attempt =
          _attempts.putIfAbsent(wordId, () => _Attempt(isCorrect, index));
      // Database first (level, then log), SharedPreferences last.
      if (attempt.step == null) {
        final change = attempt.isCorrect
            ? await _vocabulary.levelUpIfDue(wordId, userKey)
            : await _vocabulary.levelDown(wordId, userKey);
        attempt.step = LevelStep(
          change?.previousLevel ?? question.word.level,
          change?.word.level ?? question.word.level,
        );
      }
      final step = attempt.step!;
      if (!attempt.logged) {
        await _history.recordAnswer(
          userKey: userKey,
          wordId: wordId,
          wordLevelSnapshot: step.before,
          sessionType: SessionType.dailyReview,
          isCorrect: attempt.isCorrect,
        );
        attempt.logged = true;
      }
      final next = await _reviews.saveAnswer(
        userKey,
        session,
        wordId: wordId,
        isCorrect: attempt.isCorrect,
        level: step,
      );
      _attempts.remove(wordId);
      if (isClosed) return;
      // The graded choice is the first tap's, even on a retry.
      emit(state.copyWith(
        session: next,
        selectedAnswerIndex: attempt.choiceIndex,
        isSubmitting: false,
      ));
    } catch (e) {
      if (isClosed) return;
      emit(state.copyWith(selectedAnswerIndex: null, isSubmitting: false));
      messageController.add(S.current.daily_review_save_failed(e.toString()));
    }
  }

  Future<void> next() async {
    if (state.phase != DailyReviewPhase.testing ||
        state.isSubmitting ||
        !state.hasAnsweredCurrent) {
      return;
    }
    final nextIndex = _nextQuestionIndex();
    if (nextIndex != null) {
      emit(state.copyWith(
        currentIndex: nextIndex,
        selectedAnswerIndex: null,
      ));
      return;
    }
    if (state.isPractice) {
      emit(state.copyWith(phase: DailyReviewPhase.result));
      return;
    }
    await _finishOfficial();
  }

  /// The next question to ask, or null at the end. The official run skips
  /// words the review already has an answer for.
  int? _nextQuestionIndex() {
    final answers =
        state.isPractice ? const <int, bool>{} : state.session?.answers;
    for (var i = state.currentIndex + 1; i < state.questions.length; i++) {
      if (!(answers?.containsKey(state.questions[i].word.id) ?? false)) {
        return i;
      }
    }
    return null;
  }

  Future<void> _finishOfficial() async {
    final session = state.session;
    if (session == null) return;
    emit(state.copyWith(isSubmitting: true));
    try {
      final userKey = _userKey;
      var done = await _reviews.complete(userKey, session);
      // Kept in state at once, so a retry after a later failure starts from
      // what is saved.
      if (!isClosed) emit(state.copyWith(session: done));
      await AlarmService.syncReviewReminder(_vocabulary);
      done = await _grantRewardIfNeeded(done);
      final words = await _vocabulary.getAllWords();
      if (isClosed) return;
      emit(state.copyWith(
        phase: DailyReviewPhase.result,
        session: done,
        wordChanges: _wordChanges(done, words),
        reward: DailyReviewRewards.of(done),
        isSubmitting: false,
      ));
    } catch (e) {
      if (isClosed) return;
      emit(state.copyWith(isSubmitting: false));
      messageController.add(S.current.daily_review_save_failed(e.toString()));
    }
  }

  /// Pays the review at most once. The claim is saved before anything is
  /// paid, so a crash in between loses the reward instead of paying twice.
  Future<DailyReviewSession> _grantRewardIfNeeded(
      DailyReviewSession session) async {
    if (!session.isCompleted || session.rewardClaimed) return session;
    final claim = await _reviews.markRewardClaimed(_userKey, session);
    final claimed = claim.session;
    if (!isClosed) emit(state.copyWith(session: claimed));
    // Storage already had the claim: it was paid before.
    if (!claim.claimedNow) return claimed;
    final reward = DailyReviewRewards.of(claimed);
    try {
      if (reward.totalXp > 0) await _xpCubit.addXp(reward.totalXp);
      if (reward.totalGems > 0) await _xpCubit.addGems(reward.totalGems);
    } catch (e) {
      // The claim is saved: never retry, never pay twice.
      debugPrint('Daily review reward not paid: $e');
    }
    try {
      await _questCubit.onProgressByType(QuestType.completeQuiz);
    } catch (e) {
      // Quest progress must not block the result.
      debugPrint('Daily review quest progress not saved: $e');
    }
    if (!isClosed) {
      messageController.add(S.current
          .daily_review_reward_received(reward.totalXp, reward.totalGems));
    }
    return claimed;
  }

  // ── Settings ──────────────────────────────────────────────────────────────

  Future<void> changePreset(int preset) async {
    final normalized = DailyTarget.normalizePreset(preset);
    try {
      await _reviews.savePreset(_userKey, normalized);
      if (isClosed) return;
      emit(state.copyWith(preset: normalized));
      messageController.add(S.current.daily_review_preset_applies_tomorrow);
    } catch (e) {
      if (isClosed) return;
      messageController.add(S.current.error_load_data(e.toString()));
    }
  }

  // ── Mapping ───────────────────────────────────────────────────────────────

  List<DailyReviewWordChange> _wordChanges(
      DailyReviewSession session, List<VocabularyEntry> words) {
    final byId = {for (final word in words) word.id: word};
    final changes = <DailyReviewWordChange>[];
    for (final id in session.wordIds) {
      final step = session.levels[id];
      final word = byId[id];
      if (step == null || word == null || !step.isChanged) continue;
      changes.add(DailyReviewWordChange(
        wordId: id,
        word: word.word,
        meaning: word.meaning,
        before: step.before,
        after: step.after,
      ));
    }
    return changes;
  }

  @override
  Future<void> close() {
    messageController.close();
    return super.close();
  }
}

class _Attempt {
  _Attempt(this.isCorrect, this.choiceIndex);

  final bool isCorrect;

  /// The choice of the first tap, which is the one graded.
  final int choiceIndex;
  LevelStep? step;
  bool logged = false;
}
