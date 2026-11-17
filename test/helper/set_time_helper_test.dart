import 'package:flutter_test/flutter_test.dart';
import 'package:test_abc/helper/set_time_helper.dart';

void main() {
  final reviewed = DateTime(2026, 3, 10, 9);

  group('SetTimeHelper.isDue', () {
    test('a word that was never reviewed is due', () {
      expect(SetTimeHelper.isDue(0, null, reviewed), isTrue);
      expect(SetTimeHelper.isDue(4, null, reviewed), isTrue);
    });

    test('a word is due exactly when its interval has passed', () {
      for (var level = 0; level <= 6; level++) {
        final interval = SetTimeHelper.reviewInterval(level);
        final dueAt = reviewed.add(interval);

        expect(
          SetTimeHelper.isDue(
              level, reviewed, dueAt.subtract(const Duration(seconds: 1))),
          isFalse,
          reason: 'level $level, one second early',
        );
        expect(SetTimeHelper.isDue(level, reviewed, dueAt), isTrue,
            reason: 'level $level, on time');
      }
    });

    test('higher levels never rest for less time', () {
      for (var level = 0; level < 6; level++) {
        expect(
          SetTimeHelper.reviewInterval(level + 1),
          greaterThanOrEqualTo(SetTimeHelper.reviewInterval(level)),
        );
      }
    });
  });

  group('SetTimeHelper.reminderTime', () {
    test('during the day it is the moment the word becomes due', () {
      expect(
        SetTimeHelper.reminderTime(1, reviewed),
        reviewed.add(const Duration(minutes: 15)),
      );
    });

    test('short intervals do not ring during the night', () {
      // Level 4 rests 2 hours; 23:00 + 2h would be 01:00.
      final late = DateTime(2026, 3, 10, 23);

      // One hour is used up before midnight, the other after 06:00.
      expect(SetTimeHelper.reminderTime(4, late), DateTime(2026, 3, 11, 7));
    });

    test('it is never earlier than the moment the word becomes due', () {
      for (var hour = 0; hour < 24; hour++) {
        final at = DateTime(2026, 3, 10, hour, 30);
        for (var level = 0; level <= 6; level++) {
          final reminder = SetTimeHelper.reminderTime(level, at);
          expect(SetTimeHelper.isDue(level, at, reminder), isTrue,
              reason: 'level $level reviewed at $hour:30');
        }
      }
    });

    test('a mastered word is reminded after its long interval', () {
      expect(
        SetTimeHelper.reminderTime(5, reviewed),
        reviewed.add(const Duration(days: 8)),
      );
    });
  });
}
