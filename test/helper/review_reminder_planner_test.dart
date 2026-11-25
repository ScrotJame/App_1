import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:test_abc/helper/review_reminder_planner.dart';

void main() {
  /// Bodies read back as "<tier>#<index>:<count>" so tests can see which
  /// message was picked and with which count.
  ReviewReminderMessages messages({int perTier = 5}) => ReviewReminderMessages(
        title: 'title',
        bodies: {
          for (final tier in ReminderTier.values)
            tier: [
              for (var i = 0; i < perTier; i++)
                (int count) => '${tier.name}#$i:$count',
            ],
        },
      );

  List<ReviewReminder> plan(
    List<DateTime> times, {
    required DateTime now,
    int seed = 1,
    int perTier = 5,
  }) =>
      ReviewReminderPlanner.plan(
        reminderTimes: times,
        now: now,
        messages: messages(perTier: perTier),
        random: Random(seed),
      );

  DateTime at(int day, int hour, [int minute = 0]) =>
      DateTime(2026, 3, 10 + day, hour, minute);

  final morning = at(0, 6); // "now" for most tests, before the anchor.

  List<ReviewReminder> onDay(List<ReviewReminder> all, int day) {
    final start = at(day, 0);
    final end = at(day + 1, 0);
    return all
        .where((r) => !r.at.isBefore(start) && r.at.isBefore(end))
        .toList();
  }

  test('no reviewed word means no reminder', () {
    expect(plan(const [], now: morning), isEmpty);
  });

  group('day 0', () {
    test('anchor at 07:00 reminds at 07:00, 10:00 and 20:00', () {
      final day0 = onDay(plan([at(0, 7)], now: morning), 0);
      expect(day0.map((r) => r.at), [at(0, 7), at(0, 10), at(0, 20)]);
      expect(day0.every((r) => r.tier == ReminderTier.fresh), isTrue);
    });

    test('anchor at 19:00 reminds only at 19:00', () {
      final day0 = onDay(plan([at(0, 19)], now: morning), 0);
      expect(day0.map((r) => r.at), [at(0, 19)]);
    });

    test('anchor at 21:30 reminds only at 21:30', () {
      final day0 = onDay(plan([at(0, 21, 30)], now: morning), 0);
      expect(day0.map((r) => r.at), [at(0, 21, 30)]);
    });

    test('anchor at 18:30 keeps 21:30 but drops 20:00', () {
      final day0 = onDay(plan([at(0, 18, 30)], now: morning), 0);
      expect(day0.map((r) => r.at), [at(0, 18, 30), at(0, 21, 30)]);
    });

    test('anchor at 23:00 moves to 07:00 the next day', () {
      final all = plan([at(0, 23)], now: morning);
      expect(all.first.at, at(1, 7));
      expect(all.first.tier, ReminderTier.fresh);
      expect(onDay(all, 0), isEmpty);
    });

    test('anchor at 05:00 moves to 07:00 the same day', () {
      final all = plan([at(0, 5)], now: at(0, 4));
      expect(all.first.at, at(0, 7));
    });

    test('an overdue word anchors one hour after now', () {
      final all = plan([at(0, 8)], now: at(0, 10));
      expect(all.first.at, at(0, 11));
      expect(all.first.count, 1);
    });
  });

  group('later days', () {
    late List<ReviewReminder> all;

    setUp(() => all = plan([at(0, 7)], now: morning));

    test('days 1 and 2 are streak reminders four times a day', () {
      for (final day in [1, 2]) {
        final reminders = onDay(all, day);
        expect(reminders.map((r) => r.at),
            [at(day, 9), at(day, 12), at(day, 17), at(day, 20)]);
        expect(reminders.every((r) => r.tier == ReminderTier.streak), isTrue);
      }
    });

    test('days 3 to 6 are fading reminders five times a day', () {
      for (final day in [3, 6]) {
        final reminders = onDay(all, day);
        expect(reminders.map((r) => r.at), [
          at(day, 8),
          at(day, 11),
          at(day, 14),
          at(day, 17),
          at(day, 20),
        ]);
        expect(reminders.every((r) => r.tier == ReminderTier.fading), isTrue);
      }
    });

    test('days 7 to 13 are comeback reminders five times a day', () {
      for (final day in [7, 13]) {
        final reminders = onDay(all, day);
        expect(reminders, hasLength(5));
        expect(
            reminders.every((r) => r.tier == ReminderTier.comeback), isTrue);
      }
    });

    test('the plan stops after day 13', () {
      expect(onDay(all, 14), isEmpty);
      expect(all, hasLength(3 + 2 * 4 + 4 * 5 + 7 * 5));
    });

    test('nothing is planned between 22:00 and 07:00', () {
      expect(all.every((r) => r.at.hour >= 7 && r.at.hour < 22), isTrue);
    });

    test('reminders are in time order and every one has the title', () {
      for (var i = 1; i < all.length; i++) {
        expect(all[i].at.isAfter(all[i - 1].at), isTrue);
      }
      expect(all.every((r) => r.title == 'title'), isTrue);
    });
  });

  test('count is the number of words due by each reminder', () {
    final all = plan([at(0, 7), at(0, 12), at(2, 10)], now: morning);
    int countAt(DateTime time) => all.singleWhere((r) => r.at == time).count;

    expect(countAt(at(0, 7)), 1);
    expect(countAt(at(0, 10)), 1);
    expect(countAt(at(0, 20)), 2);
    expect(countAt(at(1, 9)), 2);
    expect(countAt(at(2, 9)), 2);
    expect(countAt(at(2, 12)), 3);
    expect(all.first.body, endsWith(':1'));
  });

  test('two reminders in a row of the same tier never repeat a body', () {
    for (var seed = 0; seed < 50; seed++) {
      final all = plan([at(0, 7)], now: morning, seed: seed);
      for (var i = 1; i < all.length; i++) {
        if (all[i].tier != all[i - 1].tier) continue;
        final current = all[i].body.split(':').first;
        final previous = all[i - 1].body.split(':').first;
        expect(current, isNot(previous), reason: 'seed $seed, index $i');
      }
    }
  });

  test('a tier with a single body still works', () {
    final all = plan([at(0, 7)], now: morning, perTier: 1);
    expect(all, hasLength(66));
  });
}
