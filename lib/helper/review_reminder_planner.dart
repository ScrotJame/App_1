import 'dart:math';

import 'package:equatable/equatable.dart';

/// How long the user has ignored their due words, which sets how often and
/// in which tone they are reminded.
enum ReminderTier { fresh, streak, fading, comeback }

typedef ReminderBody = String Function(int count);

class ReviewReminderMessages {
  const ReviewReminderMessages({required this.title, required this.bodies});

  final String title;
  final Map<ReminderTier, List<ReminderBody>> bodies;
}

class ReviewReminder extends Equatable {
  const ReviewReminder({
    required this.at,
    required this.tier,
    required this.count,
    required this.title,
    required this.body,
  });

  final DateTime at;
  final ReminderTier tier;

  /// Words due by [at].
  final int count;
  final String title;
  final String body;

  @override
  List<Object?> get props => [at, tier, count, title, body];
}

/// Plans every review reminder for the next [horizonDays] days at once.
///
/// The plan starts when the earliest reviewed word becomes due and gets
/// denser each day the user stays away. It is rebuilt from scratch every
/// time the user studies, which is what resets it.
class ReviewReminderPlanner {
  static const int horizonDays = 14;
  static const int dayStartHour = 7;
  static const int quietStartHour = 22;
  static const Duration overdueDelay = Duration(hours: 1);
  static const Duration freshFollowUp = Duration(hours: 3);
  static const Duration freshMinGap = Duration(hours: 2);
  static const int freshEveningHour = 20;

  static const List<int> _streakHours = [9, 12, 17, 20];
  static const List<int> _lateHours = [8, 11, 14, 17, 20];

  static List<ReviewReminder> plan({
    required List<DateTime> reminderTimes,
    required DateTime now,
    required ReviewReminderMessages messages,
    required Random random,
  }) {
    if (reminderTimes.isEmpty) return const [];
    final sorted = [...reminderTimes]..sort();

    var anchor = sorted.first;
    if (!anchor.isAfter(now)) anchor = now.add(overdueDelay);
    anchor = _outOfQuietHours(anchor);

    final slots = <_Slot>[
      for (final time in _freshTimes(anchor)) _Slot(time, ReminderTier.fresh),
      for (var day = 1; day < horizonDays; day++)
        for (final hour in _hoursFor(tierForDay(day)))
          _Slot(
            DateTime(anchor.year, anchor.month, anchor.day + day, hour),
            tierForDay(day),
          ),
    ];

    final reminders = <ReviewReminder>[];
    ReminderTier? lastTier;
    var lastIndex = -1;
    for (final slot in slots) {
      final pool = messages.bodies[slot.tier] ?? const <ReminderBody>[];
      if (pool.isEmpty) continue;
      final index = slot.tier == lastTier
          ? _pickOther(pool.length, lastIndex, random)
          : random.nextInt(pool.length);
      lastTier = slot.tier;
      lastIndex = index;

      final count = sorted.where((t) => !t.isAfter(slot.at)).length;
      reminders.add(ReviewReminder(
        at: slot.at,
        tier: slot.tier,
        count: count,
        title: messages.title,
        body: pool[index](count),
      ));
    }
    return reminders;
  }

  /// Tier for the [day]-th calendar day after the anchor's day.
  static ReminderTier tierForDay(int day) {
    if (day <= 0) return ReminderTier.fresh;
    if (day <= 2) return ReminderTier.streak;
    if (day <= 6) return ReminderTier.fading;
    return ReminderTier.comeback;
  }

  static List<int> _hoursFor(ReminderTier tier) =>
      tier == ReminderTier.streak ? _streakHours : _lateHours;

  static DateTime _outOfQuietHours(DateTime time) {
    if (time.hour >= quietStartHour) {
      return DateTime(time.year, time.month, time.day + 1, dayStartHour);
    }
    if (time.hour < dayStartHour) {
      return DateTime(time.year, time.month, time.day, dayStartHour);
    }
    return time;
  }

  static List<DateTime> _freshTimes(DateTime anchor) {
    final candidates = [
      anchor,
      anchor.add(freshFollowUp),
      DateTime(anchor.year, anchor.month, anchor.day, freshEveningHour),
    ]..sort();

    final kept = <DateTime>[];
    for (final time in candidates) {
      if (time.isBefore(anchor)) continue;
      if (!_sameDay(time, anchor)) continue;
      if (time.hour < dayStartHour || time.hour >= quietStartHour) continue;
      if (kept.isNotEmpty && time.difference(kept.last) < freshMinGap) {
        continue;
      }
      kept.add(time);
    }
    return kept;
  }

  static bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  /// A random index in `0..length-1` other than [previous] when possible.
  static int _pickOther(int length, int previous, Random random) {
    if (length < 2 || previous < 0) return random.nextInt(length);
    final pick = random.nextInt(length - 1);
    return pick >= previous ? pick + 1 : pick;
  }
}

class _Slot {
  const _Slot(this.at, this.tier);

  final DateTime at;
  final ReminderTier tier;
}
