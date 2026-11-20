import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:rxdart/rxdart.dart';

import '../../../database/app_db.dart';
import '../../../helper/streak_date_helper.dart';
import '../../../repository/learning_history_repository.dart';
import '../../../repository/vocabulary_repository.dart';
import '../logic/daily_review_picker.dart';
import '../logic/daily_target.dart';
import 'daily_review_local_data_source.dart';
import 'daily_review_session.dart';
import 'daily_review_status.dart';

/// Today's review and its settings, kept in SharedPreferences per user.
///
/// Grading is not done here: the cubit writes the level and the history log
/// first, and only then calls [saveAnswer].
class DailyReviewRepository {
  DailyReviewRepository(
    this._dataSource,
    this._vocabulary,
    this._history, {
    DateTime Function()? clock,
    Random? random,
  })  : _clock = clock ?? DateTime.now,
        _random = random ?? Random();

  final DailyReviewLocalDataSource _dataSource;
  final IVocabularyRepository _vocabulary;
  final ILearningHistoryRepository _history;
  final DateTime Function() _clock;
  final Random _random;

  final BehaviorSubject<DailyReviewStatus> _status =
      BehaviorSubject.seeded(DailyReviewStatus.notCreated);

  static String sessionKey(String userKey) => 'daily_review_session_$userKey';
  static String presetKey(String userKey) => 'daily_review_preset_$userKey';
  static String adaptiveKey(String userKey) => 'daily_review_adaptive_$userKey';
  static String recentKey(String userKey) => 'daily_review_recent_$userKey';

  String get _today => StreakDateHelper.keyOf(_clock());

  // ── Status ────────────────────────────────────────────────────────────────

  /// Today's status, then every change. Reading it never creates a review.
  Stream<DailyReviewStatus> watchTodayStatus(String userKey) {
    unawaited(refreshStatus(userKey));
    return _status.stream.distinct();
  }

  Future<DailyReviewStatus> refreshStatus(String userKey) async {
    final session = await _readToday(userKey);
    _emit(session);
    return DailyReviewStatus.of(session);
  }

  // ── Session ───────────────────────────────────────────────────────────────

  /// Resumes today's review, or creates it when there is none for today.
  /// Returns null, and stores nothing, when the user has no learned word.
  Future<DailyReviewSession?> openToday(String userKey) async {
    if (userKey.isEmpty) return null;
    final words = await _vocabulary.getAllWords();
    final byId = {for (final word in words) word.id: word};

    var session = await _readToday(userKey);
    if (session != null) {
      session = await _reconcile(userKey, session, byId);
      if (session.wordIds.isEmpty) session = null;
    }
    session ??= await _create(userKey, words);

    if (session == null) {
      await _dataSource.remove(sessionKey(userKey));
      _emit(null);
      return null;
    }
    await _save(userKey, session);
    return session;
  }

  Future<DailyReviewSession> saveAnswer(
    String userKey,
    DailyReviewSession session, {
    required int wordId,
    required bool isCorrect,
    required LevelStep level,
  }) async {
    final next = session.withAnswer(wordId, isCorrect: isCorrect, level: level);
    await _save(userKey, next);
    return next;
  }

  /// Closes the official run and remembers its accuracy for the adaptive N.
  Future<DailyReviewSession> complete(
      String userKey, DailyReviewSession session) async {
    if (session.isCompleted) return session;
    final next = session.copyWith(completedAt: _clock());
    await _save(userKey, next);
    await _pushRecentAccuracy(userKey, next.accuracy);
    return next;
  }

  Future<DailyReviewSession> markRewardClaimed(
      String userKey, DailyReviewSession session) async {
    final next = session.copyWith(rewardClaimed: true);
    await _save(userKey, next);
    return next;
  }

  // ── Settings ──────────────────────────────────────────────────────────────

  Future<int> readPreset(String userKey) async {
    final raw = await _dataSource.readString(presetKey(userKey));
    return DailyTarget.normalizePreset(int.tryParse(raw ?? ''));
  }

  Future<void> savePreset(String userKey, int preset) => _dataSource
      .writeString(presetKey(userKey), '${DailyTarget.normalizePreset(preset)}');

  /// Accuracy of up to the 3 latest finished reviews, oldest first.
  Future<List<double>> readRecentAccuracies(String userKey) async {
    final raw = await _dataSource.readString(recentKey(userKey));
    if (raw == null) return const [];
    try {
      final list = jsonDecode(raw);
      if (list is! List) return const [];
      return list.whereType<num>().map((v) => v.toDouble()).toList();
    } catch (_) {
      return const [];
    }
  }

  Future<void> close() => _status.close();

  // ── Private ───────────────────────────────────────────────────────────────

  Future<DailyReviewSession?> _readToday(String userKey) async {
    if (userKey.isEmpty) return null;
    final session = DailyReviewSession.tryDecode(
        await _dataSource.readString(sessionKey(userKey)));
    if (session == null || session.date != _today) return null;
    return session;
  }

  /// Drops deleted words and copies answers that reached the history log but
  /// not SharedPreferences. Copied answers are never graded again.
  Future<DailyReviewSession> _reconcile(
    String userKey,
    DailyReviewSession session,
    Map<int, VocabularyEntry> byId,
  ) async {
    final wordIds = session.wordIds.where(byId.containsKey).toList();
    final answers = {
      for (final e in session.answers.entries)
        if (byId.containsKey(e.key)) e.key: e.value,
    };
    final levels = {
      for (final e in session.levels.entries)
        if (byId.containsKey(e.key)) e.key: e.value,
    };

    final open = wordIds.where((id) => !answers.containsKey(id)).toList();
    if (open.isNotEmpty) {
      final logged = await _history.getDailyReviewAnswers(
        userKey: userKey,
        day: StreakDateHelper.tryParseKey(session.date) ?? _clock(),
      );
      for (final id in open) {
        final log = logged[id];
        if (log == null) continue;
        answers[id] = log.isCorrect;
        levels[id] = LevelStep(log.levelBefore, byId[id]?.level ?? log.levelBefore);
      }
    }
    return session.copyWith(wordIds: wordIds, answers: answers, levels: levels);
  }

  Future<DailyReviewSession?> _create(
      String userKey, List<VocabularyEntry> words) async {
    final candidates = [
      for (final word in words)
        ReviewCandidate(
          id: word.id,
          level: word.level,
          lastReviewed: word.lastReviewed,
          correctCount: word.correctCount,
          wrongCount: word.wrongCount,
        ),
    ];
    final learned = candidates.where(DailyReviewPicker.isLearned).length;
    if (learned == 0) return null;

    final decision = DailyTarget.decide(
      learnedCount: learned,
      preset: await readPreset(userKey),
      saved: AdaptiveTarget.tryDecode(
          await _dataSource.readString(adaptiveKey(userKey))),
      recentAccuracies: await readRecentAccuracies(userKey),
    );
    final adaptive = decision.adaptive;
    if (adaptive != null) {
      await _dataSource.writeString(adaptiveKey(userKey), adaptive.encode());
    }

    final pick = DailyReviewPicker.pick(
      candidates: candidates,
      target: decision.target,
      now: _clock(),
      random: _random,
    );
    return DailyReviewSession(
      date: _today,
      target: decision.target,
      adaptive: decision.isAdaptive,
      wordIds: pick.wordIds,
      groupCounts: pick.groupCounts,
    );
  }

  Future<void> _save(String userKey, DailyReviewSession session) async {
    await _dataSource.writeString(sessionKey(userKey), session.encode());
    _emit(session);
  }

  Future<void> _pushRecentAccuracy(String userKey, double accuracy) async {
    final recent = [...await readRecentAccuracies(userKey), accuracy];
    final kept = recent.length > DailyTarget.recentWindow
        ? recent.sublist(recent.length - DailyTarget.recentWindow)
        : recent;
    await _dataSource.writeString(recentKey(userKey), jsonEncode(kept));
  }

  /// A review of another day (kept open past midnight) shows as not created.
  void _emit(DailyReviewSession? session) {
    if (_status.isClosed) return;
    _status.add(session != null && session.date == _today
        ? DailyReviewStatus.of(session)
        : DailyReviewStatus.notCreated);
  }
}
