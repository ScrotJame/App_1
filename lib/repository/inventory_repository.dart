import 'package:drift/drift.dart' hide Column;
import 'package:flutter/foundation.dart';

import '../database/app_db.dart';
import '../models/entity/item_entity.dart';

abstract class IInventoryRepository {
  Future<List<UserItemEntity>> getUserItems(String userKey);
  Future<void> syncWithServer();
}

class InventoryRepository implements IInventoryRepository {
  final AppDatabase _db;

  InventoryRepository(this._db);

  // ─── Parse ────────────────────────────────────────────────────────

  UserItemEntity _parseRow(TypedResult row) {
    final item     = row.readTable(_db.itemsEntrie);
    final userItem = row.readTable(_db.userItemsEntrie);

    return UserItemEntity(
      userId:   userItem.userId,
      itemId:   userItem.itemId,
      quantity: userItem.quantity,
      item: ItemEntity(
        id:          item.id,
        name:        item.name,
        icon:        item.icon,
        price:       item.price,
        stock:       item.stock,
        description: item.description,
        isSynced:    item.isSynced,
        lastUpdated: item.lastUpdated,
      ),
    );
  }

  // ─── Queries ──────────────────────────────────────────────────────

  @override
  Future<List<UserItemEntity>> getUserItems(String userKey) async {
    final query = _db.select(_db.userItemsEntrie).join([
      innerJoin(
        _db.itemsEntrie,
        _db.itemsEntrie.id.equalsExp(_db.userItemsEntrie.itemId),
      ),
    ])..where(_db.userItemsEntrie.userId.equals(userKey));

    final rows = await query.get();
    return rows.map(_parseRow).toList();
  }

  // ─── Sync ─────────────────────────────────────────────────────────

  @override
  Future<void> syncWithServer() async {
    final unsyncedItems = await (_db.select(_db.itemsEntrie)
      ..where((t) => t.isSynced.equals(false)))
        .get();

    if (unsyncedItems.isEmpty) {
      debugPrint('[InventoryRepo] syncWithServer: nothing to sync');
      return;
    }

    // await _apiClient.syncItems(unsyncedItems);

    await (_db.update(_db.itemsEntrie)
      ..where((t) => t.isSynced.equals(false)))
        .write(ItemsEntrieCompanion(
      isSynced:    const Value(true),
      lastUpdated: Value(DateTime.now()),
    ));
  }
}