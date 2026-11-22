import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:test_abc/commons/enums.dart';
import 'package:test_abc/models/tag_vocab.dart';
import 'package:test_abc/page/test_word/logic/test_planner.dart';

import 'test_word_support.dart';

void main() {
  final japanese = [
    for (var i = 1; i <= 12; i++)
      entry(i, '語$i', 'meaning $i', pronunciation: 'ご$i', language: 'ja'),
  ];

  TestPlan planOf(
    List<VocabularyWithTags> pool, {
    Set<TestKind> kinds = const {TestKind.choice},
    int count = 10,
    Set<String> voices = const {'ja'},
    int seed = 1,
    List<VocabularyWithTags>? allWords,
  }) =>
      TestPlanner.plan(
        pool: pool,
        allWords: allWords ?? pool,
        kinds: kinds,
        questionCount: count,
        voiceLanguages: voices,
        random: Random(seed),
      );

  Map<TestKind, int> countByKind(TestPlan plan) {
    final counts = <TestKind, int>{};
    for (final q in plan.questions) {
      counts[q.kind] = (counts[q.kind] ?? 0) + 1;
    }
    return counts;
  }

  test('splits the selected kinds evenly', () {
    final plan = planOf(japanese, kinds: TestKind.values.toSet(), count: 12);

    expect(countByKind(plan), {
      TestKind.choice: 3,
      TestKind.typing: 3,
      TestKind.listening: 3,
      TestKind.trueFalse: 3,
    });
    expect(plan.warnings, isEmpty);
  });

  test('never asks about a word twice', () {
    final plan = planOf(japanese, kinds: TestKind.values.toSet(), count: 12);
    final ids = plan.questions.map((q) => q.entry.id).toList();

    expect(ids.toSet(), hasLength(ids.length));
  });

  test('stops at the question count', () {
    expect(planOf(japanese, count: 5).questions, hasLength(5));
  });

  test('a pool smaller than the count gives every word', () {
    expect(planOf(japanese, count: 30).questions, hasLength(12));
  });

  test('skips the words no selected kind can use', () {
    final pool = [...japanese, entry(20, 'apple', 'táo', language: 'en')];

    final plan = planOf(pool, kinds: {TestKind.listening}, count: 30);

    expect(plan.questions, hasLength(12));
    expect(plan.questions.every((q) => q.entry.language == 'ja'), isTrue);
  });

  test('a kind without any question is dropped with a warning', () {
    final plan = planOf(
      japanese,
      kinds: {TestKind.choice, TestKind.listening},
      voices: {},
    );

    expect(countByKind(plan).keys, [TestKind.choice]);
    expect(plan.warnings, [
      const TestPlanWarning(TestKind.listening, missingVoiceLanguages: ['ja']),
    ]);
  });

  test('no question at all when the words cannot make one', () {
    final plan = planOf(japanese.take(2).toList(), kinds: {TestKind.choice});

    expect(plan.questions, isEmpty);
    expect(plan.warnings, [const TestPlanWarning(TestKind.choice)]);
  });

  test('wrong choices come from every word, not only the pool', () {
    final plan = planOf(
      japanese.take(1).toList(),
      allWords: japanese,
      kinds: {TestKind.choice},
    );

    expect(plan.questions, hasLength(1));
  });

  test('the same seed gives the same test', () {
    List<(int, TestKind)> shape(TestPlan plan) =>
        [for (final q in plan.questions) (q.entry.id, q.kind)];

    expect(
      shape(planOf(japanese, kinds: TestKind.values.toSet(), seed: 7)),
      shape(planOf(japanese, kinds: TestKind.values.toSet(), seed: 7)),
    );
  });
}
