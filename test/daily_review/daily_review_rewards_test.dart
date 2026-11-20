import 'package:flutter_test/flutter_test.dart';
import 'package:test_abc/page/daily_review/data/daily_review_session.dart';
import 'package:test_abc/page/daily_review/logic/daily_review_rewards.dart';
import 'package:test_abc/page/test_word/test_cubit.dart';

void main() {
  DailyReviewSession session({
    required Map<int, bool> answers,
    Map<int, LevelStep> levels = const {},
    bool completed = true,
  }) =>
      DailyReviewSession(
        date: '2026-11-19',
        target: answers.length,
        wordIds: answers.keys.toList(),
        answers: answers,
        levels: levels,
        completedAt: completed ? DateTime(2026, 11, 19, 10) : null,
      );

  test('an unfinished review pays nothing', () {
    final reward = DailyReviewRewards.of(session(
      answers: {1: true},
      levels: {1: const LevelStep(1, 2)},
      completed: false,
    ));
    expect(reward, DailyReviewRewardBreakdown.none);
  });

  test('finishing pays the completion bonus even with only wrong answers', () {
    final reward = DailyReviewRewards.of(session(
      answers: {1: false, 2: false},
      levels: {1: const LevelStep(3, 2), 2: const LevelStep(0, 0)},
    ));
    expect(reward.totalXp, 30);
    expect(reward.totalGems, 20);
    expect(reward.wordXp, 0);
    expect(reward.accuracyXp, 0);
  });

  test('each word that levelled up pays for its new level', () {
    final reward = DailyReviewRewards.of(session(
      answers: {1: true, 2: true, 3: false},
      levels: {
        1: const LevelStep(2, 3),
        2: const LevelStep(4, 5),
        3: const LevelStep(1, 0),
      },
    ));
    expect(reward.wordXp, TestState.xpForLevel(3) + TestState.xpForLevel(5));
    expect(reward.wordGems, TestState.gemsForLevel(3) + TestState.gemsForLevel(5));
    expect(reward.accuracyXp, 0); // 2/3 < 0.8
    expect(reward.totalXp, 15 + 40 + 30);
    expect(reward.totalGems, 35 + 75 + 20);
  });

  test('a right answer on a word that was not due pays no word reward', () {
    final reward = DailyReviewRewards.of(session(
      answers: {1: true},
      levels: {1: const LevelStep(3, 3)},
    ));
    expect(reward.wordXp, 0);
    expect(reward.wordGems, 0);
  });

  test('an accuracy of exactly 0.8 pays the accuracy bonus', () {
    final reward = DailyReviewRewards.of(session(
      answers: {1: true, 2: true, 3: true, 4: true, 5: false},
    ));
    expect(reward.accuracyXp, 20);
    expect(reward.accuracyGems, 10);
    expect(reward.totalXp, 50);
    expect(reward.totalGems, 30);
  });
}
