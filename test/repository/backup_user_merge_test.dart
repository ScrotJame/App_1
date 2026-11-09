import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:test_abc/database/app_db.dart';
import 'package:test_abc/repository/backup_data_repository.dart';

import 'backup_test_support.dart';

void main() {
  String backupJson({
    int gems = 0,
    int level = 1,
    int experience = 0,
    int currentStreak = 0,
    int longestStreak = 0,
    int totalLearned = 0,
    DateTime? lastActiveDate,
    required DateTime updatedAt,
  }) {
    return jsonEncode({
      'version': 2,
      'user': {
        'keyOpen': 'file-key',
        'username': 'Backup name',
        'gems': gems,
        'level': level,
        'experience': experience,
        'currentStreak': currentStreak,
        'longestStreak': longestStreak,
        'totalLearned': totalLearned,
        'lastActiveDate': lastActiveDate?.toIso8601String(),
        'createdAt': DateTime(2025, 6, 1).toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      },
    });
  }

  Future<UsersEntrieData> importInto(AppDatabase db, String json) async {
    final result = await BackupRepository(db).importFromJsonString(json);
    expect(result.success, isTrue, reason: result.error);
    return db.select(db.usersEntrie).getSingle();
  }

  test('restores progress onto a freshly created profile', () async {
    final db = await openDbWithUser('device', updatedAt: DateTime(2026, 5, 1));

    final user = await importInto(
      db,
      backupJson(
        gems: 300,
        level: 7,
        experience: 900,
        currentStreak: 5,
        longestStreak: 12,
        totalLearned: 200,
        lastActiveDate: DateTime(2026, 4, 30),
        updatedAt: DateTime(2026, 4, 30),
      ),
    );

    expect(user.gems, 300);
    expect(user.level, 7);
    expect(user.experience, 900);
    expect(user.currentStreak, 5);
    expect(user.longestStreak, 12);
    expect(user.totalLearned, 200);
  });

  test('an older file does not lower progress', () async {
    final db = await openDbWithUser(
      'device',
      gems: 500,
      level: 9,
      experience: 2000,
      currentStreak: 3,
      longestStreak: 20,
      totalLearned: 400,
      lastActiveDate: DateTime(2026, 5, 1),
      updatedAt: DateTime(2026, 5, 1),
    );

    final user = await importInto(
      db,
      backupJson(
        gems: 10,
        level: 2,
        experience: 50,
        currentStreak: 15,
        longestStreak: 15,
        totalLearned: 30,
        lastActiveDate: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      ),
    );

    expect(user.gems, 500);
    expect(user.level, 9);
    expect(user.experience, 2000);
    expect(user.currentStreak, 3);
    expect(user.longestStreak, 20);
    expect(user.totalLearned, 400);
    expect(user.lastActiveDate, DateTime(2026, 5, 1));
  });

  test('takes the streak pair from the file when it was active later', () async {
    final db = await openDbWithUser(
      'device',
      currentStreak: 9,
      lastActiveDate: DateTime(2026, 1, 1),
    );

    final user = await importInto(
      db,
      backupJson(
        currentStreak: 2,
        lastActiveDate: DateTime(2026, 5, 1),
        updatedAt: DateTime(2026, 1, 1),
      ),
    );

    expect(user.currentStreak, 2);
    expect(user.lastActiveDate, DateTime(2026, 5, 1));
  });

  test('username comes from the file only when the file is newer', () async {
    final olderFile = await openDbWithUser('a', updatedAt: DateTime(2026, 5, 1));
    expect(
      (await importInto(olderFile, backupJson(updatedAt: DateTime(2026, 1, 1))))
          .username,
      'Local name',
    );

    final newerFile = await openDbWithUser('b', updatedAt: DateTime(2026, 1, 1));
    expect(
      (await importInto(newerFile, backupJson(updatedAt: DateTime(2026, 5, 1))))
          .username,
      'Backup name',
    );
  });

  test('keeps the local id and the widest created and updated range', () async {
    final db = await openDbWithUser('device', updatedAt: DateTime(2026, 5, 1));
    final before = await db.select(db.usersEntrie).getSingle();

    final user = await importInto(db, backupJson(updatedAt: DateTime(2026, 1, 1)));

    expect(user.id, before.id);
    expect(user.createdAt, DateTime(2025, 6, 1));
    expect(user.updatedAt, DateTime(2026, 5, 1));
  });
}
