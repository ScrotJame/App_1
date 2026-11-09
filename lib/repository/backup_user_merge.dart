import 'dart:math' as math;

import 'package:drift/drift.dart';

import '../database/app_db.dart';
import '../models/entity/user_entity.dart';

/// Merges a backed-up profile into the profile on this device, field by field.
///
/// A new device always has a just-created profile, so comparing updatedAt alone
/// would discard every restored value. Progress counters therefore only grow.
UsersEntrieCompanion mergeUserStats({
  required UsersEntrieData existing,
  required UserEntity backup,
  required String safeUsername,
  required int safeGems,
}) {
  final fileIsNewer =
      backup.updatedAt != null && backup.updatedAt!.isAfter(existing.updatedAt);
  final fileActiveLater = backup.lastActiveDate != null &&
      (existing.lastActiveDate == null ||
          backup.lastActiveDate!.isAfter(existing.lastActiveDate!));

  final backupCreatedAt = backup.createdAt;
  final createdAt =
      backupCreatedAt != null && backupCreatedAt.isBefore(existing.createdAt)
          ? backupCreatedAt
          : existing.createdAt;

  return UsersEntrieCompanion(
    username: Value(fileIsNewer ? safeUsername : existing.username),
    currentStreak: Value(
      fileActiveLater
          ? (backup.currentStreak ?? existing.currentStreak)
          : existing.currentStreak,
    ),
    lastActiveDate: Value(
      fileActiveLater ? backup.lastActiveDate : existing.lastActiveDate,
    ),
    longestStreak:
        Value(math.max(existing.longestStreak, backup.longestStreak ?? 0)),
    totalLearned:
        Value(math.max(existing.totalLearned, backup.totalLearned ?? 0)),
    gems: Value(math.max(existing.gems, safeGems)),
    level: Value(math.max(existing.level, backup.level ?? 0)),
    experience: Value(math.max(existing.experience, backup.experience ?? 0)),
    createdAt: Value(createdAt),
    updatedAt: Value(fileIsNewer ? backup.updatedAt! : existing.updatedAt),
  );
}
