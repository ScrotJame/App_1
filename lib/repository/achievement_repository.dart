import 'package:drift/drift.dart';
import 'package:test_abc/database/app_db.dart';

import '../models/entity/achivement_entity.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Types từ generated code (app_db_g.dart) — dùng đúng tên, không alias:
//
//  Table accessor : _db.achievementDefinitions      ($AchievementDefinitionsTable)
//  DataClass      : AchievementDefinition           (id: String, non-null fields)
//
//  Table accessor : _db.userAchievementProgress     ($UserAchievementProgressTable)
//  DataClass      : UserAchievementProgressData     (userKey, achievementId: String)
//  Companion      : UserAchievementProgressCompanion
//    .insert({ required userKey, required achievementId, Value currentValue,
//              Value isUnlocked, Value unlockedAt, Value updatedAt })
//
//  Primary key    : {userKey, achievementId}  → insertOnConflictUpdate hoạt động đúng
// ─────────────────────────────────────────────────────────────────────────────

abstract class IAchievementRepository {
  /// Kiểm tra & unlock sau mỗi hành động học.
  /// Trả về danh sách achievement vừa được unlock lần đầu (để hiện popup).
  Future<List<AchivementEntity>> checkAndUnlock({
    required String userKey,
    required int totalLearned,
    required int currentStreak,
    required int unitsCompleted,
    required DateTime learnedAt,
  });

  /// Toàn bộ thành tựu + progress của user (cho trang hiển thị).
  Future<List<AchivementEntity>> getAllAchievements({
    required String userKey,
  });

  /// Force-update currentValue cho 1 achievement (dùng khi cần sync từ server).
  /// [achievementId] là UUID String — khớp với AchievementDefinition.id.
  Future<void> updateProgress({
    required String userKey,
    required String achievementId,
    required int newValue,
  });
}

// ─────────────────────────────────────────────────────────────────────────────

class AchievementRepository implements IAchievementRepository {
  final AppDatabase _db;

  AchievementRepository(this._db);

  // ── getAllAchievements ──────────────────────────────────────────────────────
  // LEFT JOIN: lấy toàn bộ definition, gắn progress nếu có.
  // Thứ tự: sortOrder ASC.
  @override
  Future<List<AchivementEntity>> getAllAchievements({
    required String userKey,
  }) async {
    final defTable = _db.achievementDefinitions;
    final progTable = _db.userAchievementProgress;

    final rows = await (_db.select(defTable).join([
      leftOuterJoin(
        progTable,
        progTable.achievementId.equalsExp(defTable.id) &
        progTable.userKey.equals(userKey),
      ),
    ])
      ..orderBy([OrderingTerm.asc(defTable.sortOrder)]))
        .get();

    return rows
        .map((row) => _mapToEntity(
      row.readTable(defTable),
      row.readTableOrNull(progTable),
    ))
        .toList();
  }

  // ── checkAndUnlock ─────────────────────────────────────────────────────────
  // Chỉ xử lý những achievement chưa unlock.
  // Upsert progress theo primary key {userKey, achievementId}.
  // Trả về list mới unlock (lần đầu tiên) để Cubit bắn side-effect popup.
  @override
  Future<List<AchivementEntity>> checkAndUnlock({
    required String userKey,
    required int totalLearned,
    required int currentStreak,
    required int unitsCompleted,
    required DateTime learnedAt,
  }) async {
    final defTable = _db.achievementDefinitions;
    final progTable = _db.userAchievementProgress;

    final valueByCategory = <String, int>{
      'milestone': totalLearned,
      'streak': currentStreak,
      'collection': unitsCompleted,
    };

    // Chỉ lấy những achievement chưa unlock (tiết kiệm xử lý)
    final pendingRows = await (_db.select(defTable).join([
      leftOuterJoin(
        progTable,
        progTable.achievementId.equalsExp(defTable.id) &
        progTable.userKey.equals(userKey),
      ),
    ])
      ..where(
        progTable.userKey.isNull() |
        progTable.isUnlocked.equals(false),
      ))
        .get();

    final newlyUnlocked = <AchivementEntity>[];
    final now = DateTime.now();

    for (final row in pendingRows) {
      final def = row.readTable(defTable);
      final prog = row.readTableOrNull(progTable);

      final effectiveValue = _resolveEffectiveValue(
        def: def,
        valueByCategory: valueByCategory,
        learnedAt: learnedAt,
      );
      final shouldUnlock = effectiveValue >= def.targetValue;

      // Upsert dựa trên primary key {userKey, achievementId}
      await _db.into(progTable).insertOnConflictUpdate(
        UserAchievementProgressCompanion.insert(
          userKey: userKey,
          achievementId: def.id,
          currentValue: Value(effectiveValue),
          isUnlocked: Value(shouldUnlock),
          // Chỉ ghi unlockedAt nếu đây là lần đầu unlock
          unlockedAt: shouldUnlock && prog?.unlockedAt == null
              ? Value(now)
              : const Value.absent(),
          updatedAt: Value(now),
        ),
      );

      // Chỉ thêm vào newlyUnlocked nếu đây là lần đầu (trước đó chưa unlock)
      if (shouldUnlock && !(prog?.isUnlocked ?? false)) {
        newlyUnlocked.add(_mapToEntity(
          def,
          UserAchievementProgressData(
            userKey: userKey,
            achievementId: def.id,
            currentValue: effectiveValue,
            isUnlocked: true,
            unlockedAt: now,
            updatedAt: now,
          ),
        ));
      }
    }

    return newlyUnlocked;
  }

  // ── updateProgress ─────────────────────────────────────────────────────────
  // Force-update currentValue — không tự động unlock,
  // chỉ dùng khi sync từ server hoặc admin override.
  @override
  Future<void> updateProgress({
    required String userKey,
    required String achievementId,
    required int newValue,
  }) async {
    await (_db.update(_db.userAchievementProgress)
      ..where(
            (t) =>
        t.userKey.equals(userKey) &
        t.achievementId.equals(achievementId),
      ))
        .write(
      UserAchievementProgressCompanion(
        currentValue: Value(newValue),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  // ── PRIVATE HELPERS ────────────────────────────────────────────────────────

  /// Tính effective value theo category hoặc code đặc biệt.
  int _resolveEffectiveValue({
    required AchievementDefinition def,
    required Map<String, int> valueByCategory,
    required DateTime learnedAt,
  }) {
    // Special: night_owl — học sau 22:00
    if (def.code == 'night_owl') {
      return learnedAt.hour >= 22 ? 1 : 0;
    }
    return valueByCategory[def.category] ?? 0;
  }

  /// Null-defensive mapping: AchievementDefinition + optional progress → Entity.
  /// AchievementDefinition có tất cả field non-null → không cần ?? fallback.
  /// Progress nullable (user chưa bắt đầu) → dùng ?? với default an toàn.
  AchivementEntity _mapToEntity(
      AchievementDefinition def,
      UserAchievementProgressData? prog,
      ) {
    return AchivementEntity(
      id: def.id,
      code: def.code,
      category: def.category,
      titleKey: def.titleKey,
      descriptionKey: def.descriptionKey,
      iconKey: def.iconKey,
      targetValue: def.targetValue,
      sortOrder: def.sortOrder,
      isVisible: def.isVisible,
      currentValue: prog?.currentValue ?? 0,
      isUnlocked: prog?.isUnlocked ?? false,
      unlockedAt: prog?.unlockedAt,
    );
  }
}