/// Shared test helpers for security tests.
///
/// Provides an in-memory [AppDatabase] so tests run fast and isolated,
/// plus common seed utilities.
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:test_abc/database/app_db.dart';

/// Create a fresh in-memory [AppDatabase] per test.
AppDatabase createTestDatabase() {
  return AppDatabase.forTesting(NativeDatabase.memory());
}

/// Seed a single user into the DB and return the generated keyOpen.
Future<String> seedUser(
  AppDatabase db, {
  String keyOpen = 'test-user-key-001',
  String username = 'TestUser',
  int gems = 1000,
  int currentStreak = 0,
  int longestStreak = 0,
  int totalLearned = 0,
  int level = 1,
  int experience = 0,
}) async {
  await db.into(db.usersEntrie).insert(
        UsersEntrieCompanion.insert(
          keyOpen: keyOpen,
          username: username,
          gems: Value(gems),
          currentStreak: Value(currentStreak),
          longestStreak: Value(longestStreak),
          totalLearned: Value(totalLearned),
          level: Value(level),
          experience: Value(experience),
          createdAt: Value(DateTime.now()),
          updatedAt: Value(DateTime.now()),
        ),
      );
  return keyOpen;
}

/// Seed a shop item and return the generated ID.
Future<String> seedItem(
  AppDatabase db, {
  required String name,
  double price = 100,
  int stock = 10,
  String icon = 'IC_TEST',
  String? id,
}) async {
  final companion = ItemsEntrieCompanion.insert(
    id: id != null ? Value(id) : const Value.absent(),
    name: name,
    icon: icon,
    price: price,
    stock: Value(stock),
  );
  await db.into(db.itemsEntrie).insert(companion);

  // Return the id — if provided use that, else query the last inserted row.
  if (id != null) return id;
  final rows = await (db.select(db.itemsEntrie)
        ..where((t) => t.name.equals(name)))
      .get();
  return rows.first.id;
}

/// Seed a vocabulary word and return its auto-incremented ID.
Future<int> seedWord(
  AppDatabase db, {
  required String word,
  required String meaning,
  String? pronunciation,
  String? language,
  int? unitId,
}) async {
  return db.into(db.vocabularyEntries).insert(
        VocabularyEntriesCompanion.insert(
          word: word,
          meaning: meaning,
          pronunciation:
              pronunciation != null ? Value(pronunciation) : const Value.absent(),
          language: Value(language),
          unitId: Value(unitId),
        ),
      );
}

/// Seed a unit and return its auto-incremented ID.
Future<int> seedUnit(AppDatabase db, {required String title}) async {
  return db.into(db.unitsEntries).insert(
        UnitsEntriesCompanion.insert(title: title),
      );
}

/// Read user gems from DB.
Future<int> getUserGems(AppDatabase db, String keyOpen) async {
  final user = await (db.select(db.usersEntrie)
        ..where((t) => t.keyOpen.equals(keyOpen)))
      .getSingle();
  return user.gems;
}

/// Read item stock from DB.
Future<int> getItemStock(AppDatabase db, String itemId) async {
  final item = await (db.select(db.itemsEntrie)
        ..where((t) => t.id.equals(itemId)))
      .getSingle();
  return item.stock;
}
