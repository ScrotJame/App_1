import 'dart:math' as math;

import 'package:drift/drift.dart';
import '../../models/entity/active_companion_entity.dart';
import '../../models/entity/companion_definition_entity.dart';
import '../database/app_db.dart';

class InsufficientFoodException implements Exception {
  final String message;
  const InsufficientFoodException([
    this.message = 'Không đủ food. Hãy học thêm từ để nhận food!',
  ]);
  @override
  String toString() => message;
}

class CompanionMaxLevelException implements Exception {
  final String message;
  const CompanionMaxLevelException([
    this.message = 'Companion đã đạt cấp tối đa!',
  ]);
  @override
  String toString() => message;
}

abstract class ICompanionRepository {
  Stream<ActiveCompanionEntity?> watchActiveCompanion(String userKey);
  Future<List<CompanionDefinitionEntity>> getDefinitionsByType(String type);
  Future<void> adoptCompanion({required String userKey, required int definitionId});
  Future<void> switchCompanion({required String userKey, required int newDefinitionId});
  Future<double> earnFood({required String userKey, required double wordsLearned});
  Future<void> feedCompanion({required String userKey});
}

class CompanionRepository implements ICompanionRepository {
  final AppDatabase _db;

  CompanionRepository(this._db);

  @override
  Stream<ActiveCompanionEntity?> watchActiveCompanion(String userKey) {
    final query = _db.select(_db.activeCompanions).join([
      innerJoin(
        _db.companionDefinitions,
        _db.companionDefinitions.id
            .equalsExp(_db.activeCompanions.definitionId),
      ),
    ])
      ..where(_db.activeCompanions.userKey.equals(userKey));

    return query.watchSingleOrNull().map((row) {
      if (row == null) return null;
      final active = row.readTable(_db.activeCompanions);
      final def = row.readTable(_db.companionDefinitions);
      return _toEntity(active, def);
    });
  }

  // ─────────────────────────────────────────────────────────────────────────
  // getDefinitionsByType
  // ─────────────────────────────────────────────────────────────────────────

  @override
  Future<List<CompanionDefinitionEntity>> getDefinitionsByType(String type) async {
    final rows = await (_db.select(_db.companionDefinitions)
      ..where((t) => t.type.equals(type))
      ..orderBy([(t) => OrderingTerm.asc(t.id)]))
        .get();
    return rows.map(_defToEntity).toList();
  }

  // ─────────────────────────────────────────────────────────────────────────
  // adoptCompanion
  // ─────────────────────────────────────────────────────────────────────────

  @override
  Future<void> adoptCompanion({
    required String userKey,
    required int definitionId,
  }) async {
    final def = await (_db.select(_db.companionDefinitions)
      ..where((t) => t.id.equals(definitionId)))
        .getSingle();

    await _db.into(_db.activeCompanions).insertOnConflictUpdate(
      ActiveCompanionsCompanion.insert(
        userKey: userKey,
        definitionId: definitionId,
        level: const Value(1),
        foodInventory: const Value(0),
        pendingWords: const Value(0),
        foodUsedInCurrentLevel: const Value(0),
        totalFoodUsed: const Value(0),
        totalWordsLearned: const Value(0),
        currentXpBonus: Value(def.maxXpBonus / def.maxLevel),
        isMaxLevel: const Value(false),
      ),
    );
  }

  @override
  Future<void> switchCompanion({
    required String userKey,
    required int newDefinitionId,
  }) async {
    await _db.transaction(() async {
      final current = await (_db.select(_db.activeCompanions)
        ..where((t) => t.userKey.equals(userKey)))
          .getSingleOrNull();

      if (current != null) {
        await _db.into(_db.companionHistories).insert(
          CompanionHistoriesCompanion.insert(
            userKey: userKey,
            definitionId: current.definitionId,
            levelReached: current.level,
            totalFoodUsed: current.totalFoodUsed,
            totalWordsLearned: current.totalWordsLearned,
            adoptedAt: current.adoptedAt,
          ),
        );

        await (_db.delete(_db.activeCompanions)
          ..where((t) => t.userKey.equals(userKey)))
            .go();
      }

      await adoptCompanion(userKey: userKey, definitionId: newDefinitionId);
    });
  }

  @override
  Future<double> earnFood({
    required String userKey,
    required double wordsLearned,
  }) async {
    return _db.transaction(() async {
      // 1. Đọc companion + definition
      final row = await (_db.select(_db.activeCompanions).join([
        innerJoin(
          _db.companionDefinitions,
          _db.companionDefinitions.id
              .equalsExp(_db.activeCompanions.definitionId),
        ),
      ])
        ..where(_db.activeCompanions.userKey.equals(userKey)))
          .getSingleOrNull();

      if (row == null) return 0;

      final active = row.readTable(_db.activeCompanions);
      final def = row.readTable(_db.companionDefinitions);

      final wordsPerFood = def.wordsPerFood;
      final maxInventory = def.maxFoodInventory;

      // 2. Tính food earned
      final totalPending = active.pendingWords + wordsLearned;
      final foodEarned = totalPending ~/ wordsPerFood;
      final remainingPending = totalPending % wordsPerFood;

      // 3. Cộng food vào inventory (capped)
      final newInventory =
      (active.foodInventory + foodEarned).clamp(0, maxInventory);
      final double actualFoodEarned = (newInventory - active.foodInventory).toDouble();

      // 4. Update ActiveCompanion
      await (_db.update(_db.activeCompanions)
        ..where((t) => t.userKey.equals(userKey)))
          .write(
        ActiveCompanionsCompanion(
          pendingWords: Value(remainingPending),
          foodInventory: Value(newInventory),
          totalWordsLearned: Value(active.totalWordsLearned + wordsLearned),
          updatedAt: Value(DateTime.now()),
        ),
      );

      // 5. Ghi log nếu có food được earn
      if (actualFoodEarned > 0) {
        await _db.into(_db.companionWordEarnLogs).insert(
          CompanionWordEarnLogsCompanion.insert(
            userKey: userKey,
            wordsLearned: wordsLearned,
            foodEarned: actualFoodEarned,
            definitionId: active.definitionId,
          ),
        );
      }

      return actualFoodEarned;
    });
  }

  @override
  Future<void> feedCompanion({required String userKey}) async {
    await _db.transaction(() async {
      final row = await (_db.select(_db.activeCompanions).join([
        innerJoin(
          _db.companionDefinitions,
          _db.companionDefinitions.id
              .equalsExp(_db.activeCompanions.definitionId),
        ),
      ])
        ..where(_db.activeCompanions.userKey.equals(userKey)))
          .getSingleOrNull();

      if (row == null) return;

      final active = row.readTable(_db.activeCompanions);
      final def = row.readTable(_db.companionDefinitions);

      // 2. Guard checks
      if (active.isMaxLevel) throw const CompanionMaxLevelException();
      if (active.foodInventory <= 0) throw const InsufficientFoodException();

      // 3. Tính food cần để lên cấp tiếp theo
      final foodNeeded = _foodNeededForLevel(
        level: active.level,
        base: def.baseFoodPerLevel,
        scalingPow: def.scalingPow,
      );

      final newFoodUsed = active.foodUsedInCurrentLevel + 1;
      final newTotalFoodUsed = active.totalFoodUsed + 1;
      final newInventory = active.foodInventory - 1;
      final didLevelUp = newFoodUsed >= foodNeeded;

      int newLevel = active.level;
      int newFoodUsedInLevel = newFoodUsed;
      bool newIsMaxLevel = active.isMaxLevel;
      double newXpBonus = active.currentXpBonus;

      if (didLevelUp) {
        newLevel = active.level + 1;
        newFoodUsedInLevel = 0;
        newIsMaxLevel = newLevel >= def.maxLevel;
        newXpBonus = def.maxXpBonus * (newLevel / def.maxLevel);
      }

      // Update ActiveCompanion
      await (_db.update(_db.activeCompanions)
        ..where((t) => t.userKey.equals(userKey)))
          .write(
        ActiveCompanionsCompanion(
          foodInventory: Value(newInventory),
          foodUsedInCurrentLevel: Value(newFoodUsedInLevel),
          totalFoodUsed: Value(newTotalFoodUsed),
          level: Value(newLevel),
          isMaxLevel: Value(newIsMaxLevel),
          currentXpBonus: Value(newXpBonus),
          updatedAt: Value(DateTime.now()),
        ),
      );

      await _db.into(_db.companionFoodLogs).insert(
        CompanionFoodLogsCompanion.insert(
          userKey: userKey,
          foodUsed: 1,
          levelAtTime: active.level,
          definitionId: active.definitionId,
          causedLevelUp: Value(didLevelUp),
        ),
      );
    });
  }

  int _foodNeededForLevel({
    required int level,
    required int base,
    required double scalingPow,
  }) {
    return (base * math.pow(level, scalingPow)).ceil();
  }

  ActiveCompanionEntity _toEntity(
      ActiveCompanion active,
      CompanionDefinition def,
      ) {
    return ActiveCompanionEntity(
      userKey: active.userKey,
      definitionId: active.definitionId,
      level: active.level,
      foodInventory: active.foodInventory,
      pendingWords: active.pendingWords,
      foodUsedInCurrentLevel: active.foodUsedInCurrentLevel,
      totalFoodUsed: active.totalFoodUsed,
      totalWordsLearned: active.totalWordsLearned,
      currentXpBonus: active.currentXpBonus,
      isMaxLevel: active.isMaxLevel,
      adoptedAt: active.adoptedAt,
      updatedAt: active.updatedAt,
      definition: _defToEntity(def),
    );
  }

  CompanionDefinitionEntity _defToEntity(CompanionDefinition def) {
    return CompanionDefinitionEntity(
      id: def.id,
      type: def.type,
      name: def.name,
      description: def.description,
      iconKey: def.iconKey,
      maxXpBonus: def.maxXpBonus,
      maxLevel: def.maxLevel,
      baseFoodPerLevel: def.baseFoodPerLevel,
      scalingPow: def.scalingPow,
      wordsPerFood: def.wordsPerFood,
      maxFoodInventory: def.maxFoodInventory,
      unlockUserLevel: def.unlockUserLevel,
    );
  }
}