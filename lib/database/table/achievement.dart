import 'package:drift/drift.dart';
import 'package:test_abc/database/table/user.dart';
import 'package:uuid/uuid.dart';

class AchievementDefinitions extends Table {
  TextColumn get id => text().clientDefault(() => const Uuid().v4())();

  /// Unique key để code reference, không bao giờ thay đổi
  /// Ví dụ: 'first_word', 'streak_7', 'total_100'
  TextColumn get code => text().unique()();

  /// 'milestone' | 'streak' | 'collection' | 'special'
  TextColumn get category => text()();

  /// l10n key cho tên và mô tả
  TextColumn get titleKey => text()();
  TextColumn get descriptionKey => text()();

  /// Icon asset key
  TextColumn get iconKey => text()();

  /// Giá trị mục tiêu cần đạt (totalLearned >= target, streak >= target...)
  IntColumn get targetValue => integer()();

  /// Thứ tự hiển thị trong UI
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();

  /// false = ẩn cho đến khi unlock (thành tựu bí ẩn)
  BoolColumn get isVisible =>
      boolean().withDefault(const Constant(true))();
}

// ─────────────────────────────────────────────────────────────
// 2. UserAchievementProgress — Tiến trình của từng user
// ─────────────────────────────────────────────────────────────
class UserAchievementProgress extends Table {
  TextColumn get userKey =>
      text().references(UsersEntrie, #keyOpen)();
  TextColumn get achievementId =>
      text().references(AchievementDefinitions, #id,
          onDelete: KeyAction.cascade)();

  IntColumn get currentValue =>
      integer().withDefault(const Constant(0))();

  BoolColumn get isUnlocked =>
      boolean().withDefault(const Constant(false))();

  /// null = chưa unlock
  DateTimeColumn get unlockedAt => dateTime().nullable()();

  DateTimeColumn get updatedAt =>
      dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {userKey, achievementId};
}