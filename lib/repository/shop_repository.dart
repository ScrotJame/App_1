import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import '../database/app_db.dart';
import '../models/items_entity.dart';

abstract class IShopRepository {
  Stream<List<ItemsEntity>> watchProducts();
  Future<void> addProduct(ItemsEntity product);
  Future<void> buyProduct(ItemsEntity product, String userId);
  Future<void> syncWithServer();
}

class ShopRepository implements IShopRepository {
  final AppDatabase _db;

  ShopRepository(this._db);

  @override
  Future<void> addProduct(ItemsEntity product) {
    return _db.into(_db.itemsEntrie).insert(
      ItemsEntrieCompanion.insert(
        id: Value(product.id ?? ''),
        name: product.name ?? '',
        price: product.price ?? 0,
        icon: '',
      ),
    );
  }

  /// Mua sản phẩm: trừ stock + cộng quantity cho user, trong 1 transaction.
  /// Sau đó gọi syncWithServer để đánh dấu cần đồng bộ.
  @override
  Future<void> buyProduct(ItemsEntity product, String userId) async {
    final itemId = product.id;
    if (itemId == null || itemId.isEmpty) {
      throw ArgumentError('product.id không được null/rỗng');
    }

    await _db.transaction(() async {
      final row = await (_db.select(_db.itemsEntrie)
        ..where((t) => t.id.equals(itemId)))
          .getSingleOrNull();

      if (row == null) {
        throw StateError('Không tìm thấy sản phẩm id=$itemId');
      }
      if (row.stock <= 0) {
        throw StateError('Sản phẩm "${row.name}" đã hết hàng');
      }

      debugPrint('[ShopRepo] buyProduct: item=$itemId stock=${row.stock} → ${row.stock - 1}');

      // ── 2. Trừ stock ─────────────────────────────────────────
      await (_db.update(_db.itemsEntrie)
        ..where((t) => t.id.equals(itemId)))
          .write(ItemsEntrieCompanion(
        stock: Value(row.stock - 1),
        isSynced: const Value(false), // cần sync lại sau
        lastUpdated: Value(DateTime.now()),
      ));

      // ── 3. Cộng quantity vào UserItemsEntrie ─────────────────
      // insertOnConflictUpdate: nếu (userId, itemId) đã tồn tại thì cộng thêm
      final existing = await (_db.select(_db.userItemsEntrie)
        ..where((t) => t.userId.equals(userId) & t.itemId.equals(itemId)))
          .getSingleOrNull();

      if (existing == null) {
        await _db.into(_db.userItemsEntrie).insert(
          UserItemsEntrieCompanion.insert(
            userId: userId,
            itemId: itemId,
            quantity: const Value(1),
          ),
        );
        debugPrint('[ShopRepo] buyProduct: created UserItems userId=$userId itemId=$itemId qty=1');
      } else {
        await (_db.update(_db.userItemsEntrie)
          ..where((t) => t.userId.equals(userId) & t.itemId.equals(itemId)))
            .write(UserItemsEntrieCompanion(
          quantity: Value(existing.quantity + 1),
        ));
        debugPrint('[ShopRepo] buyProduct: updated UserItems userId=$userId itemId=$itemId qty=${existing.quantity + 1}');
      }
    });

    try {
      await syncWithServer();
    } catch (e) {
    }
  }

  @override
  Future<void> syncWithServer() async {
    // Lấy các item chưa được sync
    final unsyncedItems = await (_db.select(_db.itemsEntrie)
      ..where((t) => t.isSynced.equals(false)))
        .get();

    if (unsyncedItems.isEmpty) {
      debugPrint('[ShopRepo] syncWithServer: nothing to sync');
      return;
    }

    // await _apiClient.syncItems(unsyncedItems);

    await (_db.update(_db.itemsEntrie)
      ..where((t) => t.isSynced.equals(false)))
        .write(ItemsEntrieCompanion(
      isSynced: const Value(true),
      lastUpdated: Value(DateTime.now()),
    ));
  }

  @override
  Stream<List<ItemsEntity>> watchProducts() {
    return _db.select(_db.itemsEntrie).watch().map((rows) {
      return rows.map((row) => ItemsEntity(
        id: row.id,
        name: row.name,
        price: row.price,
        description: row.description,
        icon: row.icon,
        stock: row.stock,
      )).toList();
    });
  }
}