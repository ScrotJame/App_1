/// ══════════════════════════════════════════════════════════════════════════════
/// NHÓM 4: UNAUTHORIZED ACCESS TESTS
/// ══════════════════════════════════════════════════════════════════════════════
///
/// Mục tiêu: Kiểm tra data isolation — user A KHÔNG thể truy cập data user B.
/// Kiểm tra các guard clause khi key không tồn tại hoặc null.
/// ══════════════════════════════════════════════════════════════════════════════
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:test_abc/database/app_db.dart';
import 'package:test_abc/repository/user_repository.dart';
import 'package:test_abc/repository/vocabulary_repository.dart';
import 'package:test_abc/repository/inventory_repository.dart';
import 'package:test_abc/repository/companion_repository.dart';
import 'package:test_abc/repository/achievement_repository.dart';

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

  group('🔑 [Nhóm 4] Unauthorized Access', () {
    // ─────────────────────────────────────────────────────────────────────────
    // TC-AUTH-001: Truy cập inventory user A bằng key user B
    // ─────────────────────────────────────────────────────────────────────────
    test('TC-AUTH-001: getUserItems(keyB) không trả items của userA', () async {
      final keyA = await seedUser(db, keyOpen: 'user-A', gems: 500);
      final keyB = await seedUser(db, keyOpen: 'user-B', gems: 500);

      // Tạo item và gán cho user A
      final itemId = await seedItem(db, name: 'Sword', price: 50);
      await db.into(db.userItemsEntrie).insert(
            UserItemsEntrieCompanion.insert(
              userId: keyA,
              itemId: itemId,
              quantity: const Value(3),
            ),
          );

      // User B cố truy cập
      final inventoryRepo = InventoryRepository(db);
      final userBItems = await inventoryRepo.getUserItems(keyB);

      expect(userBItems, isEmpty,
          reason: 'User B KHÔNG được thấy items của User A');
    });

    // ─────────────────────────────────────────────────────────────────────────
    // TC-AUTH-002: Truy cập word progress user A bằng key user B
    // ─────────────────────────────────────────────────────────────────────────
    test('TC-AUTH-002: word progress user A không lộ cho user B', () async {
      final keyA = await seedUser(db, keyOpen: 'auth-user-A');
      final keyB = await seedUser(db, keyOpen: 'auth-user-B');

      // Tạo word và ghi progress cho user A
      final wordId = await seedWord(db, word: 'apple', meaning: 'quả táo');
      final vocabRepo = VocabularyRepository(db);
      await vocabRepo.changeWordState(wordId, 5, keyA); // mastered

      // User B check
      final isMastered =
          await vocabRepo.isWordAlreadyMastered(wordId, keyB);
      expect(isMastered, isFalse,
          reason: 'User B không nên thấy progress của User A');
    });

    // ─────────────────────────────────────────────────────────────────────────
    // TC-AUTH-003: watchActiveCompanion với key user khác
    // ─────────────────────────────────────────────────────────────────────────
    test('TC-AUTH-003: watchActiveCompanion(keyB) → null khi chỉ userA có companion', () async {
      final keyA = await seedUser(db, keyOpen: 'comp-user-A');
      await seedUser(db, keyOpen: 'comp-user-B');

      final companionRepo = CompanionRepository(db);
      final defs = await companionRepo.getDefinitionsByType('pet');
      if (defs.isEmpty) return;

      // User A adopt companion
      await companionRepo.adoptCompanion(
        userKey: keyA,
        definitionId: defs.first.id!,
      );

      // User B watch → phải null
      final companionB = await companionRepo
          .watchActiveCompanion('comp-user-B')
          .first;

      expect(companionB, isNull,
          reason: 'User B không nên thấy companion của User A');
    });

    // ─────────────────────────────────────────────────────────────────────────
    // TC-AUTH-004: Truy cập với key không tồn tại
    // ─────────────────────────────────────────────────────────────────────────
    group('TC-AUTH-004: Truy cập với key không tồn tại', () {
      test('getUserItems(phantom-key) → empty list', () async {
        final inventoryRepo = InventoryRepository(db);
        final items = await inventoryRepo.getUserItems('phantom-key-999');
        expect(items, isEmpty);
      });

      test('watchActiveCompanion(phantom-key) → null', () async {
        final companionRepo = CompanionRepository(db);
        final result = await companionRepo
            .watchActiveCompanion('phantom-key-999')
            .first;
        expect(result, isNull);
      });

      test('isWordAlreadyMastered with phantom userId → false', () async {
        final wordId = await seedWord(db, word: 'test', meaning: 'test');
        final vocabRepo = VocabularyRepository(db);
        final result =
            await vocabRepo.isWordAlreadyMastered(wordId, 'phantom-999');
        expect(result, isFalse);
      });
    });

    // ─────────────────────────────────────────────────────────────────────────
    // TC-AUTH-005: Empty string key
    // ─────────────────────────────────────────────────────────────────────────
    group('TC-AUTH-005: Empty string key attacks', () {
      test('getUserItems("") → empty list, KHÔNG crash', () async {
        final inventoryRepo = InventoryRepository(db);
        final items = await inventoryRepo.getUserItems('');
        expect(items, isEmpty);
      });

      test('feedCompanion("") → phải handle gracefully', () async {
        final companionRepo = CompanionRepository(db);
        try {
          await companionRepo.feedCompanion(userKey: '');
          // OK — trả về void nếu không có companion
        } catch (e) {
          // OK — throw expected exception
          expect(e, isA<Exception>());
        }
      });

      test('earnFood("") → phải trả 0', () async {
        final companionRepo = CompanionRepository(db);
        final result =
            await companionRepo.earnFood(userKey: '', wordsLearned: 10);
        expect(result, equals(0));
      });
    });

    // ─────────────────────────────────────────────────────────────────────────
    // TC-AUTH-006: User A thử delete user B
    // ─────────────────────────────────────────────────────────────────────────
    test('TC-AUTH-006: Delete user A không ảnh hưởng user B', () async {
      await seedUser(db, keyOpen: 'del-A', gems: 100);
      await seedUser(db, keyOpen: 'del-B', gems: 200);

      // Delete user A
      await (db.delete(db.usersEntrie)
            ..where((t) => t.keyOpen.equals('del-A')))
          .go();

      // User B phải vẫn tồn tại với data nguyên vẹn
      final userB = await (db.select(db.usersEntrie)
            ..where((t) => t.keyOpen.equals('del-B')))
          .getSingleOrNull();

      expect(userB, isNotNull, reason: 'User B phải vẫn tồn tại');
      expect(userB!.gems, equals(200), reason: 'User B gems phải nguyên vẹn');
    });

    // ─────────────────────────────────────────────────────────────────────────
    // TC-AUTH-007: Achievement isolation giữa 2 user
    // ─────────────────────────────────────────────────────────────────────────
    test('TC-AUTH-007: Achievement user A không lộ cho user B', () async {
      final keyA = await seedUser(db, keyOpen: 'ach-user-A', totalLearned: 100);
      await seedUser(db, keyOpen: 'ach-user-B', totalLearned: 0);

      final achRepo = AchievementRepository(db);

      // User A unlock achievements
      await achRepo.checkAndUnlock(
        userKey: keyA,
        totalLearned: 100,
        currentStreak: 10,
        unitsCompleted: 5,
        learnedAt: DateTime.now(),
      );

      // User B phải chưa có unlock nào
      final achB = await achRepo.getAllAchievements(userKey: 'ach-user-B');
      final unlockedB = achB.where((a) => a.isUnlocked == true).toList();

      expect(unlockedB, isEmpty,
          reason: 'User B không nên có achievements đã unlock của User A');
    });
  });
}
