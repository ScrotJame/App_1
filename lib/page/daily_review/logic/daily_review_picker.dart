import 'dart:math';

import '../../../commons/status_comon.dart';
import '../../../helper/set_time_helper.dart';

/// The group a learned word falls into for the daily review.
enum DailyReviewGroup { due, weak, mastered, rest }

/// What the picker needs to know about one word.
class ReviewCandidate {
  const ReviewCandidate({
    required this.id,
    required this.level,
    required this.lastReviewed,
    this.correctCount = 0,
    this.wrongCount = 0,
  });

  final int id;
  final int level;

  /// Null for a word that was never learned. Such a word is never picked.
  final DateTime? lastReviewed;
  final int correctCount;
  final int wrongCount;

  int get answerCount => correctCount + wrongCount;

  double get wrongRate => answerCount == 0 ? 0 : wrongCount / answerCount;
}

/// The words of one daily review, in the order they are asked.
class DailyReviewPick {
  const DailyReviewPick({required this.wordIds, required this.groupCounts});

  final List<int> wordIds;

  /// How many of [wordIds] came from each group, fills included.
  final Map<DailyReviewGroup, int> groupCounts;
}

/// Chooses the words of a daily review. Pure: no database, no clock.
class DailyReviewPicker {
  DailyReviewPicker._();

  static const double dueShare = 0.5;
  static const double weakShare = 0.3;

  /// A word is weak from this share of wrong answers.
  static const double weakRate = 0.4;

  static const List<DailyReviewGroup> _quotaOrder = [
    DailyReviewGroup.due,
    DailyReviewGroup.weak,
    DailyReviewGroup.mastered,
  ];

  static const List<DailyReviewGroup> _fillOrder = [
    DailyReviewGroup.due,
    DailyReviewGroup.weak,
    DailyReviewGroup.mastered,
    DailyReviewGroup.rest,
  ];

  static final DateTime _never = DateTime.fromMillisecondsSinceEpoch(0);

  static bool isLearned(ReviewCandidate word) => word.lastReviewed != null;

  /// The only group of [word], or null when it was never learned. Checked in
  /// this order: mastered, weak, due, rest.
  static DailyReviewGroup? groupOf(ReviewCandidate word, DateTime now) {
    final lastReviewed = word.lastReviewed;
    if (lastReviewed == null) return null;
    if (word.level >= WordStatus.masteredLevel) return DailyReviewGroup.mastered;
    if (word.answerCount > 0 && word.wrongRate >= weakRate) {
      return DailyReviewGroup.weak;
    }
    if (SetTimeHelper.isDue(word.level, lastReviewed, now)) {
      return DailyReviewGroup.due;
    }
    return DailyReviewGroup.rest;
  }

  static Map<DailyReviewGroup, int> quotas(int target) {
    final due = (target * dueShare).round();
    final weak = (target * weakShare).round();
    return {
      DailyReviewGroup.due: due,
      DailyReviewGroup.weak: weak,
      DailyReviewGroup.mastered: max(0, target - due - weak),
      DailyReviewGroup.rest: 0,
    };
  }

  static DailyReviewPick pick({
    required List<ReviewCandidate> candidates,
    required int target,
    required DateTime now,
    required Random random,
  }) {
    final groups = {
      for (final group in DailyReviewGroup.values) group: <ReviewCandidate>[],
    };
    for (final word in candidates) {
      final group = groupOf(word, now);
      if (group != null) groups[group]?.add(word);
    }
    groups.forEach((group, words) => words.sort((a, b) => _compare(group, a, b)));

    final taken = <DailyReviewGroup, int>{
      for (final group in DailyReviewGroup.values) group: 0,
    };
    final picked = <int>[];

    void take(DailyReviewGroup group, int count) {
      final words = groups[group] ?? const <ReviewCandidate>[];
      final int start = taken[group] ?? 0;
      final int end = min<int>(words.length, start + max<int>(0, count));
      for (var i = start; i < end; i++) {
        picked.add(words[i].id);
      }
      taken[group] = end;
    }

    if (target > 0) {
      final quota = quotas(target);
      for (final group in _quotaOrder) {
        take(group, quota[group] ?? 0);
      }
      for (final group in _fillOrder) {
        take(group, target - picked.length);
      }
    }

    picked.shuffle(random);
    return DailyReviewPick(
      wordIds: List.unmodifiable(picked),
      groupCounts: Map.unmodifiable(taken),
    );
  }

  static int _compare(
      DailyReviewGroup group, ReviewCandidate a, ReviewCandidate b) {
    final byGroup = switch (group) {
      DailyReviewGroup.due => _dueAt(a).compareTo(_dueAt(b)),
      DailyReviewGroup.weak => _compareWeak(a, b),
      DailyReviewGroup.mastered ||
      DailyReviewGroup.rest =>
        _reviewedAt(a).compareTo(_reviewedAt(b)),
    };
    return byGroup != 0 ? byGroup : a.id.compareTo(b.id);
  }

  static int _compareWeak(ReviewCandidate a, ReviewCandidate b) {
    final byRate = b.wrongRate.compareTo(a.wrongRate);
    return byRate != 0 ? byRate : b.wrongCount.compareTo(a.wrongCount);
  }

  static DateTime _reviewedAt(ReviewCandidate word) =>
      word.lastReviewed ?? _never;

  static DateTime _dueAt(ReviewCandidate word) =>
      _reviewedAt(word).add(SetTimeHelper.reviewInterval(word.level));
}
