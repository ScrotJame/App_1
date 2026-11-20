import 'package:flutter_test/flutter_test.dart';
import 'package:test_abc/page/daily_review/logic/daily_target.dart';

void main() {
  DailyTargetDecision decide({
    int learned = 150,
    int preset = 20,
    AdaptiveTarget? saved = const AdaptiveTarget(value: 20, preset: 20),
    List<double> recent = const [],
  }) =>
      DailyTarget.decide(
        learnedCount: learned,
        preset: preset,
        saved: saved,
        recentAccuracies: recent,
      );

  group('under 100 learned words', () {
    test('N is the preset and nothing adaptive is saved', () {
      final result = decide(learned: 99, preset: 30, recent: [1, 1, 1]);
      expect(result.target, 30);
      expect(result.adaptive, isNull);
      expect(result.isAdaptive, isFalse);
    });

    test('a preset other than 10 / 20 / 30 falls back to 20', () {
      expect(decide(learned: 5, preset: 15).target, 20);
      expect(DailyTarget.normalizePreset(null), 20);
      expect(DailyTarget.normalizePreset(10), 10);
    });
  });

  group('from 100 learned words', () {
    test('the first time, N is the preset', () {
      final result = decide(learned: 100, preset: 30, saved: null, recent: [1, 1, 1]);
      expect(result.target, 30);
      expect(result.adaptive, const AdaptiveTarget(value: 30, preset: 30));
      expect(result.isAdaptive, isTrue);
    });

    test('an average of 0.9 or more adds 5', () {
      expect(decide(recent: [0.9, 0.9, 0.9]).target, 25);
      expect(decide(recent: [1, 0.95, 0.9]).target, 25);
    });

    test('an average under 0.6 removes 5', () {
      expect(decide(recent: [0.5, 0.6, 0.5]).target, 15);
    });

    test('in between, N stays', () {
      expect(decide(recent: [0.7, 0.8, 0.9]).target, 20);
      expect(decide(recent: [0.6, 0.6, 0.6]).target, 20);
    });

    test('fewer than 3 finished reviews: N stays', () {
      expect(decide(recent: [1, 1]).target, 20);
    });

    test('only the 3 latest reviews count', () {
      expect(decide(recent: [0.1, 1, 1, 1]).target, 25);
    });

    test('N stays within 10 and 50', () {
      expect(
        decide(saved: const AdaptiveTarget(value: 50, preset: 20), recent: [1, 1, 1])
            .target,
        50,
      );
      expect(
        decide(saved: const AdaptiveTarget(value: 10, preset: 20), recent: [0, 0, 0])
            .target,
        10,
      );
    });

    test('changing the preset starts over from the new preset', () {
      final result = decide(
        preset: 30,
        saved: const AdaptiveTarget(value: 45, preset: 20),
        recent: [1, 1, 1],
      );
      expect(result.target, 30);
      expect(result.adaptive, const AdaptiveTarget(value: 30, preset: 30));
    });

    test('the result is what gets saved for next time', () {
      final result = decide(recent: [1, 1, 1]);
      expect(result.adaptive, const AdaptiveTarget(value: 25, preset: 20));
    });
  });

  group('AdaptiveTarget storage', () {
    test('round trip', () {
      const target = AdaptiveTarget(value: 35, preset: 20);
      expect(AdaptiveTarget.tryDecode(target.encode()), target);
    });

    test('broken data reads as nothing saved', () {
      expect(AdaptiveTarget.tryDecode(null), isNull);
      expect(AdaptiveTarget.tryDecode('{oops'), isNull);
      expect(AdaptiveTarget.tryDecode('{"value": "x", "preset": 20}'), isNull);
    });
  });
}
