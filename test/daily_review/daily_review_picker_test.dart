import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:test_abc/page/daily_review/logic/daily_review_picker.dart';

void main() {
  final now = DateTime(2026, 11, 19, 12);

  /// Level 1, reviewed [ago] ago: due once 15 minutes have passed.
  ReviewCandidate due(int id, {Duration ago = const Duration(days: 1)}) =>
      ReviewCandidate(id: id, level: 1, lastReviewed: now.subtract(ago));

  /// Level 2, reviewed a minute ago (not due), wrong more often than not.
  ReviewCandidate weak(int id, {int wrong = 2, int correct = 1}) =>
      ReviewCandidate(
        id: id,
        level: 2,
        lastReviewed: now.subtract(const Duration(minutes: 1)),
        correctCount: correct,
        wrongCount: wrong,
      );

  ReviewCandidate mastered(int id, {Duration ago = const Duration(days: 1)}) =>
      ReviewCandidate(id: id, level: 5, lastReviewed: now.subtract(ago));

  /// Learned, not due, never wrong.
  ReviewCandidate rest(int id, {Duration ago = const Duration(minutes: 1)}) =>
      ReviewCandidate(id: id, level: 1, lastReviewed: now.subtract(ago));

  ReviewCandidate unlearned(int id) =>
      ReviewCandidate(id: id, level: 0, lastReviewed: null);

  DailyReviewPick pick(List<ReviewCandidate> words, int target,
          {int seed = 1}) =>
      DailyReviewPicker.pick(
        candidates: words,
        target: target,
        now: now,
        random: Random(seed),
      );

  group('groups', () {
    test('each word is in exactly one group, in table order', () {
      final masteredAndWeak = ReviewCandidate(
        id: 1,
        level: 5,
        lastReviewed: now.subtract(const Duration(days: 30)),
        correctCount: 0,
        wrongCount: 9,
      );
      final weakAndDue = ReviewCandidate(
        id: 2,
        level: 1,
        lastReviewed: now.subtract(const Duration(days: 30)),
        correctCount: 1,
        wrongCount: 1,
      );

      expect(DailyReviewPicker.groupOf(masteredAndWeak, now),
          DailyReviewGroup.mastered);
      expect(DailyReviewPicker.groupOf(weakAndDue, now), DailyReviewGroup.weak);
      expect(DailyReviewPicker.groupOf(due(3), now), DailyReviewGroup.due);
      expect(DailyReviewPicker.groupOf(rest(4), now), DailyReviewGroup.rest);
      expect(DailyReviewPicker.groupOf(unlearned(5), now), isNull);
    });

    test('a word with no answers is never weak', () {
      final word = ReviewCandidate(
        id: 1,
        level: 2,
        lastReviewed: now.subtract(const Duration(minutes: 1)),
      );
      expect(DailyReviewPicker.groupOf(word, now), DailyReviewGroup.rest);
    });

    test('a wrong rate just under 0.4 is not weak', () {
      final word = weak(1, wrong: 39, correct: 61);
      expect(DailyReviewPicker.groupOf(word, now), DailyReviewGroup.rest);
      expect(DailyReviewPicker.groupOf(weak(2, wrong: 2, correct: 3), now),
          DailyReviewGroup.weak);
    });
  });

  group('quotas', () {
    test('50 / 30 / rest for even and odd targets', () {
      Map<DailyReviewGroup, int> q(int n) => DailyReviewPicker.quotas(n);
      expect(q(20)[DailyReviewGroup.due], 10);
      expect(q(20)[DailyReviewGroup.weak], 6);
      expect(q(20)[DailyReviewGroup.mastered], 4);
      expect(q(15)[DailyReviewGroup.due], 8);
      expect(q(15)[DailyReviewGroup.weak], 5);
      expect(q(15)[DailyReviewGroup.mastered], 2);
      expect(q(25)[DailyReviewGroup.due], 13);
      expect(q(25)[DailyReviewGroup.weak], 8);
      expect(q(25)[DailyReviewGroup.mastered], 4);
      expect(q(10)[DailyReviewGroup.mastered], 2);
    });

    test('every group full: the quotas are used as they are', () {
      final words = [
        for (var i = 1; i <= 20; i++) due(i),
        for (var i = 21; i <= 40; i++) weak(i),
        for (var i = 41; i <= 60; i++) mastered(i),
      ];

      final result = pick(words, 20);

      expect(result.wordIds, hasLength(20));
      expect(result.wordIds.toSet(), hasLength(20));
      expect(result.groupCounts[DailyReviewGroup.due], 10);
      expect(result.groupCounts[DailyReviewGroup.weak], 6);
      expect(result.groupCounts[DailyReviewGroup.mastered], 4);
      expect(result.groupCounts[DailyReviewGroup.rest], 0);
    });
  });

  group('filling', () {
    test('a short group is filled from due, then weak, then mastered', () {
      final words = [
        due(1),
        due(2),
        for (var i = 10; i < 20; i++) weak(i),
        for (var i = 20; i < 30; i++) mastered(i),
        for (var i = 30; i < 40; i++) rest(i),
      ];

      final result = pick(words, 10);

      // Quotas 5 / 3 / 2. Due has only 2, so weak gives 3 more.
      expect(result.groupCounts[DailyReviewGroup.due], 2);
      expect(result.groupCounts[DailyReviewGroup.weak], 6);
      expect(result.groupCounts[DailyReviewGroup.mastered], 2);
      expect(result.groupCounts[DailyReviewGroup.rest], 0);
      expect(result.wordIds, hasLength(10));
    });

    test('the rest group only fills what the others cannot', () {
      final words = [
        for (var i = 1; i <= 3; i++) mastered(i),
        for (var i = 10; i < 20; i++) rest(i),
      ];

      final result = pick(words, 10);

      expect(result.groupCounts[DailyReviewGroup.mastered], 3);
      expect(result.groupCounts[DailyReviewGroup.rest], 7);
      expect(result.wordIds, hasLength(10));
    });

    test('fewer learned words than N: the review has all of them', () {
      final result = pick([due(1), weak(2), mastered(3)], 20);
      expect(result.wordIds.toSet(), {1, 2, 3});
    });

    test('words never learned are never picked', () {
      final result = pick([unlearned(1), unlearned(2), due(3)], 20);
      expect(result.wordIds, [3]);
    });

    test('a target of 0 picks nothing', () {
      expect(pick([due(1)], 0).wordIds, isEmpty);
    });
  });

  group('priority', () {
    test('due: the word that became due first comes first', () {
      final words = [
        // due at -105 min
        ReviewCandidate(
            id: 1, level: 1, lastReviewed: now.subtract(const Duration(hours: 2))),
        // due at -60 min
        ReviewCandidate(
            id: 2, level: 4, lastReviewed: now.subtract(const Duration(hours: 3))),
        // due at -55 min
        ReviewCandidate(
            id: 3, level: 0, lastReviewed: now.subtract(const Duration(hours: 1))),
      ];

      expect(pick(words, 2).wordIds.toSet(), {1, 2});
    });

    test('weak: highest wrong rate, then most wrong answers', () {
      final words = [
        weak(10, wrong: 3, correct: 1), // 0.75
        weak(11, wrong: 2, correct: 0), // 1.0
        weak(12, wrong: 6, correct: 2), // 0.75, more wrong answers
      ];

      expect(pick(words, 2).wordIds.toSet(), {11, 12});
    });

    test('mastered: the oldest review comes first', () {
      final words = [
        mastered(1, ago: const Duration(days: 1)),
        mastered(2, ago: const Duration(days: 9)),
        mastered(3, ago: const Duration(days: 5)),
      ];

      expect(pick(words, 2).wordIds.toSet(), {2, 3});
    });

    test('ties are broken by id', () {
      final words = [due(7), due(4), due(9)];
      expect(pick(words, 2).wordIds.toSet(), {4, 7});
    });
  });

  group('shuffle', () {
    test('the same seed gives the same order', () {
      final words = [for (var i = 1; i <= 10; i++) due(i)];
      expect(pick(words, 10, seed: 3).wordIds, pick(words, 10, seed: 3).wordIds);
      expect(pick(words, 10, seed: 3).wordIds.toSet(),
          {for (var i = 1; i <= 10; i++) i});
    });
  });
}
