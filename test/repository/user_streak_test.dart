import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:test_abc/database/app_db.dart';
import 'package:test_abc/helper/streak_date_helper.dart';
import 'package:test_abc/repository/user_repository.dart';

import 'backup_test_support.dart';

void main() {
  /// Evening of the n-th day of a run that starts on 10 March 2026.
  DateTime evening(int day) => DateTime(2026, 3, 10 + day, 21, 30);
  DateTime morning(int day) => DateTime(2026, 3, 10 + day, 7);
  DateTime date(int day) => DateTime(2026, 3, 10 + day);

  late AppDatabase db;
  late UserRepository repo;

  Future<UsersEntrieData> readUser() => db.select(db.usersEntrie).getSingle();

  Future<Set<String>> markedDays() async {
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getStringList(StreakDateHelper.prefKey) ?? []).toSet();
  }

  /// Completes the daily quests on `count` consecutive days.
  Future<void> completeDays(int count) async {
    for (var day = 0; day < count; day++) {
      await repo.markTodayStreak(now: evening(day));
    }
  }

  setUp(() async {
    db = await openDbWithUser('device');
    addTearDown(db.close);
    repo = UserRepository(db);
  });

  test('each completed day extends the streak', () async {
    expect(await repo.markTodayStreak(now: evening(0)), 1);
    expect(await repo.markTodayStreak(now: evening(1)), 2);
    expect(await repo.markTodayStreak(now: evening(2)), 3);

    final user = await readUser();
    expect(user.currentStreak, 3);
    expect(user.longestStreak, 3);
  });

  test('lastActiveDate is the latest completed day, not the first', () async {
    await completeDays(4);

    expect((await readUser()).lastActiveDate, date(3));
  });

  test('marking the same day twice counts once', () async {
    await repo.markTodayStreak(now: evening(0));
    await repo.markTodayStreak(now: evening(0).add(const Duration(hours: 1)));

    expect((await readUser()).currentStreak, 1);
    expect(await markedDays(), {'2026-03-10'});
  });

  test('yesterday still counts before today is completed', () async {
    await completeDays(2);

    await repo.syncStreak(now: morning(2));

    final user = await readUser();
    expect(user.currentStreak, 2);
    expect(user.lastActiveDate, date(1));
  });

  test('a missed day resets the streak and keeps the longest', () async {
    await completeDays(3);

    await repo.syncStreak(now: morning(4));

    final user = await readUser();
    expect(user.currentStreak, 0);
    expect(user.longestStreak, 3);
    expect(user.lastActiveDate, isNull);
  });

  test('rebuilds the same streak when the marked days are lost', () async {
    await completeDays(4);
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(StreakDateHelper.prefKey);

    await repo.syncStreak(now: morning(4));

    final user = await readUser();
    expect(user.currentStreak, 4);
    expect(user.longestStreak, 4);
    expect(user.lastActiveDate, date(3));
    expect(await markedDays(),
        {'2026-03-10', '2026-03-11', '2026-03-12', '2026-03-13'});
  });

  test('corrects a lastActiveDate left on the first day of the streak',
      () async {
    // State written by the old syncStreak: four marked days, lastActiveDate
    // still on day one.
    await completeDays(4);
    await (db.update(db.usersEntrie)).write(
      UsersEntrieCompanion(lastActiveDate: Value(date(0))),
    );

    await repo.syncStreak(now: evening(3));

    expect((await readUser()).lastActiveDate, date(3));
  });

  group('StreakDateHelper', () {
    test('parses only real yyyy-MM-dd days', () {
      expect(StreakDateHelper.tryParseKey('2026-03-10'), DateTime(2026, 3, 10));
      expect(StreakDateHelper.tryParseKey('2026-02-31'), isNull);
      expect(StreakDateHelper.tryParseKey('2026-3-1'), isNull);
      expect(StreakDateHelper.tryParseKey('not a date'), isNull);
    });

    test('a run crosses month boundaries by calendar day', () {
      expect(
        StreakDateHelper.runEndingOn(DateTime(2026, 3, 1, 15), 3),
        {'2026-03-01', '2026-02-28', '2026-02-27'},
      );
    });
  });
}
