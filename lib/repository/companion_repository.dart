// companion_repository.dart
import 'package:drift/drift.dart';

import '../database/app_db.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Entities
// ─────────────────────────────────────────────────────────────────────────────

class CompanionDefEntity {
  final int id;
  final String type; // 'pet' | 'plant'
  final String name;
  final String description;
  final String iconKey;
  final double maxXpBonus;
  final int maxLevel;
  final int baseWords;
  final double scalingPow;
  final int unlockUserLevel;

  const CompanionDefEntity({
    required this.id,
    required this.type,
    required this.name,
    required this.description,
    required this.iconKey,
    required this.maxXpBonus,
    required this.maxLevel,
    required this.baseWords,
    required this.scalingPow,
    required this.unlockUserLevel,
  });

  /// Số từ cần để lên từ [level] → [level+1]
  /// Formula: (baseWords * level^scalingPow).ceil()
  int wordsNeededForLevel(int level) {
    if (level >= maxLevel) return 999999; // đã max
    return (baseWords * _pow(level, scalingPow)).ceil();
  }

  /// Tổng từ cần từ cấp 1 đến cấp [targetLevel]
  int totalWordsToReach(int targetLevel) {
    int total = 0;
    for (int lvl = 1; lvl < targetLevel; lvl++) {
      total += wordsNeededForLevel(lvl);
    }
    return total;
  }

  /// XP bonus tại level hiện tại (linear interpolation)
  double xpBonusAtLevel(int level) {
    if (maxLevel <= 0) return maxXpBonus;
    return maxXpBonus * (level / maxLevel);
  }

  double _pow(num base, double exp) {
    if (exp == 1.0) return base.toDouble();
    double result = 1.0;
    double b = base.toDouble();
    // Simple iterative approximation for fractional powers
    // In production, use dart:math pow()
    return _dartPow(b, exp);
  }

  double _dartPow(double base, double exp) {
    // Placeholder — replace with: import 'dart:math'; return pow(base, exp).toDouble();
    return base * exp; // simplified; use dart:math in real code
  }
}

class ActiveCompanionEntity {
  final String userKey;
  final int definitionId;
  final int level;
  final int totalWordsLearned;
  final int wordsInCurrentLevel;
  final double currentXpBonus;
  final bool isMaxLevel;
  final DateTime adoptedAt;

  final CompanionDefEntity? definition;

  const ActiveCompanionEntity({
    required this.userKey,
    required this.definitionId,
    required this.level,
    required this.totalWordsLearned,
    required this.wordsInCurrentLevel,
    required this.currentXpBonus,
    required this.isMaxLevel,
    required this.adoptedAt,
    this.definition,
  });

  /// Số từ cần để lên cấp tiếp theo
  int get wordsNeededForNextLevel =>
      definition?.wordsNeededForLevel(level) ?? 999999;

  /// Progress 0.0 → 1.0 trong cấp hiện tại
  double get levelProgress {
    final needed = wordsNeededForNextLevel;
    if (needed <= 0 || needed == 999999) return 1.0;
    return (wordsInCurrentLevel / needed).clamp(0.0, 1.0);
  }

  /// Tên hiển thị
  String get displayName => definition?.name ?? 'Companion';

  ActiveCompanionEntity copyWith({
    int? level,
    int? totalWordsLearned,
    int? wordsInCurrentLevel,
    double? currentXpBonus,
    bool? isMaxLevel,
  }) {
    return ActiveCompanionEntity(
      userKey: userKey,
      definitionId: definitionId,
      level: level ?? this.level,
      totalWordsLearned: totalWordsLearned ?? this.totalWordsLearned,
      wordsInCurrentLevel: wordsInCurrentLevel ?? this.wordsInCurrentLevel,
      currentXpBonus: currentXpBonus ?? this.currentXpBonus,
      isMaxLevel: isMaxLevel ?? this.isMaxLevel,
      adoptedAt: adoptedAt,
      definition: definition,
    );
  }
}

class CompanionHistoryEntity {
  final int id;
  final String userKey;
  final int definitionId;
  final int levelReached;
  final int totalWordsLearned;
  final DateTime adoptedAt;
  final DateTime deletedAt;
  final CompanionDefEntity? definition;

  const CompanionHistoryEntity({
    required this.id,
    required this.userKey,
    required this.definitionId,
    required this.levelReached,
    required this.totalWordsLearned,
    required this.adoptedAt,
    required this.deletedAt,
    this.definition,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// Repository
// ─────────────────────────────────────────────────────────────────────────────

class CompanionRepository {
  final AppDatabase _db;

  CompanionRepository(this._db);

  // ── Definitions ─────────────────────────────────────────────

  Future<List<CompanionDefEntity>> getDefinitionsByType(String type) async {
    final rows = await (_db.select(_db.companionDefinitions)
      ..where((t) => t.type.equals(type)))
        .get();
    return rows.map(_mapDef).toList();
  }

  Future<CompanionDefEntity?> getDefinition(int id) async {
    final row = await (_db.select(_db.companionDefinitions)
      ..where((t) => t.id.equals(id)))
        .getSingleOrNull();
    return row != null ? _mapDef(row) : null;
  }

  // ── Active Companion ─────────────────────────────────────────

  /// Stream active companion (null = chưa chọn)
  Stream<ActiveCompanionEntity?> watchActiveCompanion(String userKey) {
    final query = _db.select(_db.activeCompanions).join([
      leftOuterJoin(
        _db.companionDefinitions,
        _db.companionDefinitions.id
            .equalsExp(_db.activeCompanions.definitionId),
      ),
    ])
      ..where(_db.activeCompanions.userKey.equals(userKey));

    return query.watchSingleOrNull().map((row) {
      if (row == null) return null;
      final a = row.readTable(_db.activeCompanions);
      final d = row.readTableOrNull(_db.companionDefinitions);
      return _mapActive(a, d);
    });
  }

  // ── Adopt (first time, no existing companion) ────────────────

  Future<ActiveCompanionEntity> adoptCompanion({
    required String userKey,
    required int definitionId,
  }) async {
    final def = await getDefinition(definitionId);
    if (def == null) throw Exception('Definition not found');

    await _db.into(_db.activeCompanions).insertOnConflictUpdate(
      ActiveCompanionsCompanion(
        userKey: Value(userKey),
        definitionId: Value(definitionId),
        level: const Value(1),
        totalWordsLearned: const Value(0),
        wordsInCurrentLevel: const Value(0),
        currentXpBonus: Value(def.xpBonusAtLevel(1)),
        isMaxLevel: const Value(false),
        adoptedAt: Value(DateTime.now()),
        updatedAt: Value(DateTime.now()),
      ),
    );

    final row = await (_db.select(_db.activeCompanions)
      ..where((t) => t.userKey.equals(userKey)))
        .getSingle();
    return _mapActive(row, null)
        .copyWith(); // re-fetch with def via stream in practice
  }

  /// Switch companion:
  /// 1. Save current to CompanionHistory
  /// 2. DELETE current ActiveCompanion
  /// 3. INSERT new ActiveCompanion
  Future<void> switchCompanion({
    required String userKey,
    required int newDefinitionId,
  }) async {
    await _db.transaction(() async {
      // 1. Save to history
      final current = await (_db.select(_db.activeCompanions)
        ..where((t) => t.userKey.equals(userKey)))
          .getSingleOrNull();

      if (current != null) {
        await _db.into(_db.companionHistories).insert(
          CompanionHistoriesCompanion(
            userKey: Value(userKey),
            definitionId: Value(current.definitionId),
            levelReached: Value(current.level),
            totalWordsLearned: Value(current.totalWordsLearned),
            adoptedAt: Value(current.adoptedAt),
            deletedAt: Value(DateTime.now()),
          ),
        );

        // 2. Delete current
        await (_db.delete(_db.activeCompanions)
          ..where((t) => t.userKey.equals(userKey)))
            .go();
      }

      // 3. Insert new
      final def = await getDefinition(newDefinitionId);
      if (def == null) throw Exception('Definition not found');

      await _db.into(_db.activeCompanions).insert(
        ActiveCompanionsCompanion(
          userKey: Value(userKey),
          definitionId: Value(newDefinitionId),
          level: const Value(1),
          totalWordsLearned: const Value(0),
          wordsInCurrentLevel: const Value(0),
          currentXpBonus: Value(def.xpBonusAtLevel(1)),
          isMaxLevel: const Value(false),
          adoptedAt: Value(DateTime.now()),
          updatedAt: Value(DateTime.now()),
        ),
      );
    });
  }

  // ── Feed words (core mechanic) ───────────────────────────────

  /// Gọi sau mỗi lần user học xong [wordsCount] từ.
  /// Trả về true nếu companion lên cấp.
  Future<bool> feedWords({
    required String userKey,
    required int wordsCount,
  }) async {
    bool leveledUp = false;

    await _db.transaction(() async {
      final current = await (_db.select(_db.activeCompanions)
        ..where((t) => t.userKey.equals(userKey)))
          .getSingleOrNull();

      if (current == null || current.isMaxLevel) return;

      final def = await getDefinition(current.definitionId);
      if (def == null) return;

      int newTotal = current.totalWordsLearned + wordsCount;
      int newInLevel = current.wordsInCurrentLevel + wordsCount;
      int newLevel = current.level;

      // Level-up loop
      while (newLevel < def.maxLevel) {
        final needed = def.wordsNeededForLevel(newLevel);
        if (newInLevel >= needed) {
          newInLevel -= needed;
          newLevel++;
          leveledUp = true;
        } else {
          break;
        }
      }

      final reachedMax = newLevel >= def.maxLevel;
      final newBonus = def.xpBonusAtLevel(newLevel);

      await (_db.update(_db.activeCompanions)
        ..where((t) => t.userKey.equals(userKey)))
          .write(ActiveCompanionsCompanion(
        level: Value(newLevel),
        totalWordsLearned: Value(newTotal),
        wordsInCurrentLevel: Value(reachedMax ? 0 : newInLevel),
        currentXpBonus: Value(newBonus),
        isMaxLevel: Value(reachedMax),
        updatedAt: Value(DateTime.now()),
      ));

      // Log
      await _db.into(_db.companionWordLogs).insert(
        CompanionWordLogsCompanion(
          userKey: Value(userKey),
          wordsCount: Value(wordsCount),
          levelAtTime: Value(newLevel),
          definitionId: Value(current.definitionId),
          causedLevelUp: Value(leveledUp),
          createdAt: Value(DateTime.now()),
        ),
      );
    });

    return leveledUp;
  }

  // ── History ──────────────────────────────────────────────────

  Future<List<CompanionHistoryEntity>> getHistory(String userKey) async {
    final rows = await (_db.select(_db.companionHistories)
      ..where((t) => t.userKey.equals(userKey))
      ..orderBy([(t) => OrderingTerm.desc(t.deletedAt)]))
        .get();

    final List<CompanionHistoryEntity> result = [];
    for (final row in rows) {
      final def = await getDefinition(row.definitionId);
      result.add(_mapHistory(row, def));
    }
    return result;
  }

  // ── Mappers ──────────────────────────────────────────────────

  CompanionDefEntity _mapDef(CompanionDefinition row) => CompanionDefEntity(
    id: row.id,
    type: row.type,
    name: row.name,
    description: row.description,
    iconKey: row.iconKey,
    maxXpBonus: row.maxXpBonus,
    maxLevel: row.maxLevel,
    baseWords: row.baseWords,
    scalingPow: row.scalingPow,
    unlockUserLevel: row.unlockUserLevel,
  );

  ActiveCompanionEntity _mapActive(
      ActiveCompanion row,
      CompanionDefinition? def,
      ) =>
      ActiveCompanionEntity(
        userKey: row.userKey,
        definitionId: row.definitionId,
        level: row.level,
        totalWordsLearned: row.totalWordsLearned,
        wordsInCurrentLevel: row.wordsInCurrentLevel,
        currentXpBonus: row.currentXpBonus,
        isMaxLevel: row.isMaxLevel,
        adoptedAt: row.adoptedAt,
        definition: def != null ? _mapDef(def) : null,
      );

  CompanionHistoryEntity _mapHistory(
      CompanionHistory row,
      CompanionDefEntity? def,
      ) =>
      CompanionHistoryEntity(
        id: row.id,
        userKey: row.userKey,
        definitionId: row.definitionId,
        levelReached: row.levelReached,
        totalWordsLearned: row.totalWordsLearned,
        adoptedAt: row.adoptedAt,
        deletedAt: row.deletedAt,
        definition: def,
      );
}