import 'dart:convert';

import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:test_abc/database/app_db.dart';
import 'package:test_abc/repository/backup_data_repository.dart';
import 'package:test_abc/repository/companion_repository.dart';

import 'backup_test_support.dart';

void main() {
  const cat = 'Mèo Vàng';
  const dragon = 'Rồng Lửa';

  Future<CompanionDefinition> definitionNamed(AppDatabase db, String name) {
    return (db.select(db.companionDefinitions)
          ..where((t) => t.name.equals(name)))
        .getSingle();
  }

  /// Adopts [name] and puts it at [level].
  Future<void> adopt(
    AppDatabase db,
    String userKey,
    String name, {
    int level = 1,
    int totalFoodUsed = 0,
    int foodInventory = 0,
  }) async {
    final definition = await definitionNamed(db, name);
    await CompanionRepository(db)
        .adoptCompanion(userKey: userKey, definitionId: definition.id);
    await (db.update(db.activeCompanions)
          ..where((t) => t.userKey.equals(userKey)))
        .write(ActiveCompanionsCompanion(
      level: Value(level),
      totalFoodUsed: Value(totalFoodUsed),
      foodInventory: Value(foodInventory),
    ));
  }

  Future<String> backupWith(
    String name, {
    int level = 1,
    int totalFoodUsed = 0,
    int foodInventory = 0,
  }) async {
    final source = await openDbWithUser('source');
    await adopt(source, 'source', name,
        level: level,
        totalFoodUsed: totalFoodUsed,
        foodInventory: foodInventory);
    final json = await BackupRepository(source).buildBackupJson();
    await source.close();
    return json;
  }

  Future<void> importInto(AppDatabase db, String json) async {
    final result = await BackupRepository(db).importFromJsonString(json);
    expect(result.success, isTrue, reason: result.error);
  }

  Future<ActiveCompanion?> activeOf(AppDatabase db, String userKey) {
    return (db.select(db.activeCompanions)
          ..where((t) => t.userKey.equals(userKey)))
        .getSingleOrNull();
  }

  Future<String?> activeNameOf(AppDatabase db, String userKey) async {
    final companion =
        await CompanionRepository(db).watchActiveCompanion(userKey).first;
    return companion?.definition?.name;
  }

  test('a restore on a new device brings the companion back', () async {
    final json = await backupWith(dragon,
        level: 4, totalFoodUsed: 30, foodInventory: 3);
    final target = await openDbWithUser('target');
    addTearDown(target.close);

    await importInto(target, json);

    expect(await activeNameOf(target, 'target'), dragon);
    final active = await activeOf(target, 'target');
    expect(active?.level, 4);
    expect(active?.totalFoodUsed, 30);
    expect(active?.foodInventory, 3);
    expect(active?.isMaxLevel, isFalse);
    final definition = await definitionNamed(target, dragon);
    expect(active?.currentXpBonus,
        closeTo(definition.maxXpBonus * 4 / definition.maxLevel, 1e-9));
  });

  test('the companion is matched by its definition, not by the id in the file',
      () async {
    final decoded = jsonDecode(await backupWith(dragon, level: 4))
        as Map<String, dynamic>;
    // The same catalogue, numbered differently on the exporting device.
    for (final definition in decoded['companionDefinitions'] as List) {
      definition['id'] = 100 - (definition['id'] as int);
    }
    final active = decoded['activeCompanion'] as Map<String, dynamic>;
    active['definitionId'] = 100 - (active['definitionId'] as int);

    final target = await openDbWithUser('target');
    addTearDown(target.close);
    await importInto(target, jsonEncode(decoded));

    expect(await activeNameOf(target, 'target'), dragon);
  });

  test('the device keeps its companion when it is further along', () async {
    final json = await backupWith(dragon, level: 2);
    final target = await openDbWithUser('target');
    addTearDown(target.close);
    await adopt(target, 'target', cat, level: 6);

    await importInto(target, json);

    expect(await activeNameOf(target, 'target'), cat);
    expect((await activeOf(target, 'target'))?.level, 6);
    expect(await target.select(target.companionHistories).get(), isEmpty);
  });

  test('a companion that is further along replaces the one on the device',
      () async {
    final json = await backupWith(dragon, level: 4);
    final target = await openDbWithUser('target');
    addTearDown(target.close);
    await adopt(target, 'target', cat);

    await importInto(target, json);
    await importInto(target, json);

    expect(await activeNameOf(target, 'target'), dragon);
    expect((await activeOf(target, 'target'))?.level, 4);
    // The cat that left is kept as an earlier companion, once.
    final history =
        await target.select(target.companionHistories).getSingle();
    expect(history.userKey, 'target');
    expect(history.definitionId, (await definitionNamed(target, cat)).id);
  });

  test('the same companion keeps the progress that is further along',
      () async {
    final json = await backupWith(cat, level: 3, totalFoodUsed: 12);
    final target = await openDbWithUser('target');
    addTearDown(target.close);
    await adopt(target, 'target', cat, level: 3, totalFoodUsed: 20);

    await importInto(target, json);

    expect((await activeOf(target, 'target'))?.totalFoodUsed, 20);
    expect(await target.select(target.companionHistories).get(), isEmpty);
  });

  test('earlier companions are restored once', () async {
    final source = await openDbWithUser('source');
    await adopt(source, 'source', cat, level: 2);
    await CompanionRepository(source).switchCompanion(
      userKey: 'source',
      newDefinitionId: (await definitionNamed(source, dragon)).id,
    );
    final json = await BackupRepository(source).buildBackupJson();
    await source.close();

    final target = await openDbWithUser('target');
    addTearDown(target.close);
    await importInto(target, json);
    await importInto(target, json);

    final history =
        await target.select(target.companionHistories).getSingle();
    expect(history.userKey, 'target');
    expect(history.definitionId, (await definitionNamed(target, cat)).id);
    expect(history.levelReached, 2);
    expect(await activeNameOf(target, 'target'), dragon);
  });

  test('a companion this app does not know is skipped', () async {
    final target = await openDbWithUser('target');
    addTearDown(target.close);
    final json = jsonEncode({
      'version': 2,
      'companionDefinitions': [
        {'id': 1, 'type': 'pet', 'name': 'From a newer app'},
      ],
      'activeCompanion': {'definitionId': 1, 'level': 9},
    });

    await importInto(target, json);

    expect(await activeOf(target, 'target'), isNull);
  });

  test('a file without a companion leaves the one on the device', () async {
    final target = await openDbWithUser('target');
    addTearDown(target.close);
    await adopt(target, 'target', cat, level: 2);

    await importInto(target, jsonEncode({'version': 2, 'vocabularies': []}));

    expect(await activeNameOf(target, 'target'), cat);
  });
}
