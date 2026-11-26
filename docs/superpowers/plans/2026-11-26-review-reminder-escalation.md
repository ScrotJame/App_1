# Escalating Review Reminders Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the single one-shot review alarm with a 14-day plan of reminders that gets denser the longer the user ignores it, with tiered localized messages, and that survives reboots.

**Architecture:** A pure Dart planner (`ReviewReminderPlanner`) turns every reviewed word's reminder time into a list of `(time, tier, title, body)` reminders. `AlarmService.syncReviewReminder` (already called everywhere a word's level changes) sends the whole list to Android over the existing method channel. Kotlin sets one alarm per reminder, stores the list as JSON in SharedPreferences, and a new `BootReceiver` re-arms from that store after a reboot or app update.

**Tech Stack:** Flutter 3.41.2 / Dart 3, Drift, intl_utils (`S` class), flutter_test; Android Kotlin (AlarmManager, SharedPreferences, org.json, NotificationCompat).

**Spec:** `docs/superpowers/specs/2026-11-26-review-reminder-escalation-design.md`

## Global Constraints

- Never schedule a reminder between 22:00 and 07:00 (local time).
- Plan horizon: days `d = 0..13` after the anchor's day; nothing on day 14.
- Tiers: `d = 0` fresh (max 3, ≥2h apart: anchor, anchor+3h, 20:00); `d = 1–2` streak at 09:00, 12:00, 17:00, 20:00; `d = 3–6` fading and `d = 7–13` comeback at 08:00, 11:00, 14:00, 17:00, 20:00.
- Anchor = earliest reminder time; if not after `now`, `now + 1h`; then moved out of quiet hours (≥22:00 → 07:00 next day, <07:00 → 07:00 same day).
- Each tier has 5 bodies with a `count` placeholder; no two consecutive reminders of the same tier use the same body.
- No hardcoded UI text: strings go into both `lib/l10n/intl_en.arb` and `lib/l10n/intl_vi.arb`, then `flutter pub run intl_utils:generate`.
- Generated code is gitignored; never commit `lib/generated/` or `*.g.dart`.
- Avoid `!` in Dart. States/value classes use `Equatable`.
- `*.md` is gitignored; plan/spec files are committed with `git add -f`.
- Commit on branch `feature/review-reminder-escalation`. Commit message style: `type(scope): summary`.

## File Structure

| File | Responsibility |
|---|---|
| `lib/helper/review_reminder_planner.dart` (new) | Pure planning: tiers, slot times, counts, message choice |
| `test/helper/review_reminder_planner_test.dart` (new) | Unit tests for the planner |
| `lib/repository/vocabulary_repository.dart` | `reviewReminderTimes()` replaces `nextReviewReminderTime()` |
| `test/repository/vocabulary_word_level_test.dart` | Repository tests for `reviewReminderTimes()` |
| `lib/l10n/intl_en.arb`, `lib/l10n/intl_vi.arb` | Title + 20 tiered bodies; remove `review_reminder_message` |
| `lib/service/alarm_service.dart` | Builds messages from `S`, runs planner, sends `scheduleReviewPlan` |
| `test/page/learning/word_progress_flow_test.dart` | End-to-end channel expectations |
| `android/.../test_abc/ReviewPlanStore.kt` (new) | `ReviewReminder` data class + JSON persistence |
| `android/.../test_abc/AlarmScheduler.kt`, `AndroidAlarmScheduler.kt` | Plan scheduling, cancel, re-arm, exact/inexact fallback |
| `android/.../test_abc/AlarmReceiver.kt` | Shows review notifications from extras |
| `android/.../test_abc/BootReceiver.kt` (new) | Re-arms after boot / app update |
| `android/.../notification/NotificationHelper.kt` | `showReview(title, body)` with a fixed id |
| `android/.../test_abc/MainActivity.kt` | `scheduleReviewPlan` channel method |
| `android/app/src/main/AndroidManifest.xml` | Register `BootReceiver`, drop boot filter from `AlarmReceiver` |

`android/...` = `android/app/src/main/kotlin/com/example`.

---

### Task 1: Review reminder planner

**Files:**
- Create: `lib/helper/review_reminder_planner.dart`
- Test: `test/helper/review_reminder_planner_test.dart`

**Interfaces:**
- Consumes: nothing.
- Produces:
  - `enum ReminderTier { fresh, streak, fading, comeback }`
  - `typedef ReminderBody = String Function(int count);`
  - `class ReviewReminderMessages { const ReviewReminderMessages({required String title, required Map<ReminderTier, List<ReminderBody>> bodies}); final String title; final Map<ReminderTier, List<ReminderBody>> bodies; }`
  - `class ReviewReminder extends Equatable { final DateTime at; final ReminderTier tier; final int count; final String title; final String body; }`
  - `static List<ReviewReminder> ReviewReminderPlanner.plan({required List<DateTime> reminderTimes, required DateTime now, required ReviewReminderMessages messages, required Random random})` — sorted by `at`, empty when `reminderTimes` is empty.

- [ ] **Step 1: Write the failing tests**

Create `test/helper/review_reminder_planner_test.dart`:

```dart
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
```

- [ ] **Step 2: Run the tests to verify they fail**

Run: `flutter test test/helper/review_reminder_planner_test.dart`
Expected: FAIL to compile, `review_reminder_planner.dart` not found.

- [ ] **Step 3: Write the implementation**

Create `lib/helper/review_reminder_planner.dart`:

```dart
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
```

- [ ] **Step 4: Run the tests to verify they pass**

Run: `flutter test test/helper/review_reminder_planner_test.dart`
Expected: all tests PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/helper/review_reminder_planner.dart test/helper/review_reminder_planner_test.dart
git commit -m "feat(reminder): plan escalating review reminders for 14 days"
```

---

### Task 2: Repository returns every reminder time

**Files:**
- Modify: `lib/repository/vocabulary_repository.dart` (interface near line 100, implementation near line 383)
- Test: `test/repository/vocabulary_word_level_test.dart` (group `nextReviewReminderTime`, near line 304)

**Interfaces:**
- Consumes: `SetTimeHelper.reminderTime(int level, DateTime lastReviewed)` (existing, `lib/helper/set_time_helper.dart`).
- Produces: `Future<List<DateTime>> IVocabularyRepository.reviewReminderTimes()` — one entry per word with a non-null `lastReviewed`, including words already due. Order is not specified. `nextReviewReminderTime` stays for now; Task 3 removes it.

- [ ] **Step 1: Write the failing tests**

In `test/repository/vocabulary_word_level_test.dart`, add this group right after the closing `});` of `group('nextReviewReminderTime', ...)` (keep that group for now):

```dart
  group('reviewReminderTimes', () {
    test('is empty while no word has been reviewed', () async {
      expect(await repo.reviewReminderTimes(), isEmpty);
    });

    test('has one time per reviewed word, due ones included', () async {
      final other = await repo.insertWord(word: '犬', meaning: 'dog');
      await repo.levelUpIfDue(wordId, userKey, now: t0); // level 1: +15 min
      await repo.restartReviewWait(other, userKey, now: t0); // level 0: +5 min

      expect(
        await repo.reviewReminderTimes(),
        unorderedEquals([
          t0.add(const Duration(minutes: 15)),
          t0.add(const Duration(minutes: 5)),
        ]),
      );
    });

    test('forgets a word once it is deleted', () async {
      await repo.levelUpIfDue(wordId, userKey, now: t0);

      await repo.deleteWord(wordId);

      expect(await repo.reviewReminderTimes(), isEmpty);
    });
  });
```

(`t0` is `DateTime(2026, 3, 10, 9)`, so the times above are after 06:00 and `SetTimeHelper` adds the interval directly.)

- [ ] **Step 2: Run the tests to verify they fail**

Run: `flutter test test/repository/vocabulary_word_level_test.dart --plain-name "reviewReminderTimes"`
Expected: FAIL to compile, `reviewReminderTimes` isn't defined.

- [ ] **Step 3: Write the implementation**

In `lib/repository/vocabulary_repository.dart`, in `abstract class IVocabularyRepository`, add right after `Future<DateTime?> nextReviewReminderTime({DateTime? now});`:

```dart
  /// When each reviewed word should be reminded, one entry per word with a
  /// `lastReviewed`, words that are due already included.
  Future<List<DateTime>> reviewReminderTimes();
```

In `class VocabularyRepository`, add right after the `nextReviewReminderTime` implementation:

```dart
  @override
  Future<List<DateTime>> reviewReminderTimes() async {
    final reviewed = await (_db.select(_db.vocabularyEntries)
          ..where((t) => t.lastReviewed.isNotNull()))
        .get();
    return [
      for (final word in reviewed)
        if (word.lastReviewed case final lastReviewed?)
          SetTimeHelper.reminderTime(word.level, lastReviewed),
    ];
  }
```

- [ ] **Step 4: Run the tests to verify they pass**

Run: `flutter test test/repository/vocabulary_word_level_test.dart`
Expected: all tests PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/repository/vocabulary_repository.dart test/repository/vocabulary_word_level_test.dart
git commit -m "feat(reminder): list every reviewed word's reminder time"
```

---

### Task 3: Localized messages and sending the plan from AlarmService

**Files:**
- Modify: `lib/l10n/intl_en.arb`, `lib/l10n/intl_vi.arb`
- Modify: `lib/service/alarm_service.dart`
- Modify: `lib/repository/vocabulary_repository.dart` (remove `nextReviewReminderTime`)
- Modify: `test/repository/vocabulary_word_level_test.dart` (remove group `nextReviewReminderTime`)
- Test: `test/page/learning/word_progress_flow_test.dart`

**Interfaces:**
- Consumes: `ReviewReminderPlanner.plan`, `ReviewReminderMessages`, `ReminderTier`, `ReminderBody` (Task 1); `IVocabularyRepository.reviewReminderTimes()` (Task 2).
- Produces: method channel call `scheduleReviewPlan` with arguments `{'reminders': List<Map<String, Object>>}`, each map `{'at': int (epoch millis), 'title': String, 'body': String}`, sorted by `at`. `cancelReviewAlarm` (no args) when there is nothing to remind. `scheduleReviewAlarm` is no longer sent. Task 4 implements the Android side of exactly this contract.

- [ ] **Step 1: Update the flow tests to the new channel contract (failing)**

In `test/page/learning/word_progress_flow_test.dart`:

Replace the whole test `'one test sets one reminder, not one alarm per word'` with:

```dart
    test('one test sends one reminder plan, not one alarm per word', () async {
      final before = DateTime.now();

      await takeTest(isCorrect: (id) => id != wordIds[3]);

      expect(callsOf('scheduleAlarm'), isEmpty);
      final plans = callsOf('scheduleReviewPlan');
      expect(plans, hasLength(1));
      final reminders =
          (plans.single.arguments as Map)['reminders'] as List<Object?>;
      expect(reminders, isNotEmpty);
      final first = reminders.first as Map;
      expect(first['title'], S.current.review_reminder_title);
      expect(first['body'], isA<String>());
      final at = DateTime.fromMillisecondsSinceEpoch(first['at'] as int);
      expect(at.isAfter(before), isTrue);
      // The plan never starts before the earliest word is due.
      final times = await vocabulary.reviewReminderTimes();
      final earliest = times.reduce((a, b) => a.isBefore(b) ? a : b);
      expect(at.isBefore(earliest), isFalse);
    });
```

In test `'deleting the only reviewed word cancels the reminder'`, replace both occurrences of `callsOf('scheduleReviewAlarm')` with `callsOf('scheduleReviewPlan')`.

In test `'deleting one of two reviewed words keeps a reminder for the other'`, replace everything from `final args = callsOf('scheduleReviewAlarm')...` to the end of that test body with:

```dart
      final reminders = (callsOf('scheduleReviewPlan').single.arguments
          as Map)['reminders'] as List<Object?>;
      final first = reminders.first as Map;
      final times = await vocabulary.reviewReminderTimes();
      expect(times, hasLength(1));
      expect(
        DateTime.fromMillisecondsSinceEpoch(first['at'] as int)
            .isBefore(times.single),
        isFalse,
      );
```

In `test/repository/vocabulary_word_level_test.dart`, delete the whole `group('nextReviewReminderTime', () { ... });`.

- [ ] **Step 2: Run the flow tests to verify they fail**

Run: `flutter test test/page/learning/word_progress_flow_test.dart`
Expected: FAIL to compile, `review_reminder_title` isn't defined on `S`.

- [ ] **Step 3: Add the strings**

In `lib/l10n/intl_en.arb`, replace the line
`  "review_reminder_message": "Some of your words are ready for review.",`
with:

```json
  "review_reminder_title": "Time to review!",
  "review_reminder_fresh_1": "{count, plural, one{1 word is waiting for review.} other{{count} words are waiting for review.}}",
  "review_reminder_fresh_2": "{count, plural, one{Review time: 1 word is ready.} other{Review time: {count} words are ready.}}",
  "review_reminder_fresh_3": "{count, plural, one{A quick review now keeps 1 word fresh.} other{A quick review now keeps {count} words fresh.}}",
  "review_reminder_fresh_4": "{count, plural, one{1 word is due. It only takes a minute.} other{{count} words are due. It only takes a minute.}}",
  "review_reminder_fresh_5": "{count, plural, one{Now is the best moment to review 1 word.} other{Now is the best moment to review {count} words.}}",
  "review_reminder_streak_1": "{count, plural, one{Don't break your streak: 1 word is waiting.} other{Don't break your streak: {count} words are waiting.}}",
  "review_reminder_streak_2": "{count, plural, one{Keep your study streak going with 1 word today.} other{Keep your study streak going with {count} words today.}}",
  "review_reminder_streak_3": "{count, plural, one{Your streak is at risk: 1 word to review.} other{Your streak is at risk: {count} words to review.}}",
  "review_reminder_streak_4": "{count, plural, one{A short session saves your streak: 1 word.} other{A short session saves your streak: {count} words.}}",
  "review_reminder_streak_5": "{count, plural, one{Come back for 1 word and keep the streak alive.} other{Come back for {count} words and keep the streak alive.}}",
  "review_reminder_fading_1": "{count, plural, one{1 word is starting to slip from memory.} other{{count} words are starting to slip from memory.}}",
  "review_reminder_fading_2": "{count, plural, one{It has been a few days. Review 1 word before you forget it.} other{It has been a few days. Review {count} words before you forget them.}}",
  "review_reminder_fading_3": "{count, plural, one{Your memory of 1 word is fading. Catch it now.} other{Your memory of {count} words is fading. Catch them now.}}",
  "review_reminder_fading_4": "{count, plural, one{1 word you learned needs you back.} other{{count} words you learned need you back.}}",
  "review_reminder_fading_5": "{count, plural, one{Don't let your hard work fade: 1 word to review.} other{Don't let your hard work fade: {count} words to review.}}",
  "review_reminder_comeback_1": "{count, plural, one{Just 2 minutes for 1 word.} other{Just 2 minutes for {count} words.}}",
  "review_reminder_comeback_2": "{count, plural, one{We miss you! 1 word is waiting for you.} other{We miss you! {count} words are waiting for you.}}",
  "review_reminder_comeback_3": "{count, plural, one{Start again small: review 1 word today.} other{Start again small: review {count} words today.}}",
  "review_reminder_comeback_4": "{count, plural, one{Your words are still here: 1 to review.} other{Your words are still here: {count} to review.}}",
  "review_reminder_comeback_5": "{count, plural, one{One short session brings 1 word back.} other{One short session brings {count} words back.}}",
```

In `lib/l10n/intl_vi.arb`, replace the line
`  "review_reminder_message": "Đã đến lúc ôn lại từ vựng.",`
with:

```json
  "review_reminder_title": "Đến giờ ôn tập!",
  "review_reminder_fresh_1": "Có {count} từ đang chờ bạn ôn.",
  "review_reminder_fresh_2": "Đến giờ ôn rồi: {count} từ đã sẵn sàng.",
  "review_reminder_fresh_3": "Ôn nhanh bây giờ để nhớ chắc {count} từ.",
  "review_reminder_fresh_4": "{count} từ đã đến hạn ôn, chỉ mất một phút thôi.",
  "review_reminder_fresh_5": "Đây là lúc tốt nhất để ôn {count} từ.",
  "review_reminder_streak_1": "Đừng để chuỗi học bị đứt: {count} từ đang chờ.",
  "review_reminder_streak_2": "Giữ chuỗi ngày học với {count} từ hôm nay.",
  "review_reminder_streak_3": "Chuỗi học đang gặp nguy: còn {count} từ cần ôn.",
  "review_reminder_streak_4": "Một lượt ôn ngắn là giữ được chuỗi học: {count} từ.",
  "review_reminder_streak_5": "Quay lại ôn {count} từ để giữ chuỗi học nhé.",
  "review_reminder_fading_1": "{count} từ đang dần trôi khỏi trí nhớ.",
  "review_reminder_fading_2": "Đã mấy ngày rồi, ôn {count} từ trước khi quên mất nhé.",
  "review_reminder_fading_3": "Bạn sắp quên {count} từ rồi, ôn lại ngay thôi.",
  "review_reminder_fading_4": "{count} từ bạn đã học đang chờ bạn quay lại.",
  "review_reminder_fading_5": "Đừng để công sức học bị phai: còn {count} từ cần ôn.",
  "review_reminder_comeback_1": "Chỉ cần 2 phút cho {count} từ.",
  "review_reminder_comeback_2": "Nhớ bạn lắm! {count} từ vẫn đang chờ.",
  "review_reminder_comeback_3": "Bắt đầu lại nhẹ nhàng: ôn {count} từ hôm nay.",
  "review_reminder_comeback_4": "Từ vựng của bạn vẫn ở đây: {count} từ cần ôn.",
  "review_reminder_comeback_5": "Một lượt ôn ngắn sẽ kéo {count} từ quay về.",
```

Then regenerate:

Run: `flutter pub run intl_utils:generate`
Expected: completes; `lib/generated/l10n.dart` now has `String review_reminder_fresh_1(num count)` etc.

- [ ] **Step 4: Send the plan from AlarmService**

Replace `lib/service/alarm_service.dart` with:

```dart
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../generated/l10n.dart';
import '../helper/review_reminder_planner.dart';
import '../repository/vocabulary_repository.dart';

class AlarmService {
  static const MethodChannel _channel = MethodChannel('com.example.test_abc/alarm');

  /// Only Android has a native handler for the alarm channel.
  static bool get _isSupported =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  static Future<void> schedule(String word, int seconds) async {
    await _invoke('scheduleAlarm', {
      'message': word,
      'delaySeconds': seconds,
    });
  }

  /// Rebuilds the whole review reminder plan from the words' levels, or
  /// removes it when no reviewed word is left. Call it after anything that
  /// changes a word's level or deletes words: studying is what resets the
  /// escalation back to its first tier.
  static Future<void> syncReviewReminder(IVocabularyRepository repo) async {
    if (!_isSupported) return;
    try {
      final reminders = ReviewReminderPlanner.plan(
        reminderTimes: await repo.reviewReminderTimes(),
        now: DateTime.now(),
        messages: reviewReminderMessages(S.current),
        random: Random(),
      );
      if (reminders.isEmpty) {
        await _invoke('cancelReviewAlarm');
      } else {
        await _invoke('scheduleReviewPlan', {
          'reminders': [
            for (final r in reminders)
              <String, Object>{
                'at': r.at.millisecondsSinceEpoch,
                'title': r.title,
                'body': r.body,
              },
          ],
        });
      }
    } catch (e) {
      debugPrint('Review reminder not updated: $e');
    }
  }

  static ReviewReminderMessages reviewReminderMessages(S s) =>
      ReviewReminderMessages(
        title: s.review_reminder_title,
        bodies: {
          ReminderTier.fresh: [
            s.review_reminder_fresh_1,
            s.review_reminder_fresh_2,
            s.review_reminder_fresh_3,
            s.review_reminder_fresh_4,
            s.review_reminder_fresh_5,
          ],
          ReminderTier.streak: [
            s.review_reminder_streak_1,
            s.review_reminder_streak_2,
            s.review_reminder_streak_3,
            s.review_reminder_streak_4,
            s.review_reminder_streak_5,
          ],
          ReminderTier.fading: [
            s.review_reminder_fading_1,
            s.review_reminder_fading_2,
            s.review_reminder_fading_3,
            s.review_reminder_fading_4,
            s.review_reminder_fading_5,
          ],
          ReminderTier.comeback: [
            s.review_reminder_comeback_1,
            s.review_reminder_comeback_2,
            s.review_reminder_comeback_3,
            s.review_reminder_comeback_4,
            s.review_reminder_comeback_5,
          ],
        },
      );

  static Future<void> _invoke(String method, [Map<String, Object>? arguments]) async {
    if (!_isSupported) return;
    try {
      await _channel.invokeMethod(method, arguments);
    } on PlatformException catch (e) {
      debugPrint('Lỗi gọi Native: ${e.message}');
    } on MissingPluginException catch (e) {
      debugPrint('Lỗi gọi Native: ${e.message}');
    }
  }
}
```

(`S`'s generated methods take `num count`; a `String Function(num)` tear-off is a valid `ReminderBody`, i.e. `String Function(int)`.)

- [ ] **Step 5: Remove `nextReviewReminderTime`**

In `lib/repository/vocabulary_repository.dart`, delete `Future<DateTime?> nextReviewReminderTime({DateTime? now});` from the interface and the whole `@override Future<DateTime?> nextReviewReminderTime(...)` method from `VocabularyRepository`.

Run: `grep -rn "nextReviewReminderTime\|review_reminder_message\|scheduleReviewAlarm" lib test --include=*.dart | grep -v lib/generated`
Expected: no output.

- [ ] **Step 6: Run the tests to verify they pass**

Run: `flutter test test/page/learning/word_progress_flow_test.dart test/repository/vocabulary_word_level_test.dart test/helper/review_reminder_planner_test.dart`
Expected: all PASS.

Run: `flutter analyze --no-fatal-infos --no-fatal-warnings`
Expected: no errors.

- [ ] **Step 7: Commit**

```bash
git add lib/l10n/intl_en.arb lib/l10n/intl_vi.arb lib/service/alarm_service.dart lib/repository/vocabulary_repository.dart test/page/learning/word_progress_flow_test.dart test/repository/vocabulary_word_level_test.dart
git commit -m "feat(reminder): send the tiered reminder plan to Android"
```

---

### Task 4: Android side: schedule the plan, survive reboot, exact-alarm fallback

There is no Android unit test setup in this repo (`android/app/src/test` does not exist), so this task is verified by compiling the APK. On-device checks are listed in Step 9 for the human.

**Files:**
- Create: `android/app/src/main/kotlin/com/example/test_abc/ReviewPlanStore.kt`
- Create: `android/app/src/main/kotlin/com/example/test_abc/BootReceiver.kt`
- Modify: `android/app/src/main/kotlin/com/example/test_abc/AlarmScheduler.kt`
- Modify: `android/app/src/main/kotlin/com/example/test_abc/AndroidAlarmScheduler.kt`
- Modify: `android/app/src/main/kotlin/com/example/test_abc/AlarmReceiver.kt`
- Modify: `android/app/src/main/kotlin/com/example/test_abc/MainActivity.kt`
- Modify: `android/app/src/main/kotlin/com/example/notification/NotificationHelper.kt` (its package is `com.example.test_abc` despite the folder; keep it)
- Modify: `android/app/src/main/AndroidManifest.xml`

**Interfaces:**
- Consumes: channel `com.example.test_abc/alarm`, method `scheduleReviewPlan` with `{'reminders': [{'at': Long/Int millis, 'title': String, 'body': String}, ...]}`; method `cancelReviewAlarm` with no args (Task 3). Existing `scheduleAlarm` stays.
- Produces: alarms with request codes `2000 + index`, action `com.example.test_abc.REVIEW_REMINDER`; SharedPreferences file `review_reminders`, key `plan`.

- [ ] **Step 1: Create `ReviewPlanStore.kt`**

```kotlin
package com.example.test_abc

import android.content.Context
import org.json.JSONArray
import org.json.JSONException
import org.json.JSONObject

data class ReviewReminder(val atMillis: Long, val title: String, val body: String)

/** Keeps the last review plan so it can be set again after a reboot. */
class ReviewPlanStore(context: Context) {

    private val prefs = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)

    fun save(reminders: List<ReviewReminder>) {
        val array = JSONArray()
        reminders.forEach {
            array.put(
                JSONObject()
                    .put("at", it.atMillis)
                    .put("title", it.title)
                    .put("body", it.body)
            )
        }
        prefs.edit().putString(KEY_PLAN, array.toString()).apply()
    }

    fun load(): List<ReviewReminder> {
        val raw = prefs.getString(KEY_PLAN, null) ?: return emptyList()
        return try {
            val array = JSONArray(raw)
            (0 until array.length()).map { i ->
                val item = array.getJSONObject(i)
                ReviewReminder(
                    item.getLong("at"),
                    item.getString("title"),
                    item.getString("body")
                )
            }
        } catch (e: JSONException) {
            emptyList()
        }
    }

    fun clear() {
        prefs.edit().remove(KEY_PLAN).apply()
    }

    companion object {
        private const val PREFS = "review_reminders"
        private const val KEY_PLAN = "plan"
    }
}
```

- [ ] **Step 2: Replace `AlarmScheduler.kt`**

```kotlin
package com.example.test_abc

interface AlarmScheduler {
    fun schedule(item: AlarmItem)

    /** Replaces the whole review plan: one alarm per reminder. */
    fun scheduleReviewPlan(reminders: List<ReviewReminder>)

    /** Removes every review alarm and the stored plan. */
    fun cancelReview()

    /** Sets again the stored reminders that are still after [nowMillis]. */
    fun rearmFromStore(nowMillis: Long)
}
```

- [ ] **Step 3: Replace `AndroidAlarmScheduler.kt`**

```kotlin
package com.example.test_abc

import android.app.AlarmManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.os.Build
import java.time.ZoneId

class AndroidAlarmScheduler(private val context: Context) : AlarmScheduler {

    private val alarmManager = context.getSystemService(AlarmManager::class.java)
    private val store = ReviewPlanStore(context)

    override fun schedule(item: AlarmItem) {
        val intent = Intent(context, AlarmReceiver::class.java).apply {
            putExtra("Extra", item.message)
        }
        val triggerTimeMilli = item.time.atZone(ZoneId.systemDefault()).toInstant().toEpochMilli()
        val pendingIntent = PendingIntent.getBroadcast(
            context,
            item.hashCode(),
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        setAlarm(triggerTimeMilli, pendingIntent)
    }

    override fun scheduleReviewPlan(reminders: List<ReviewReminder>) {
        cancelReviewAlarms()
        reminders.take(MAX_REVIEW_REMINDERS).forEachIndexed { index, reminder ->
            setAlarm(reminder.atMillis, reviewPendingIntent(index, reminder))
        }
        store.save(reminders.take(MAX_REVIEW_REMINDERS))
    }

    override fun cancelReview() {
        cancelReviewAlarms()
        store.clear()
    }

    override fun rearmFromStore(nowMillis: Long) {
        store.load().forEachIndexed { index, reminder ->
            if (reminder.atMillis > nowMillis) {
                setAlarm(reminder.atMillis, reviewPendingIntent(index, reminder))
            }
        }
    }

    /**
     * Exact when the user allows it; otherwise an inexact alarm, because
     * setExactAndAllowWhileIdle throws on Android 12+ without the permission.
     */
    private fun setAlarm(atMillis: Long, pendingIntent: PendingIntent) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S && !alarmManager.canScheduleExactAlarms()) {
            alarmManager.setAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, atMillis, pendingIntent)
        } else {
            alarmManager.setExactAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, atMillis, pendingIntent)
        }
    }

    /**
     * Cancels by request code, not by the stored plan, so a lost or broken
     * store cannot leave alarms behind. Also drops the single alarm older
     * versions set.
     */
    private fun cancelReviewAlarms() {
        for (index in 0 until MAX_REVIEW_REMINDERS) {
            existing(REVIEW_REQUEST_CODE_BASE + index, reviewIntent(null))?.let {
                alarmManager.cancel(it)
                it.cancel()
            }
        }
        existing(LEGACY_REVIEW_REQUEST_CODE, Intent(context, AlarmReceiver::class.java))?.let {
            alarmManager.cancel(it)
            it.cancel()
        }
    }

    private fun existing(requestCode: Int, intent: Intent): PendingIntent? =
        PendingIntent.getBroadcast(
            context,
            requestCode,
            intent,
            PendingIntent.FLAG_NO_CREATE or PendingIntent.FLAG_IMMUTABLE
        )

    private fun reviewPendingIntent(index: Int, reminder: ReviewReminder): PendingIntent =
        PendingIntent.getBroadcast(
            context,
            REVIEW_REQUEST_CODE_BASE + index,
            reviewIntent(reminder),
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

    /** Extras do not take part in matching, so cancel can pass null. */
    private fun reviewIntent(reminder: ReviewReminder?): Intent =
        Intent(context, AlarmReceiver::class.java).apply {
            action = ACTION_REVIEW
            if (reminder != null) {
                putExtra(EXTRA_TITLE, reminder.title)
                putExtra(EXTRA_BODY, reminder.body)
            }
        }

    companion object {
        const val ACTION_REVIEW = "com.example.test_abc.REVIEW_REMINDER"
        const val EXTRA_TITLE = "title"
        const val EXTRA_BODY = "body"

        /** The planner makes at most 66; this leaves room. */
        private const val MAX_REVIEW_REMINDERS = 100
        private const val REVIEW_REQUEST_CODE_BASE = 2000
        private const val LEGACY_REVIEW_REQUEST_CODE = 1001
    }
}
```

- [ ] **Step 4: Replace `AlarmReceiver.kt`**

```kotlin
package com.example.test_abc

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

class AlarmReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context?, intent: Intent?) {
        val contextNonNull = context ?: return
        val intentNonNull = intent ?: return
        val notificationHelper = NotificationHelper(contextNonNull)

        if (intentNonNull.action == AndroidAlarmScheduler.ACTION_REVIEW) {
            val title = intentNonNull.getStringExtra(AndroidAlarmScheduler.EXTRA_TITLE) ?: return
            val body = intentNonNull.getStringExtra(AndroidAlarmScheduler.EXTRA_BODY) ?: return
            notificationHelper.showReview(title, body)
            return
        }

        val message = intentNonNull.getStringExtra("Extra") ?: return
        notificationHelper.showNotification(message)
    }
}
```

- [ ] **Step 5: Create `BootReceiver.kt`**

```kotlin
package com.example.test_abc

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

/** Android drops every alarm on reboot; set the stored review plan again. */
class BootReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context?, intent: Intent?) {
        val contextNonNull = context ?: return
        when (intent?.action) {
            Intent.ACTION_BOOT_COMPLETED,
            ACTION_QUICKBOOT_POWERON,
            Intent.ACTION_MY_PACKAGE_REPLACED ->
                AndroidAlarmScheduler(contextNonNull).rearmFromStore(System.currentTimeMillis())
        }
    }

    companion object {
        private const val ACTION_QUICKBOOT_POWERON = "android.intent.action.QUICKBOOT_POWERON"
    }
}
```

- [ ] **Step 6: Add `showReview` to `NotificationHelper.kt`**

Add this method inside `class NotificationHelper`, after `showNotification`, and a companion object at the end of the class:

```kotlin
    /** Review reminders share one id, so a new one replaces the last. */
    fun showReview(title: String, body: String) {
        val intent = Intent(context, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_SINGLE_TOP or Intent.FLAG_ACTIVITY_CLEAR_TOP
        }
        val pendingIntent = PendingIntent.getActivity(
            context,
            REVIEW_NOTIFICATION_ID,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        val notification = NotificationCompat.Builder(context, channelId)
            .setSmallIcon(R.drawable.ic_logo)
            .setContentTitle(title)
            .setContentText(body)
            .setStyle(NotificationCompat.BigTextStyle().bigText(body))
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .setContentIntent(pendingIntent)
            .setAutoCancel(true)
            .build()

        notificationManager.notify(REVIEW_NOTIFICATION_ID, notification)
    }

    companion object {
        private const val REVIEW_NOTIFICATION_ID = 4200
    }
```

- [ ] **Step 7: Wire the channel in `MainActivity.kt`**

Replace the whole `"scheduleReviewAlarm" -> { ... }` branch with:

```kotlin
                "scheduleReviewPlan" -> {
                    val raw = call.argument<List<Map<String, Any?>>>("reminders")
                    if (raw == null) {
                        result.error("bad_args", "reminders is required", null)
                    } else {
                        val reminders = raw.mapNotNull { item ->
                            val at = (item["at"] as? Number)?.toLong() ?: return@mapNotNull null
                            ReviewReminder(
                                at,
                                item["title"] as? String ?: "",
                                item["body"] as? String ?: ""
                            )
                        }
                        scheduler.scheduleReviewPlan(reminders)
                        result.success(true)
                    }
                }
```

Keep `"scheduleAlarm"` and `"cancelReviewAlarm"` as they are.

- [ ] **Step 8: Update `AndroidManifest.xml`**

Replace the `AlarmReceiver` block with these two receivers:

```xml
        <receiver
            android:name=".AlarmReceiver"
            android:enabled="true"
            android:exported="false" />

        <receiver
            android:name=".BootReceiver"
            android:enabled="true"
            android:exported="true">
            <intent-filter>
                <action android:name="android.intent.action.BOOT_COMPLETED" />
                <action android:name="android.intent.action.QUICKBOOT_POWERON" />
                <action android:name="android.intent.action.MY_PACKAGE_REPLACED" />
            </intent-filter>
        </receiver>
```

- [ ] **Step 9: Build to verify the Kotlin compiles**

Run: `flutter build apk --debug --flavor prod -t lib/main_prod.dart`
Expected: `Built build/app/outputs/flutter-apk/app-prod-debug.apk`.

On-device checks (for the human, not required to finish the task):
1. Review a few words, then `adb shell dumpsys alarm | grep -A3 test_abc` shows many alarms with action `REVIEW_REMINDER`.
2. A fired reminder shows the localized title and a tiered body; a second one replaces the first.
3. Reboot the device; the alarms are listed again.
4. Revoke "Alarms & reminders" for the app, review a word; alarms are still set (inexact).
5. Install over a build from `master`; alarm with request code 1001 is gone after the first review.

- [ ] **Step 10: Commit**

```bash
git add android/app/src/main/AndroidManifest.xml android/app/src/main/kotlin
git commit -m "feat(reminder): schedule the review plan natively and re-arm after boot"
```

---

### Task 5: Final verification

- [ ] **Step 1:** Run `flutter analyze --no-fatal-infos --no-fatal-warnings`. Expected: no errors.
- [ ] **Step 2:** Run `flutter test`. Expected: all PASS (report any failure that also fails on `219d33a` as pre-existing).
- [ ] **Step 3:** Run `flutter build apk --debug --flavor prod -t lib/main_prod.dart`. Expected: build succeeds.
