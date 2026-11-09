import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:test_abc/database/app_db.dart';

/// Opens a fresh in-memory database that has one local user, and makes
/// [localKey] the active device key. The latest call decides the active key.
Future<AppDatabase> openDbWithUser(
  String localKey, {
  int gems = 0,
  int level = 1,
  int experience = 0,
  int currentStreak = 0,
  int longestStreak = 0,
  int totalLearned = 0,
  DateTime? lastActiveDate,
  DateTime? updatedAt,
}) async {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({'local_key': localKey});
  final db = AppDatabase.forTesting(NativeDatabase.memory());
  await db.into(db.usersEntrie).insert(
        UsersEntrieCompanion.insert(
          keyOpen: localKey,
          username: 'Local name',
          gems: Value(gems),
          level: Value(level),
          experience: Value(experience),
          currentStreak: Value(currentStreak),
          longestStreak: Value(longestStreak),
          totalLearned: Value(totalLearned),
          lastActiveDate: Value(lastActiveDate),
          createdAt: Value(DateTime(2026, 1, 1)),
          updatedAt: Value(updatedAt ?? DateTime(2026, 1, 1)),
        ),
      );
  return db;
}
