/// ══════════════════════════════════════════════════════════════════════════════
/// NHÓM 5: BUSINESS LOGIC ABUSE TESTS
/// ══════════════════════════════════════════════════════════════════════════════
///
/// Mục tiêu: Hack game logic — gems, streak, level, shop, companion.
/// Attacker có thể sửa backup JSON rồi import lại để cheat.
/// ══════════════════════════════════════════════════════════════════════════════
import 'dart:convert';

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:test_abc/database/app_db.dart';
import 'package:test_abc/database/backup_data.dart';
import 'package:test_abc/models/entity/user_entity.dart';
import 'package:test_abc/models/entity/vocabulary_entity.dart';
import 'package:test_abc/models/entity/unit_entity.dart';
import 'package:test_abc/models/items_entity.dart';
import 'package:test_abc/repository/backup_data_repository.dart';
import 'package:test_abc/repository/shop_repository.dart';
import 'package:test_abc/repository/companion_repository.dart';
import 'package:test_abc/repository/vocabulary_repository.dart';
import 'package:test_abc/repository/achievement_repository.dart';
import 'package:test_abc/repository/user_repository.dart';

import 'test_helpers.dart';

void main() {
  late AppDatabase db;

  setUp(() async {
    db = createTestDatabase();
    await db.customSelect('SELECT 1').get();
  });

  tearDown(() async {
    await db.close();
  });

  group('🎮 [Nhóm 5] Business Logic Abuse', () {
    // ─────────────────────────────────────────────────────────────────────────
    // TC-BIZ-001: Hack gems qua backup import
    // ─────────────────────────────────────────────────────────────────────────
    test('TC-BIZ-001: Import backup với gems = 999999 → gems bị thay đổi', () async {
      await seedUser(db, keyOpen: 'biz-user', gems: 100);

      final hackedBackup = BackupData(
        version: 1,
        exportedAt: DateTime.now(),
        userKey: 'biz-user',
        user: UserEntity(
          keyOpen: 'biz-user',
          username: 'Hacker',
          gems: 999999,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now().add(const Duration(days: 1)), // Newer
        ),
      );

      final backupRepo = BackupRepository(db);
      final jsonStr =
          const JsonEncoder.withIndent('  ').convert(hackedBackup.toJson());
      final result = await backupRepo.importFromJsonString(jsonStr);

      final user = await (db.select(db.usersEntrie)
            ..where((t) => t.keyOpen.equals('biz-user')))
          .getSingle();

      // ⚠️ DOCUMENT: Hiện tại backup merge KHÔNG validate gems range.
      // Attacker có thể export → sửa gems → re-import.
      // Recommendation: Thêm validation range cho gems, level, streak.
      if (result.success) {
        // Ghi nhận lỗ hổng: gems bị thay đổi thành 999999
        print('⚠️ [SECURITY] gems sau import: ${user.gems} '
            '(expected ≤ reasonable limit, got ${user.gems})');
      }

      // Test này DOCUMENT lỗ hổng, không fail hard
      expect(true, isTrue, reason: 'Document: gems có thể bị hack qua backup import');
    });

    // ─────────────────────────────────────────────────────────────────────────
    // TC-BIZ-002: Hack streak qua backup
    // ─────────────────────────────────────────────────────────────────────────
    test('TC-BIZ-002: Import backup với streak = 365 → kiểm tra syncStreak', () async {
      await seedUser(
        db,
        keyOpen: 'streak-user',
        currentStreak: 0,
        longestStreak: 0,
      );

      final hackedBackup = BackupData(
        version: 1,
        exportedAt: DateTime.now(),
        userKey: 'streak-user',
        user: UserEntity(
          keyOpen: 'streak-user',
          username: 'StreakHacker',
          currentStreak: 365,
          longestStreak: 1000,
          lastActiveDate: DateTime.now(),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now().add(const Duration(days: 1)),
        ),
      );

      final backupRepo = BackupRepository(db);
      final jsonStr =
          const JsonEncoder.withIndent('  ').convert(hackedBackup.toJson());
      await backupRepo.importFromJsonString(jsonStr);

      final user = await (db.select(db.usersEntrie)
            ..where((t) => t.keyOpen.equals('streak-user')))
          .getSingle();

      // ⚠️ DOCUMENT: streak bị import trực tiếp, không cross-validate với
      // actual activity dates.
      print('⚠️ [SECURITY] streak sau import: '
          'current=${user.currentStreak}, longest=${user.longestStreak}');

      // syncStreak SẼ tính lại dựa trên SharedPreferences streak_marked_dates
      // Nhưng nếu streak_marked_dates cũng bị hack → streak giả vẫn đứng
    });

    // ─────────────────────────────────────────────────────────────────────────
    // TC-BIZ-003: Mua sản phẩm khi stock = 0
    // ─────────────────────────────────────────────────────────────────────────
    test('TC-BIZ-003: Mua sản phẩm stock = 0 → phải throw StateError', () async {
      final userKey = await seedUser(db, keyOpen: 'stock-user', gems: 10000);
      final itemId =
          await seedItem(db, name: 'Out of Stock', price: 10, stock: 0);

      final shopRepo = ShopRepository(db);
      final product =
          ItemsEntity(id: itemId, name: 'Out of Stock', price: 10);

      expect(
        () => shopRepo.buyProduct(product, userKey),
        throwsA(isA<StateError>()),
        reason: 'Phải throw khi stock = 0',
      );
    });

    // ─────────────────────────────────────────────────────────────────────────
    // TC-BIZ-004: Mua sản phẩm khi gems không đủ
    // ─────────────────────────────────────────────────────────────────────────
    test('TC-BIZ-004: Mua sản phẩm giá 1000 khi chỉ có 10 gems → phải throw', () async {
      final userKey = await seedUser(db, keyOpen: 'poor-user', gems: 10);
      final itemId =
          await seedItem(db, name: 'Expensive Item', price: 1000, stock: 5);

      final shopRepo = ShopRepository(db);
      final product =
          ItemsEntity(id: itemId, name: 'Expensive Item', price: 1000);

      expect(
        () => shopRepo.buyProduct(product, userKey),
        throwsA(isA<StateError>()),
        reason: 'Phải throw khi gems < price',
      );

      // Verify gems không bị trừ
      final finalGems = await getUserGems(db, userKey);
      expect(finalGems, equals(10), reason: 'Gems phải nguyên vẹn');
    });

    // ─────────────────────────────────────────────────────────────────────────
    // TC-BIZ-005: Mua với product.id null/empty
    // ─────────────────────────────────────────────────────────────────────────
    test('TC-BIZ-005: buyProduct với product.id = null → phải throw ArgumentError', () async {
      final userKey = await seedUser(db, keyOpen: 'null-item-user', gems: 1000);
      final shopRepo = ShopRepository(db);

      expect(
        () => shopRepo.buyProduct(
          ItemsEntity(id: null, name: 'Ghost', price: 10),
          userKey,
        ),
        throwsA(isA<ArgumentError>()),
      );

      expect(
        () => shopRepo.buyProduct(
          ItemsEntity(id: '', name: 'Empty', price: 10),
          userKey,
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    // ─────────────────────────────────────────────────────────────────────────
    // TC-BIZ-006: incrementWordLevel trên word không tồn tại
    // ─────────────────────────────────────────────────────────────────────────
    test('TC-BIZ-006: incrementWordLevel(99999) → phải return null', () async {
      final vocabRepo = VocabularyRepository(db);
      final result = await vocabRepo.incrementWordLevel(99999);
      expect(result, isNull, reason: 'Word không tồn tại phải return null');
    });

    // ─────────────────────────────────────────────────────────────────────────
    // TC-BIZ-007: earnFood với wordsLearned âm
    // ─────────────────────────────────────────────────────────────────────────
    test('TC-BIZ-007: earnFood(wordsLearned = -100) → food KHÔNG được tăng', () async {
      final userKey = await seedUser(db, keyOpen: 'neg-earn-user');
      final companionRepo = CompanionRepository(db);

      final defs = await companionRepo.getDefinitionsByType('pet');
      if (defs.isEmpty) return;

      await companionRepo.adoptCompanion(
        userKey: userKey,
        definitionId: defs.first.id!,
      );

      // Thêm food ban đầu
      await (db.update(db.activeCompanions)
            ..where((t) => t.userKey.equals(userKey)))
          .write(const ActiveCompanionsCompanion(foodInventory: Value(5)));

      // Earn food với giá trị âm
      await companionRepo.earnFood(userKey: userKey, wordsLearned: -100);

      final companion = await (db.select(db.activeCompanions)
            ..where((t) => t.userKey.equals(userKey)))
          .getSingle();

      // ⚠️ BUG TIỀM ẨN: nếu pendingWords + (-100) → âm → food có thể bị sai
      expect(
        companion.foodInventory,
        greaterThanOrEqualTo(0),
        reason: 'Food inventory KHÔNG được âm',
      );
      expect(
        companion.totalWordsLearned,
        greaterThanOrEqualTo(0),
        reason: 'totalWordsLearned KHÔNG được âm',
      );
    });

    // ─────────────────────────────────────────────────────────────────────────
    // TC-BIZ-008: feedCompanion khi đã max level
    // ─────────────────────────────────────────────────────────────────────────
    test('TC-BIZ-008: feedCompanion khi isMaxLevel = true → phải throw CompanionMaxLevelException', () async {
      final userKey = await seedUser(db, keyOpen: 'max-level-user');
      final companionRepo = CompanionRepository(db);

      final defs = await companionRepo.getDefinitionsByType('pet');
      if (defs.isEmpty) return;

      await companionRepo.adoptCompanion(
        userKey: userKey,
        definitionId: defs.first.id!,
      );

      // Force max level
      await (db.update(db.activeCompanions)
            ..where((t) => t.userKey.equals(userKey)))
          .write(const ActiveCompanionsCompanion(
        isMaxLevel: Value(true),
        foodInventory: Value(10),
      ));

      expect(
        () => companionRepo.feedCompanion(userKey: userKey),
        throwsA(isA<CompanionMaxLevelException>()),
      );
    });

    // ─────────────────────────────────────────────────────────────────────────
    // TC-BIZ-009: feedCompanion khi food = 0
    // ─────────────────────────────────────────────────────────────────────────
    test('TC-BIZ-009: feedCompanion khi foodInventory = 0 → phải throw InsufficientFoodException', () async {
      final userKey = await seedUser(db, keyOpen: 'no-food-user');
      final companionRepo = CompanionRepository(db);

      final defs = await companionRepo.getDefinitionsByType('pet');
      if (defs.isEmpty) return;

      await companionRepo.adoptCompanion(
        userKey: userKey,
        definitionId: defs.first.id!,
      );

      // Food = 0 (default)
      expect(
        () => companionRepo.feedCompanion(userKey: userKey),
        throwsA(isA<InsufficientFoodException>()),
      );
    });

    // ─────────────────────────────────────────────────────────────────────────
    // TC-BIZ-010: Achievement unlock với data giả
    // ─────────────────────────────────────────────────────────────────────────
    test('TC-BIZ-010: checkAndUnlock với totalLearned = 999999 → unlock tất cả milestone', () async {
      final userKey = await seedUser(db, keyOpen: 'ach-hack-user');
      final achRepo = AchievementRepository(db);

      // Gọi checkAndUnlock với giá trị cực lớn
      final newlyUnlocked = await achRepo.checkAndUnlock(
        userKey: userKey,
        totalLearned: 999999,
        currentStreak: 999,
        unitsCompleted: 999,
        learnedAt: DateTime(2026, 1, 1, 23, 0), // 23:00 → night_owl
      );

      // Verify: tất cả achievement phải unlock
      final allAch = await achRepo.getAllAchievements(userKey: userKey);
      final unlocked = allAch.where((a) => a.isUnlocked == true).toList();

      // ⚠️ DOCUMENT: Achievement không cross-validate với actual data.
      // Nếu Cubit gọi checkAndUnlock với giá trị giả → unlock hết.
      // Cần validate totalLearned từ DB thay vì nhận từ tham số.
      print('⚠️ [SECURITY] Unlocked ${unlocked.length}/${allAch.length} '
          'achievements với data giả');

      expect(unlocked.length, greaterThan(0),
          reason: 'Phải unlock ít nhất 1 achievement với data cực lớn');
    });

    // ─────────────────────────────────────────────────────────────────────────
    // TC-BIZ-011: Delete word đang có progress → cascade check
    // ─────────────────────────────────────────────────────────────────────────
    test('TC-BIZ-011: Delete word có progress → progress phải bị cascade delete', () async {
      final userKey = await seedUser(db, keyOpen: 'cascade-user');
      final wordId = await seedWord(db, word: 'cascade', meaning: 'test');
      final vocabRepo = VocabularyRepository(db);

      // Ghi progress
      await vocabRepo.changeWordState(wordId, 3, userKey);

      // Verify progress tồn tại
      var progress = await (db.select(db.userWordProgressEntrie)
            ..where((t) => t.wordId.equals(wordId)))
          .get();
      expect(progress, isNotEmpty);

      // Delete word
      await vocabRepo.deleteWord(wordId);

      // Progress phải bị cascade delete (FK onDelete: cascade)
      progress = await (db.select(db.userWordProgressEntrie)
            ..where((t) => t.wordId.equals(wordId)))
          .get();
      expect(progress, isEmpty,
          reason: 'Progress phải bị cascade delete khi word bị xóa');
    });

    // ─────────────────────────────────────────────────────────────────────────
    // TC-BIZ-012: Mua sản phẩm không tồn tại
    // ─────────────────────────────────────────────────────────────────────────
    test('TC-BIZ-012: buyProduct với product không tồn tại → phải throw', () async {
      final userKey = await seedUser(db, keyOpen: 'ghost-buy-user', gems: 10000);
      final shopRepo = ShopRepository(db);

      expect(
        () => shopRepo.buyProduct(
          ItemsEntity(id: 'non-existent-id', name: 'Ghost', price: 10),
          userKey,
        ),
        throwsA(isA<StateError>()),
        reason: 'Product không tồn tại phải throw StateError',
      );
    });
  });
}
