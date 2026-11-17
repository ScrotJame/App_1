import 'dart:convert';

import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:test_abc/database/app_db.dart';
import 'package:test_abc/models/backup_entity.dart';
import 'package:test_abc/repository/backup_data_repository.dart';
import 'package:test_abc/repository/inventory_repository.dart';

import 'backup_test_support.dart';

void main() {
  const freeze = 'Streak Freeze';

  Future<String> itemIdOf(AppDatabase db, String name) async {
    final item = await (db.select(db.itemsEntrie)
          ..where((t) => t.name.equals(name)))
        .getSingle();
    return item.id;
  }

  Future<void> own(
    AppDatabase db,
    String userKey,
    String name,
    int quantity,
  ) async {
    await db.into(db.userItemsEntrie).insert(
          UserItemsEntrieCompanion.insert(
            userId: userKey,
            itemId: await itemIdOf(db, name),
            quantity: Value(quantity),
          ),
        );
  }

  /// A backup from another device whose user owns [quantity] streak freezes.
  Future<String> backupOwning(int quantity) async {
    final source = await openDbWithUser('source');
    await own(source, 'source', freeze, quantity);
    final json = await BackupRepository(source).buildBackupJson();
    await source.close();
    return json;
  }

  Future<ImportSummary?> importInto(AppDatabase db, String json) async {
    final result = await BackupRepository(db).importFromJsonString(json);
    expect(result.success, isTrue, reason: result.error);
    return result.summary;
  }

  Future<Map<String?, int?>> ownedBy(AppDatabase db, String userKey) async {
    final items = await InventoryRepository(db).getUserItems(userKey);
    return {for (final i in items) i.item?.name: i.quantity};
  }

  test('a restore on a new device brings the owned items back', () async {
    final json = await backupOwning(3);
    // A new install: its catalogue items have other ids.
    final target = await openDbWithUser('target');
    addTearDown(target.close);
    final catalogueBefore = await target.select(target.itemsEntrie).get();

    final summary = await importInto(target, json);

    expect(summary?.userItemsMerged, 1);
    expect(await ownedBy(target, 'target'), {freeze: 3});
    // The catalogue of the file is recognised, not added a second time.
    expect(await target.select(target.itemsEntrie).get(),
        hasLength(catalogueBefore.length));
  });

  test('a restore never lowers a quantity', () async {
    final json = await backupOwning(3);
    final target = await openDbWithUser('target');
    addTearDown(target.close);
    await own(target, 'target', freeze, 5);

    final summary = await importInto(target, json);

    expect(summary?.userItemsMerged, 0);
    expect(await ownedBy(target, 'target'), {freeze: 5});
  });

  test('a higher quantity in the file raises the one on the device',
      () async {
    final json = await backupOwning(3);
    final target = await openDbWithUser('target');
    addTearDown(target.close);
    await own(target, 'target', freeze, 1);

    await importInto(target, json);

    expect(await ownedBy(target, 'target'), {freeze: 3});
  });

  test('importing the same file twice changes nothing the second time',
      () async {
    final json = await backupOwning(3);
    final target = await openDbWithUser('target');
    addTearDown(target.close);

    await importInto(target, json);
    final summary = await importInto(target, json);

    expect(summary?.userItemsMerged, 0);
    expect(await ownedBy(target, 'target'), {freeze: 3});
  });

  test('an item only the file knows is restored with its catalogue entry',
      () async {
    final target = await openDbWithUser('target');
    addTearDown(target.close);
    final json = jsonEncode({
      'version': 2,
      'items': [
        {'id': 'file-item', 'name': 'Old Potion', 'icon': 'IC_POTION', 'price': 5},
      ],
      'userItems': [
        {'itemId': 'file-item', 'quantity': 2},
      ],
    });

    await importInto(target, json);

    expect(await ownedBy(target, 'target'), {'Old Potion': 2});
  });

  test('an owned item that is in no catalogue is skipped', () async {
    final target = await openDbWithUser('target');
    addTearDown(target.close);
    final json = jsonEncode({
      'version': 2,
      'userItems': [
        {'itemId': 'ghost', 'quantity': 2},
      ],
    });

    final summary = await importInto(target, json);

    expect(summary?.userItemsMerged, 0);
    expect(await target.select(target.userItemsEntrie).get(), isEmpty);
  });
}
