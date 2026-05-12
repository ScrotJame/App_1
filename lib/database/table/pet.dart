// companion_table.dart
// Drift table definitions — companion system (pet / plant).
//
// Cơ chế chính:
//   • Mỗi từ học được  →  +food/water  →  companion lên cấp
//   • Cấp càng cao càng cần nhiều từ (exponential scaling)
//   • Đổi companion    →  XÓA HOÀN TOÀN, lưu vào history, bắt đầu lại
//   • Mỗi user chỉ có 1 active companion tại 1 thời điểm
//
// Thêm vào @DriftDatabase:
//   tables: [
//     ...existing,
//     CompanionDefinitions,
//     ActiveCompanions,
//     CompanionWordLogs,
//     CompanionHistories,
//   ]

import 'package:drift/drift.dart';
import 'user.dart'; // references UsersEntrie

// ─────────────────────────────────────────────────────────────────────────────
// 1. CompanionDefinitions  –  static templates (seed once)
// ─────────────────────────────────────────────────────────────────────────────

class CompanionDefinitions extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// 'pet' | 'plant'
  TextColumn get type => text()();

  TextColumn get name => text().withLength(min: 1, max: 60)();
  TextColumn get description => text()();

  /// Emoji hoặc asset path để render UI
  TextColumn get iconKey => text()();

  // ── XP bonus stat (duy nhất) ────────────────────────────────
  /// Bonus XP % tối đa khi đạt maxLevel  (vd: 0.25 = +25%)
  RealColumn get maxXpBonus =>
      real().withDefault(const Constant(0.10))();

  // ── Progression config ──────────────────────────────────────
  /// Số cấp tối đa
  IntColumn get maxLevel => integer().withDefault(const Constant(10))();

  /// Số từ cần để lên cấp 1→2 (base)
  /// wordsNeeded(level) = (baseWords * level^scalingPow).ceil()
  /// Ví dụ base=10, scaling=1.5:
  ///   Cấp 1: 10 từ | Cấp 2: 14 từ | Cấp 5: 35 từ | Cấp 10: 100 từ
  IntColumn get baseWords => integer().withDefault(const Constant(10))();
  RealColumn get scalingPow =>
      real().withDefault(const Constant(1.5))();

  // ── Unlock condition ────────────────────────────────────────
  IntColumn get unlockUserLevel =>
      integer().withDefault(const Constant(1))();
}

// ─────────────────────────────────────────────────────────────────────────────
// 2. ActiveCompanions  –  companion đang nuôi (1 row / user)
//    Khi đổi companion: DELETE row này → lưu CompanionHistory → INSERT mới
// ─────────────────────────────────────────────────────────────────────────────

class ActiveCompanions extends Table {
  /// Primary key = userKey (enforce 1 companion / user at DB level)
  TextColumn get userKey =>
      text().references(UsersEntrie, #keyOpen)();

  IntColumn get definitionId =>
      integer().references(CompanionDefinitions, #id)();

  /// Cấp hiện tại (1 → maxLevel)
  IntColumn get level => integer().withDefault(const Constant(1))();

  /// Tổng số từ đã học kể từ khi adopt companion này
  IntColumn get totalWordsLearned =>
      integer().withDefault(const Constant(0))();

  /// Số từ đã tích lũy trong cấp hiện tại
  /// Reset về 0 mỗi khi lên cấp
  IntColumn get wordsInCurrentLevel =>
      integer().withDefault(const Constant(0))();

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
// 3. CompanionWordLogs  –  log mỗi batch từ học được
// ─────────────────────────────────────────────────────────────────────────────

class CompanionWordLogs extends Table {
  IntColumn get id => integer().autoIncrement()();

  TextColumn get userKey =>
      text().references(UsersEntrie, #keyOpen)();

  /// Số từ học được trong lần này
  IntColumn get wordsCount => integer()();

  /// Level companion tại thời điểm nhận
  IntColumn get levelAtTime => integer()();

  /// Companion definition (để trace kể cả sau khi đổi)
  IntColumn get definitionId => integer()();

  /// Companion lên cấp trong lần này không?
  BoolColumn get causedLevelUp =>
      boolean().withDefault(const Constant(false))();

  DateTimeColumn get createdAt =>
      dateTime().withDefault(currentDateAndTime)();
}

// ─────────────────────────────────────────────────────────────────────────────
// 4. CompanionHistories  –  lưu companion đã bị xóa (để hiển thị "đã qua")
// ─────────────────────────────────────────────────────────────────────────────

class CompanionHistories extends Table {
  IntColumn get id => integer().autoIncrement()();

  TextColumn get userKey =>
      text().references(UsersEntrie, #keyOpen)();

  IntColumn get definitionId => integer()();

  /// Level đạt được trước khi bị xóa
  IntColumn get levelReached => integer()();

  /// Tổng từ đã học với companion này
  IntColumn get totalWordsLearned => integer()();

  DateTimeColumn get adoptedAt => dateTime()();

  /// Thời điểm bị xóa (user chọn companion khác)
  DateTimeColumn get deletedAt =>
      dateTime().withDefault(currentDateAndTime)();
}