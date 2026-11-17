import 'package:drift/drift.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../commons/user_sesion.dart';
import '../database/app_db.dart';
import '../helper/level_helper.dart';
import '../helper/streak_date_helper.dart';

abstract class IUserRepository {
  Future<UsersEntrieData?> getCurrentUser();
  Future<String?> getLocalKey();
  Stream<UsersEntrieData?> watchCurrentUser();
  Future<UsersEntrieData> createLocalUser(String username);
  Future<bool> updateUser(UsersEntrieCompanion user);
  Future<bool> addGems(int amount);
  Future<XpGain?> addXp(int amount);
  Future<void> linkAccount(String serverId);
  Future<void> deleteLocalUser();
  Future<void> syncStreak({DateTime? now});
  Future<int> markTodayStreak({DateTime? now});
}

/// What [IUserRepository.addXp] left in the database.
class XpGain {
  const XpGain({
    required this.experience,
    required this.level,
    required this.leveledUp,
  });

  /// Total experience after the gain.
  final int experience;

  /// The user's level after the gain.
  final int level;

  /// Whether this gain pushed the user to a higher level.
  final bool leveledUp;
}

class UserRepository implements IUserRepository {
  final AppDatabase _db;
  static const _keyLocal = 'local_key';

  UserRepository(this._db);

  // ── Lấy localKey của máy này ──────────────────────────────
  Future<String?> _getLocalKey() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyLocal);
  }

  Stream<UsersEntrieData> watchUser(String userKey) {
    return (_db.select(_db.usersEntrie)
      ..where((t) => t.keyOpen.equals(userKey)))
        .watchSingle();
  }
  @override
  Future<String?> getLocalKey() => _getLocalKey();

  // ── Lấy thông tin user hiện tại ───────────────────────────
  @override
  Future<UsersEntrieData?> getCurrentUser() async {
    final localKey = await _getLocalKey();
    if (localKey == null) return null;

    return (_db.select(_db.usersEntrie)
      ..where((u) => u.keyOpen.equals(localKey)))
        .getSingleOrNull();
  }

  /// Follows the row of the device's user. The local key is looked up on
  /// every change of the users table, so a listener that subscribed before
  /// the first user existed still receives that user once it is created.
  @override
  Stream<UsersEntrieData?> watchCurrentUser() {
    return _db.select(_db.usersEntrie).watch().asyncMap((users) async {
      final localKey = await _getLocalKey();
      if (localKey == null) return null;
      for (final user in users) {
        if (user.keyOpen == localKey) return user;
      }
      return null;
    });
  }

  // ── Tạo user local lần đầu mở app ────────────────────────
  @override
  Future<UsersEntrieData> createLocalUser(String username) async {
    final localKey = const Uuid().v4();

    await _db.into(_db.usersEntrie).insert(
      UsersEntrieCompanion.insert(
        keyOpen: localKey,
        username: username,
        createdAt: Value(DateTime.now()),
        updatedAt: Value(DateTime.now()),
      ),
    );

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyLocal, localKey);
    // The row was inserted before the key was stored, so watchers looked it up
    // too early. Run them again now that the key points at the new user.
    _db.notifyUpdates({
      TableUpdate.onTable(_db.usersEntrie, kind: UpdateKind.update),
    });

    final row = (await getCurrentUser())!;
    UserSession.instance.syncFromUser(row);
    return row;
  }

  // ── Cập nhật thông tin user ───────────────────────────────
  @override
  Future<bool> updateUser(UsersEntrieCompanion user) async {
    final localKey = await _getLocalKey();
    if (localKey == null) return false;

    final now = DateTime.now();
    final userWithTimestamp = user.updatedAt.present
        ? user
        : user.copyWith(updatedAt: Value(now));

    final count = await (_db.update(_db.usersEntrie)
      ..where((u) => u.keyOpen.equals(localKey)))
        .write(userWithTimestamp);
    return count > 0;
  }

  // ── Cộng gems ─────────────────────────────────────────────
  /// Cộng ngay trong câu UPDATE (gems = gems + amount) thay vì đọc rồi ghi
  /// lại, nên hai lần cộng sát nhau không ghi đè lên nhau.
  @override
  Future<bool> addGems(int amount) async {
    if (amount <= 0) return false;
    final localKey = await _getLocalKey();
    if (localKey == null) return false;

    final count = await (_db.update(_db.usersEntrie)
          ..where((u) => u.keyOpen.equals(localKey)))
        .write(UsersEntrieCompanion.custom(
      gems: _db.usersEntrie.gems + Constant(amount),
      updatedAt: Variable(DateTime.now()),
    ));
    return count > 0;
  }

  // ── Cộng XP ───────────────────────────────────────────────
  /// Adds [amount] to the user's experience and keeps `level` in step with
  /// it. The sum is done in SQL inside one transaction, so two gains landing
  /// back to back are both kept. Returns null when nothing was added.
  @override
  Future<XpGain?> addXp(int amount) async {
    if (amount <= 0) return null;
    final localKey = await _getLocalKey();
    if (localKey == null) return null;

    final users = _db.usersEntrie;
    return _db.transaction(() async {
      final now = DateTime.now();
      final count = await (_db.update(users)
            ..where((u) => u.keyOpen.equals(localKey)))
          .write(UsersEntrieCompanion.custom(
        experience: users.experience + Constant(amount),
        updatedAt: Variable(now),
      ));
      if (count == 0) return null;

      final user = await (_db.select(users)
            ..where((u) => u.keyOpen.equals(localKey)))
          .getSingle();
      final newLevel = LevelHelper.calculate(user.experience).level;
      final leveledUp = newLevel > user.level;
      if (leveledUp) {
        await (_db.update(users)..where((u) => u.keyOpen.equals(localKey)))
            .write(UsersEntrieCompanion(level: Value(newLevel)));
      }

      return XpGain(
        experience: user.experience,
        level: leveledUp ? newLevel : user.level,
        leveledUp: leveledUp,
      );
    });
  }

  // ── Gán id thật sau khi đăng nhập ────────────────────────
  @override
  Future<void> linkAccount(String serverId) async {
    final localKey = await _getLocalKey();
    if (localKey == null) return;

    await (_db.update(_db.usersEntrie)
      ..where((u) => u.keyOpen.equals(localKey)))
        .write(UsersEntrieCompanion(id: Value(serverId)));
    final u = await getCurrentUser();
    if (u != null) UserSession.instance.syncFromUser(u);
  }

  // ── Xóa user local (logout) ───────────────────────────────
  @override
  Future<void> deleteLocalUser() async {
    final localKey = await _getLocalKey();
    if (localKey == null) return;

    await (_db.delete(_db.usersEntrie)
      ..where((u) => u.keyOpen.equals(localKey)))
        .go();

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyLocal);
    UserSession.instance.clear();
  }

  /// Recomputes the streak columns from the marked days in SharedPreferences.
  ///
  /// `lastActiveDate` is the latest marked day of the current streak. When the
  /// marked days are missing (new install restored from a backup) they are
  /// rebuilt as the `currentStreak` days that end on `lastActiveDate`.
  @override
  Future<void> syncStreak({DateTime? now}) async {
    final user = await getCurrentUser();
    if (user == null) return;

    final prefs = await SharedPreferences.getInstance();
    var markedDates =
        (prefs.getStringList(StreakDateHelper.prefKey) ?? []).toSet();

    final storedLastActive = user.lastActiveDate;
    if (markedDates.isEmpty &&
        user.currentStreak > 0 &&
        storedLastActive != null) {
      markedDates =
          StreakDateHelper.runEndingOn(storedLastActive, user.currentStreak);
      await prefs.setStringList(
          StreakDateHelper.prefKey, markedDates.toList());
    }

    final today = StreakDateHelper.dateOnly(now ?? DateTime.now());
    final lastMarkedDay =
        markedDates.contains(StreakDateHelper.keyOf(today))
            ? today
            : StreakDateHelper.daysBefore(today, 1);

    int currentStreak = 0;
    while (markedDates.contains(StreakDateHelper.keyOf(
        StreakDateHelper.daysBefore(lastMarkedDay, currentStreak)))) {
      currentStreak++;
    }

    final longestStreak = currentStreak > user.longestStreak
        ? currentStreak
        : user.longestStreak;
    final lastActiveDate = currentStreak > 0 ? lastMarkedDay : null;

    final needsDbUpdate = user.currentStreak != currentStreak ||
        user.longestStreak != longestStreak ||
        !_isSameDay(storedLastActive, lastActiveDate);

    if (needsDbUpdate) {
      await updateUser(
        UsersEntrieCompanion(
          currentStreak: Value(currentStreak),
          longestStreak: Value(longestStreak),
          lastActiveDate: Value(lastActiveDate),
        ),
      );
    }
  }

  @override
  Future<int> markTodayStreak({DateTime? now}) async {
    final prefs = await SharedPreferences.getInstance();
    final markedDates =
        (prefs.getStringList(StreakDateHelper.prefKey) ?? []).toSet();

    final todayKey = StreakDateHelper.keyOf(now ?? DateTime.now());

    if (markedDates.add(todayKey)) {
      await prefs.setStringList(
          StreakDateHelper.prefKey, markedDates.toList());
    }

    await syncStreak(now: now);

    final user = await getCurrentUser();
    return user?.currentStreak ?? 0;
  }

  bool _isSameDay(DateTime? a, DateTime? b) {
    if (a == null || b == null) return a == b;
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}
