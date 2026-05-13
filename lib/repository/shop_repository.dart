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
      final row = await _getItemOrThrow(itemId);
      _validateStock(row);

      final user = await _getUserOrThrow(userId);
      _validateGems(user, row.price);

      await _deductGems(userId, user.gems, row.price);
      await _deductStock(itemId, row.stock);
      await _addToInventory(userId, itemId);
    });

    try { await syncWithServer(); } catch (_) {}
  }

// ── Helpers ──────────────────────────────────────────────────────────────────

  Future<ItemsEntrieData> _getItemOrThrow(String itemId) async {
    final row = await (_db.select(_db.itemsEntrie)
      ..where((t) => t.id.equals(itemId)))
        .getSingleOrNull();
    if (row == null) throw StateError('Không tìm thấy sản phẩm id=$itemId');
    return row;
  }

  void _validateStock(ItemsEntrieData row) {
    if (row.stock <= 0) {
      throw StateError('Sản phẩm "${row.name}" đã hết hàng');
    }
  }

  Future<UsersEntrieData> _getUserOrThrow(String userId) async {
    final user = await (_db.select(_db.usersEntrie)
      ..where((t) => t.keyOpen.equals(userId)))
        .getSingleOrNull();
    if (user == null) throw StateError('Không tìm thấy user id=$userId');
    return user;
  }

  void _validateGems(UsersEntrieData user, double price) {
    if (user.gems < price) {
      throw StateError('Không đủ gem (cần ${price.toInt()}, có ${user.gems})');
    }
  }

  Future<void> _deductGems(String userId, int currentGems, double price) async {
    final newGems = currentGems - price.toInt();
    await (_db.update(_db.usersEntrie)
      ..where((t) => t.keyOpen.equals(userId)))
        .write(UsersEntrieCompanion(
      gems: Value(newGems),
      updatedAt: Value(DateTime.now()),
    ));
    debugPrint('[ShopRepo] _deductGems: userId=$userId gems=$currentGems → $newGems');
  }

  Future<void> _deductStock(String itemId, int currentStock) async {
    await (_db.update(_db.itemsEntrie)
      ..where((t) => t.id.equals(itemId)))
        .write(ItemsEntrieCompanion(
      stock: Value(currentStock - 1),
      isSynced: const Value(false),
      lastUpdated: Value(DateTime.now()),
    ));
    debugPrint('[ShopRepo] _deductStock: itemId=$itemId stock=$currentStock → ${currentStock - 1}');
  }

  Future<void> _addToInventory(String userId, String itemId) async {
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
      debugPrint('[ShopRepo] _addToInventory: created userId=$userId itemId=$itemId qty=1');
    } else {
      final newQty = existing.quantity + 1;
      await (_db.update(_db.userItemsEntrie)
        ..where((t) => t.userId.equals(userId) & t.itemId.equals(itemId)))
          .write(UserItemsEntrieCompanion(quantity: Value(newQty)));
      debugPrint('[ShopRepo] _addToInventory: updated userId=$userId itemId=$itemId qty=$newQty');
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