import 'package:flutter_test/flutter_test.dart';
import 'package:test_abc/service/active_time_tracker.dart';

void main() {
  group('ActiveTimeTracker Tests', () {
    late DateTime baseTime;

    setUp(() {
      baseTime = DateTime(2026, 9, 5, 10, 0, 0);
    });

    test('should increment active seconds when within idle threshold (<= 30s)', () {
      final tracker = ActiveTimeTracker(
        initialTime: baseTime,
        idleThreshold: const Duration(seconds: 30),
      );

      // 10s after baseTime, tick by 1 second
      final currentTime = baseTime.add(const Duration(seconds: 10));
      tracker.tick(currentTime, step: const Duration(seconds: 1));

      expect(tracker.activeSeconds, 1);
      expect(tracker.isIdle(currentTime), isFalse);
    });

    test('should NOT increment active seconds when idle (> 30s since last activity)', () {
      final tracker = ActiveTimeTracker(
        initialTime: baseTime,
        idleThreshold: const Duration(seconds: 30),
      );

      // 31s after baseTime with no activity
      final currentTime = baseTime.add(const Duration(seconds: 31));
      expect(tracker.isIdle(currentTime), isTrue);

      tracker.tick(currentTime, step: const Duration(seconds: 1));
      expect(tracker.activeSeconds, 0);
    });

    test('should resume counting when user records activity after being idle', () {
      final tracker = ActiveTimeTracker(
        initialTime: baseTime,
        idleThreshold: const Duration(seconds: 30),
      );

      // Idle at 40s
      final idleTime = baseTime.add(const Duration(seconds: 40));
      tracker.tick(idleTime);
      expect(tracker.activeSeconds, 0);

      // User interacts at 50s
      final activeTime = baseTime.add(const Duration(seconds: 50));
      tracker.recordActivity(activeTime);
      expect(tracker.isIdle(activeTime), isFalse);

      // Next tick 2s later (52s)
      final tickTime = baseTime.add(const Duration(seconds: 52));
      tracker.tick(tickTime, step: const Duration(seconds: 2));
      expect(tracker.activeSeconds, 2);
    });

    test('should correctly restore initial active seconds', () {
      final tracker = ActiveTimeTracker(
        initialTime: baseTime,
        initialActiveSeconds: 120,
      );

      expect(tracker.activeSeconds, 120);

      final nextTime = baseTime.add(const Duration(seconds: 5));
      tracker.tick(nextTime, step: const Duration(seconds: 5));
      expect(tracker.activeSeconds, 125);
    });
  });
}
