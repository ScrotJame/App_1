import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:test_abc/database/app_db.dart';
import 'package:test_abc/models/entity/achivement_entity.dart';
import 'package:test_abc/repository/achievement_repository.dart';
import 'package:test_abc/repository/backup_data_repository.dart';

import 'backup_test_support.dart';

void main() {
  /// Records progress the way the app does after a learning session.
  Future<void> reach(
    AppDatabase db,
    String userKey, {
    required int totalLearned,
    int currentStreak = 0,
  }) {
    return AchievementRepository(db).checkAndUnlock(
      userKey: userKey,
      totalLearned: totalLearned,
      currentStreak: currentStreak,
      unitsCompleted: 0,
      learnedAt: DateTime(2026, 3, 1, 10),
    );
  }

  Future<String> backupOf({
    required int totalLearned,
    int currentStreak = 0,
  }) async {
    final source = await openDbWithUser('source');
    await reach(source, 'source',
        totalLearned: totalLearned, currentStreak: currentStreak);
    final json = await BackupRepository(source).buildBackupJson();
    await source.close();
    return json;
  }

  Future<int> importInto(AppDatabase db, String json) async {
    final result = await BackupRepository(db).importFromJsonString(json);
    expect(result.success, isTrue, reason: result.error);
    return result.summary?.achievementsMerged ?? -1;
  }

  Future<Map<String?, AchivementEntity>> achievementsOf(
    AppDatabase db,
    String userKey,
  ) async {
    final all =
        await AchievementRepository(db).getAllAchievements(userKey: userKey);
    return {for (final a in all) a.code: a};
  }

  test('a restore on a new device brings the achievements back', () async {
    final json = await backupOf(totalLearned: 12, currentStreak: 3);
    // A new install: its achievement definitions have other ids.
    final target = await openDbWithUser('target');
    addTearDown(target.close);

    await importInto(target, json);

    final achievements = await achievementsOf(target, 'target');
    expect(achievements['first_word']?.isUnlocked, isTrue);
    expect(achievements['total_10']?.isUnlocked, isTrue);
    expect(achievements['total_10']?.unlockedAt, isNotNull);
    expect(achievements['streak_3']?.isUnlocked, isTrue);
    expect(achievements['total_50']?.isUnlocked, isFalse);
    expect(achievements['total_50']?.currentValue, 12);
  });

  test('an older file does not take back what the device reached', () async {
    final json = await backupOf(totalLearned: 12);
    final target = await openDbWithUser('target');
    addTearDown(target.close);
    await reach(target, 'target', totalLearned: 60);

    await importInto(target, json);

    final achievements = await achievementsOf(target, 'target');
    expect(achievements['total_50']?.isUnlocked, isTrue);
    expect(achievements['total_100']?.currentValue, 60);
  });

  test('a file that is further along raises the device', () async {
    final json = await backupOf(totalLearned: 60);
    final target = await openDbWithUser('target');
    addTearDown(target.close);
    await reach(target, 'target', totalLearned: 12);

    await importInto(target, json);

    final achievements = await achievementsOf(target, 'target');
    expect(achievements['total_10']?.isUnlocked, isTrue);
    expect(achievements['total_50']?.isUnlocked, isTrue);
    expect(achievements['total_100']?.currentValue, 60);
  });

  test('importing the same file twice changes nothing the second time',
      () async {
    final json = await backupOf(totalLearned: 12);
    final target = await openDbWithUser('target');
    addTearDown(target.close);

    final first = await importInto(target, json);
    final second = await importInto(target, json);

    expect(first, greaterThan(0));
    expect(second, 0);
  });

  test('an achievement this app does not know is skipped', () async {
    final target = await openDbWithUser('target');
    addTearDown(target.close);
    final json = jsonEncode({
      'version': 2,
      'achievementProgress': [
        {'code': 'from_a_newer_app', 'currentValue': 3, 'isUnlocked': true},
        {'code': 'first_word', 'currentValue': 1, 'isUnlocked': true},
      ],
    });

    final merged = await importInto(target, json);

    expect(merged, 1);
    final achievements = await achievementsOf(target, 'target');
    expect(achievements['first_word']?.isUnlocked, isTrue);
    expect(await target.select(target.userAchievementProgress).get(),
        hasLength(1));
  });
}
