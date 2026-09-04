/// ══════════════════════════════════════════════════════════════════════════════
/// NHÓM 3: RACE CONDITION & CONCURRENCY TESTS
/// ══════════════════════════════════════════════════════════════════════════════
///
/// Mục tiêu: Kiểm tra khả năng chống chịu khi nhiều thao tác đồng thời
/// cùng truy cập vào tài nguyên chia sẻ (gems, stock, food inventory).
///
/// Kịch bản chính:
///   - Double-spend gems: gọi buyProduct() đồng thời
///   - Concurrent feedCompanion(): cho ăn đồng thời khi food ít
///   - Concurrent countWordLearn(): đếm từ đồng thời
///   - Concurrent createLocalUser(): tạo user đồng thời
/// ══════════════════════════════════════════════════════════════════════════════
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:test_abc/database/app_db.dart';
import 'package:test_abc/models/items_entity.dart';
import 'package:test_abc/repository/shop_repository.dart';
import 'package:test_abc/repository/companion_repository.dart';
import 'package:test_abc/repository/vocabulary_repository.dart';

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

  group('⚡ [Nhóm 3] Race Condition & Concurrency', () {
    // ─────────────────────────────────────────────────────────────────────────
    // TC-RACE-001: Double-spend gems
    // User có đúng 100 gems, sản phẩm giá 100 gems.
    // Gọi buyProduct() 10 lần đồng thời → phải chỉ mua được 1.
    // ─────────────────────────────────────────────────────────────────────────
    test(
      'TC-RACE-001: Double-spend gems — 10 concurrent buys với 100 gems',
      () async {
        final userKey = await seedUser(db, keyOpen: 'race-user-1', gems: 100);
        final itemId = await seedItem(db, name: 'Race Item', price: 100, stock: 10);

        final shopRepo = ShopRepository(db);
        final product = ItemsEntity(id: itemId, name: 'Race Item', price: 100);

        // Gửi 10 request đồng thời
        final futures = List.generate(
          10,
          (_) => shopRepo.buyProduct(product, userKey).then((_) => true).catchError((_) => false),
        );

        final results = await Future.wait(futures);
        final successCount = results.where((r) => r).length;

        // Chỉ 1 request được thành công (gems = 100, giá = 100)
        final finalGems = await getUserGems(db, userKey);
        final finalStock = await getItemStock(db, itemId);

        expect(
          successCount,
          equals(1),
          reason:
              'Chỉ 1 trong 10 request phải thành công. '
              'Actual: $successCount successes, gems=$finalGems, stock=$finalStock',
        );
        expect(finalGems, equals(0), reason: 'Gems phải còn 0');
        expect(finalStock, equals(9), reason: 'Stock phải giảm đúng 1');
      },
    );

    // ─────────────────────────────────────────────────────────────────────────
    // TC-RACE-002: Concurrent feedCompanion với 1 food
    // ─────────────────────────────────────────────────────────────────────────
    test(
      'TC-RACE-002: Concurrent feedCompanion — 5 feeds với 1 food',
      () async {
        final userKey = await seedUser(db, keyOpen: 'race-user-2');
        final companionRepo = CompanionRepository(db);

        // Adopt companion (lấy definition đầu tiên từ seed)
        final defs = await companionRepo.getDefinitionsByType('pet');
        if (defs.isEmpty) {
          // Skip nếu không có seed data
          return;
        }

        await companionRepo.adoptCompanion(
          userKey: userKey,
          definitionId: defs.first.id!,
        );

        // Thêm 1 food bằng cách update trực tiếp
        await (db.update(db.activeCompanions)
              ..where((t) => t.userKey.equals(userKey)))
            .write(const ActiveCompanionsCompanion(
          foodInventory: Value(1),
        ));

        // Gửi 5 feedCompanion đồng thời
        final futures = List.generate(
          5,
          (_) => companionRepo
              .feedCompanion(userKey: userKey)
              .then((_) => true)
              .catchError((_) => false),
        );

        final results = await Future.wait(futures);
        final successCount = results.where((r) => r).length;

        // Chỉ 1 feed phải thành công
        final companion = await (db.select(db.activeCompanions)
              ..where((t) => t.userKey.equals(userKey)))
            .getSingleOrNull();

        expect(
          successCount,
          equals(1),
          reason:
              'Chỉ 1 feed phải thành công khi chỉ có 1 food. '
              'Actual: $successCount, remaining food=${companion?.foodInventory}',
        );
        expect(companion?.foodInventory, equals(0),
            reason: 'Food phải còn 0 sau 1 feed');
      },
    );

    // ─────────────────────────────────────────────────────────────────────────
    // TC-RACE-003: Concurrent mua sản phẩm hết stock
    // Item stock = 1, 5 user mua đồng thời → chỉ 1 thành công
    // ─────────────────────────────────────────────────────────────────────────
    test(
      'TC-RACE-003: Concurrent buy khi stock = 1 → chỉ 1 thành công',
      () async {
        final itemId =
            await seedItem(db, name: 'Last Item', price: 10, stock: 1);

        // Tạo 5 user, mỗi user 1000 gems
        final userKeys = <String>[];
        for (int i = 0; i < 5; i++) {
          final key = await seedUser(
            db,
            keyOpen: 'race-stock-user-$i',
            gems: 1000,
          );
          userKeys.add(key);
        }

        final shopRepo = ShopRepository(db);
        final product = ItemsEntity(id: itemId, name: 'Last Item', price: 10);

        final futures = userKeys.map(
          (key) => shopRepo
              .buyProduct(product, key)
              .then((_) => true)
              .catchError((_) => false),
        );

        final results = await Future.wait(futures);
        final successCount = results.where((r) => r).length;
        final finalStock = await getItemStock(db, itemId);

        expect(successCount, equals(1),
            reason: 'Chỉ 1 user mua được khi stock = 1');
        expect(finalStock, equals(0), reason: 'Stock phải = 0');
      },
    );

    // ─────────────────────────────────────────────────────────────────────────
    // TC-RACE-004: Concurrent countWordLearn
    // Gọi 20 lần đồng thời → totalLearned phải tăng đúng 20
    // ─────────────────────────────────────────────────────────────────────────
    test(
      'TC-RACE-004: Concurrent countWordLearn x20 → totalLearned phải tăng đúng 20',
      () async {
        final userKey =
            await seedUser(db, keyOpen: 'race-count-user', totalLearned: 0);
        final vocabRepo = VocabularyRepository(db);

        final futures = List.generate(
          20,
          (_) => vocabRepo.countWordLearn(userKey),
        );

        await Future.wait(futures);

        final user = await (db.select(db.usersEntrie)
              ..where((t) => t.keyOpen.equals(userKey)))
            .getSingle();

        expect(
          user.totalLearned,
          equals(20),
          reason:
              'totalLearned phải tăng đúng 20 sau 20 concurrent calls. '
              'Actual: ${user.totalLearned}',
        );
      },
    );

    // ─────────────────────────────────────────────────────────────────────────
    // TC-RACE-005: Concurrent earnFood
    // ─────────────────────────────────────────────────────────────────────────
    test(
      'TC-RACE-005: Concurrent earnFood x10 → totalWordsLearned phải nhất quán',
      () async {
        final userKey = await seedUser(db, keyOpen: 'race-earn-user');
        final companionRepo = CompanionRepository(db);

        final defs = await companionRepo.getDefinitionsByType('pet');
        if (defs.isEmpty) return;

        await companionRepo.adoptCompanion(
          userKey: userKey,
          definitionId: defs.first.id!,
        );

        // 10 concurrent earnFood, mỗi lần 1 word
        final futures = List.generate(
          10,
          (_) => companionRepo.earnFood(userKey: userKey, wordsLearned: 1),
        );

        await Future.wait(futures);

        final companion = await (db.select(db.activeCompanions)
              ..where((t) => t.userKey.equals(userKey)))
            .getSingle();

        expect(
          companion.totalWordsLearned,
          equals(10),
          reason:
              'totalWordsLearned phải = 10 sau 10 concurrent calls. '
              'Actual: ${companion.totalWordsLearned}',
        );
      },
    );
  });
}
