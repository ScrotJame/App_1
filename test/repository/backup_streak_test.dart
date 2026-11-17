import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:test_abc/database/app_db.dart';
import 'package:test_abc/helper/streak_date_helper.dart';
import 'package:test_abc/repository/backup_data_repository.dart';
import 'package:test_abc/repository/user_repository.dart';

import 'backup_test_support.dart';

void main() {
  // Import recomputes the streak against the real clock, so the days in
  // these tests are counted back from today.
  final today = StreakDateHelper.dateOnly(DateTime.now());
  String dayKey(int daysAgo) =>
      StreakDateHelper.keyOf(StreakDateHelper.daysBefore(today, daysAgo));

  Future<Set<String>> markedDays() async {
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getStringList(StreakDateHelper.prefKey) ?? []).toSet();
  }

  /// Marks the given days on the current device and syncs the user row.
  Future<void> completeDays(AppDatabase db, List<int> daysAgo) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
        StreakDateHelper.prefKey, daysAgo.map(dayKey).toList());
    await UserRepository(db).syncStreak();
  }

  /// A backup taken on another device that completed [daysAgo].
  Future<String> backupWithDays(List<int> daysAgo) async {
    final source = await openDbWithUser('source');
    await completeDays(source, daysAgo);
    final json = await BackupRepository(source).buildBackupJson();
    await source.close();
    return json;
  }

  Future<UsersEntrieData> importInto(AppDatabase db, String json) async {
    final result = await BackupRepository(db).importFromJsonString(json);
    expect(result.success, isTrue, reason: result.error);
    return db.select(db.usersEntrie).getSingle();
  }

  test('the backup file lists the completed streak days', () async {
    final json = await backupWithDays([2, 1, 0]);

    final decoded = jsonDecode(json) as Map<String, dynamic>;
    expect(decoded['streakDates'], [dayKey(2), dayKey(1), dayKey(0)]);
  });

  test('a restore on a new device keeps the streak', () async {
    final json = await backupWithDays([3, 2, 1, 0]);

    // openDbWithUser resets SharedPreferences: a device with no marked days.
    final target = await openDbWithUser('target');
    addTearDown(target.close);
    final user = await importInto(target, json);

    expect(user.currentStreak, 4);
    expect(user.longestStreak, 4);
    expect(user.lastActiveDate, today);
    expect(await markedDays(), {dayKey(3), dayKey(2), dayKey(1), dayKey(0)});
  });

  test('the restored streak survives the next sync', () async {
    final json = await backupWithDays([3, 2, 1, 0]);
    final target = await openDbWithUser('target');
    addTearDown(target.close);
    await importInto(target, json);

    await UserRepository(target).syncStreak();

    final user = await target.select(target.usersEntrie).getSingle();
    expect(user.currentStreak, 4);
  });

  test('days from the file extend the streak already on this device',
      () async {
    final json = await backupWithDays([4, 3, 2, 1]);
    final target = await openDbWithUser('target');
    addTearDown(target.close);
    await completeDays(target, [0]);

    final user = await importInto(target, json);

    expect(user.currentStreak, 5);
    expect(user.longestStreak, 5);
    expect(user.lastActiveDate, today);
  });

  test('an old file never shortens the streak on this device', () async {
    final json = await backupWithDays([11, 10]);
    final target = await openDbWithUser('target');
    addTearDown(target.close);
    await completeDays(target, [2, 1, 0]);

    final user = await importInto(target, json);

    expect(user.currentStreak, 3);
    expect(user.longestStreak, 3);
    expect(await markedDays(),
        {dayKey(11), dayKey(10), dayKey(2), dayKey(1), dayKey(0)});
  });

  test('importing the same file twice changes nothing', () async {
    final json = await backupWithDays([1, 0]);
    final target = await openDbWithUser('target');
    addTearDown(target.close);

    await importInto(target, json);
    final user = await importInto(target, json);

    expect(user.currentStreak, 2);
    expect(await markedDays(), {dayKey(1), dayKey(0)});
  });

  test('malformed and future days in a file are ignored', () async {
    final target = await openDbWithUser('target');
    addTearDown(target.close);
    final json = jsonEncode({
      'version': 2,
      'streakDates': [
        'not-a-date',
        '2026-02-31',
        dayKey(-1),
        dayKey(-400),
        dayKey(0),
      ],
    });

    final user = await importInto(target, json);

    expect(await markedDays(), {dayKey(0)});
    expect(user.currentStreak, 1);
  });

  test('a file without streak days leaves the marked days alone', () async {
    final target = await openDbWithUser('target');
    addTearDown(target.close);
    await completeDays(target, [1, 0]);
    final json = jsonEncode({
      'version': 2,
      'vocabularies': [
        {'id': 1, 'word': 'inu', 'meaning': 'con chó'},
      ],
    });

    final user = await importInto(target, json);

    expect(await markedDays(), {dayKey(1), dayKey(0)});
    expect(user.currentStreak, 2);
  });
}
