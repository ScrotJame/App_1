import 'package:drift/drift.dart';
import 'user.dart';

// ─────────────────────────────────────────────────────────────────────────────
// 1. CompanionDefinitions  –  blueprint cho từng loại companion
// ─────────────────────────────────────────────────────────────────────────────

class CompanionDefinitions extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// 'pet' | 'plant'
  TextColumn get type => text()();

  TextColumn get name => text().withLength(min: 1, max: 60)();
  TextColumn get description => text()();

  /// Emoji hoặc asset path để render UI
  TextColumn get iconKey => text()();

  // ── XP bonus stat ────────────────────────────────────────────
  /// Bonus XP % tối đa khi đạt maxLevel  (vd: 0.25 = +25%)
  RealColumn get maxXpBonus =>
      real().withDefault(const Constant(0.10))();

  // ── Progression config ───────────────────────────────────────
  IntColumn get maxLevel => integer().withDefault(const Constant(10))();

  /// Số food item cần để lên 1 cấp (base, scale theo level)
  /// foodNeeded(level) = (baseFoodPerLevel * level^scalingPow).ceil()
  IntColumn get baseFoodPerLevel =>
      integer().withDefault(const Constant(5))();
  RealColumn get scalingPow =>
      real().withDefault(const Constant(1.5))();

  // ── Food earn rate ───────────────────────────────────────────
  /// Số từ cần học để nhận được 1 food item
  /// Ví dụ: wordsPerFood = 10 → học 10 từ = +1 food
  IntColumn get wordsPerFood =>
      integer().withDefault(const Constant(10))();

  /// Số food tối đa có thể tích lũy (inventory cap)
  IntColumn get maxFoodInventory =>
      integer().withDefault(const Constant(10))();

  // ── Unlock condition ─────────────────────────────────────────
  IntColumn get unlockUserLevel =>
      integer().withDefault(const Constant(1))();
}

class ActiveCompanions extends Table {
  /// Primary key = userKey (enforce 1 companion / user at DB level)
  TextColumn get userKey =>
      text().references(UsersEntrie, #keyOpen)();

  IntColumn get definitionId =>
      integer().references(CompanionDefinitions, #id)();

  /// Cấp hiện tại (1 → maxLevel)
  IntColumn get level => integer().withDefault(const Constant(1))();

  // ── Food inventory ───────────────────────────────────────────
  /// Số food/water item đang tích lũy trong kho
  /// Tăng khi học từ, giảm khi user tap "Cho ăn / Tưới cây"
  IntColumn get foodInventory =>
      integer().withDefault(const Constant(0))();

  /// Phần dư từ học chưa đủ để đổi thành food
  /// pendingWords + wordsCount >= wordsPerFood → +1 food, reset pendingWords
  RealColumn get pendingWords =>
      real().withDefault(const Constant(0))();

  // ── Progression ──────────────────────────────────────────────
  /// Số food đã dùng trong cấp hiện tại (tiến trình lên cấp)
  /// Reset về 0 mỗi khi lên cấp
  IntColumn get foodUsedInCurrentLevel =>
      integer().withDefault(const Constant(0))();

  /// Tổng food đã dùng kể từ khi adopt companion này (cross-level)
  IntColumn get totalFoodUsed =>
      integer().withDefault(const Constant(0))();

  /// Tổng số từ đã học kể từ khi adopt (để thống kê)
  RealColumn get totalWordsLearned =>
      real().withDefault(const Constant(0))();

  // ── XP bonus cache ───────────────────────────────────────────
  /// Bonus XP % hiện tại — cached, tính lại mỗi lần lên cấp
  /// currentXpBonus = maxXpBonus * (level / maxLevel)
  RealColumn get currentXpBonus =>
      real().withDefault(const Constant(0.0))();

  /// true khi đạt maxLevel (companion "trưởng thành")
  BoolColumn get isMaxLevel =>
      boolean().withDefault(const Constant(false))();

  DateTimeColumn get adoptedAt =>
      dateTime().withDefault(currentDateAndTime)();

  DateTimeColumn get updatedAt =>
      dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {userKey};
}

// ─────────────────────────────────────────────────────────────────────────────
// 3. CompanionFoodLogs  –  log mỗi lần user dùng food cho companion
//    (thay thế CompanionWordLogs cũ — word earning được track qua pendingWords)
// ─────────────────────────────────────────────────────────────────────────────

class CompanionFoodLogs extends Table {
  IntColumn get id => integer().autoIncrement()();

  TextColumn get userKey =>
      text().references(UsersEntrie, #keyOpen)();

  /// Số food đã dùng trong lần này (thường = 1)
  IntColumn get foodUsed => integer()();

  /// Level companion tại thời điểm dùng food
  IntColumn get levelAtTime => integer()();

  /// Companion definition (để trace kể cả sau khi đổi)
  IntColumn get definitionId => integer()();

  /// Companion lên cấp sau lần feed này không?
  BoolColumn get causedLevelUp =>
      boolean().withDefault(const Constant(false))();

  DateTimeColumn get createdAt =>
      dateTime().withDefault(currentDateAndTime)();
}

// ─────────────────────────────────────────────────────────────────────────────
// 4. CompanionWordEarnLogs  –  log mỗi khi học từ → nhận food
//    Giúp debug và hiển thị lịch sử "bạn vừa nhận được N food"
// ─────────────────────────────────────────────────────────────────────────────

class CompanionWordEarnLogs extends Table {
  IntColumn get id => integer().autoIncrement()();

  TextColumn get userKey =>
      text().references(UsersEntrie, #keyOpen)();

  /// Số từ đã học trong session này
  RealColumn get wordsLearned => real()();

  /// Số food nhận được từ batch từ này
  RealColumn get foodEarned => real()();

  /// Companion definition tại thời điểm nhận
  IntColumn get definitionId => integer()();

  DateTimeColumn get createdAt =>
      dateTime().withDefault(currentDateAndTime)();
}


class CompanionHistories extends Table {
  IntColumn get id => integer().autoIncrement()();

  TextColumn get userKey =>
      text().references(UsersEntrie, #keyOpen)();

  IntColumn get definitionId => integer()();

  /// Level đạt được trước khi bị xóa
  IntColumn get levelReached => integer()();

  /// Tổng food đã dùng với companion này
  IntColumn get totalFoodUsed => integer()();

  /// Tổng từ đã học (để thống kê)
  RealColumn get totalWordsLearned => real()();

  DateTimeColumn get adoptedAt => dateTime()();

  /// Thời điểm bị xóa (user chọn companion khác)
  DateTimeColumn get deletedAt =>
      dateTime().withDefault(currentDateAndTime)();
}