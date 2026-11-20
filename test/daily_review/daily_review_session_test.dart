import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:test_abc/page/daily_review/data/daily_review_session.dart';
import 'package:test_abc/page/daily_review/data/daily_review_status.dart';
import 'package:test_abc/page/daily_review/logic/daily_review_picker.dart';

void main() {
  final session = DailyReviewSession(
    date: '2026-11-19',
    target: 20,
    adaptive: true,
    wordIds: const [12, 7, 33],
    groupCounts: const {
      DailyReviewGroup.due: 2,
      DailyReviewGroup.weak: 1,
      DailyReviewGroup.mastered: 0,
      DailyReviewGroup.rest: 0,
    },
    answers: const {12: true, 7: false},
    levels: const {12: LevelStep(2, 3), 7: LevelStep(4, 3)},
    completedAt: DateTime(2026, 11, 19, 10, 30),
    rewardClaimed: true,
  );

  test('round trip through JSON', () {
    expect(DailyReviewSession.tryDecode(session.encode()), session);
  });

  test('the JSON has the spec layout', () {
    final json = jsonDecode(session.encode()) as Map<String, dynamic>;
    expect(json['version'], 1);
    expect(json['date'], '2026-11-19');
    expect(json['wordIds'], [12, 7, 33]);
    expect(json['groupCounts'], {'due': 2, 'weak': 1, 'mastered': 0, 'rest': 0});
    expect(json['answers'], {'12': true, '7': false});
    expect(json['levels'], {'12': [2, 3], '7': [4, 3]});
    expect(json['rewardClaimed'], true);
  });

  test('broken JSON, another version or a bad date read as no session', () {
    final json = session.toJson();
    expect(DailyReviewSession.tryDecode(null), isNull);
    expect(DailyReviewSession.tryDecode('{oops'), isNull);
    expect(DailyReviewSession.tryDecode('[]'), isNull);
    expect(
        DailyReviewSession.tryDecode(jsonEncode({...json, 'version': 2})), isNull);
    expect(
        DailyReviewSession.tryDecode(jsonEncode({...json}..remove('version'))),
        isNull);
    expect(
        DailyReviewSession.tryDecode(jsonEncode({...json, 'date': '2026-02-31'})),
        isNull);
    expect(
        DailyReviewSession.tryDecode(jsonEncode({...json, 'wordIds': ['x']})),
        isNull);
  });

  test('missing optional fields use their defaults', () {
    final raw = jsonEncode({
      'version': 1,
      'date': '2026-11-19',
      'target': 10,
      'wordIds': [1, 2],
    });
    final decoded = DailyReviewSession.tryDecode(raw);
    expect(decoded?.adaptive, isFalse);
    expect(decoded?.answers, isEmpty);
    expect(decoded?.levels, isEmpty);
    expect(decoded?.isCompleted, isFalse);
    expect(decoded?.rewardClaimed, isFalse);
  });

  test('counters only look at words still in the review', () {
    final partial = DailyReviewSession(
      date: '2026-11-19',
      target: 3,
      wordIds: const [1, 2, 3],
      answers: const {1: true, 2: false, 99: true},
    );
    expect(partial.total, 3);
    expect(partial.answeredCount, 2);
    expect(partial.correctCount, 1);
    expect(partial.accuracy, 0.5);
    expect(partial.allAnswered, isFalse);

    final done = partial.withAnswer(3, isCorrect: true, level: const LevelStep(1, 2));
    expect(done.allAnswered, isTrue);
    expect(done.levels[3], const LevelStep(1, 2));
  });

  test('status of a session', () {
    expect(DailyReviewStatus.of(null), DailyReviewStatus.notCreated);
    final open = DailyReviewSession(
      date: '2026-11-19',
      target: 3,
      wordIds: const [1, 2, 3],
      answers: const {1: true},
    );
    expect(
      DailyReviewStatus.of(open),
      const DailyReviewStatus(
          progress: DailyReviewProgress.inProgress, answered: 1, total: 3),
    );
    expect(
      DailyReviewStatus.of(open.copyWith(completedAt: DateTime(2026, 11, 19))).progress,
      DailyReviewProgress.completed,
    );
  });
}
