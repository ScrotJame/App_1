import 'package:drift/drift.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../commons/user_sesion.dart';
import '../database/app_db.dart';

abstract class IUserRepository {
  Future<UsersEntrieData?> getCurrentUser();
  Future<String?> getLocalKey();
  Stream<UsersEntrieData?> watchCurrentUser();
  Future<UsersEntrieData> createLocalUser(String username);
  Future<bool> updateUser(UsersEntrieCompanion user);
  Future<void> linkAccount(String serverId);
  Future<void> deleteLocalUser();
  Future<void> syncStreak();
  Future<int> markTodayStreak();
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

  @override
  Stream<UsersEntrieData?> watchCurrentUser() async* {
    final localKey = await _getLocalKey();
    if (localKey == null) {
      yield null;
      return;
    }

    yield* (_db.select(_db.usersEntrie)..where((u) => u.keyOpen.equals(localKey)))
        .watchSingleOrNull();
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

  Future<void> updateDB() async {
    final localKey = await _getLocalKey();
    if (localKey == null) return;
    await (_db.update(_db.usersEntrie)..where((t) => t.keyOpen.equals(localKey))).write(UsersEntrieCompanion(totalLearned: Value(4)));
  }

  @override
  Future<void> syncStreak() async {
    final user = await getCurrentUser();
    if (user == null) return;

    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList('streak_marked_dates') ?? [];
    var markedDates = list.toSet();

    if (markedDates.isEmpty &&
        user.currentStreak > 0 &&
        user.lastActiveDate != null) {
      final end = DateTime(user.lastActiveDate!.year, user.lastActiveDate!.month, user.lastActiveDate!.day);
      final generated = <String>{};
      for (int i = 0; i < user.currentStreak; i++) {
        final d = end.subtract(Duration(days: i));
        final key = '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
        generated.add(key);
      }
      markedDates = generated;
      await prefs.setStringList('streak_marked_dates', markedDates.toList());
    }

    final today = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
    final todayKey = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
    final yesterday = today.subtract(const Duration(days: 1));

    final startCursor = markedDates.contains(todayKey)
        ? today
        : yesterday;

    int currentStreak = 0;
    DateTime cursor = startCursor;

    while (true) {
      final key = '${cursor.year}-${cursor.month.toString().padLeft(2, '0')}-${cursor.day.toString().padLeft(2, '0')}';
      if (markedDates.contains(key)) {
        currentStreak++;
        cursor = cursor.subtract(const Duration(days: 1));
      } else {
        break;
      }
    }

    final longestStreak = currentStreak > user.longestStreak ? currentStreak : user.longestStreak;
    final lastActiveDate = currentStreak > 0 ? (user.lastActiveDate ?? DateTime.now()) : null;

    bool needsDbUpdate = false;
    if (user.currentStreak != currentStreak) needsDbUpdate = true;
    if (user.longestStreak != longestStreak) needsDbUpdate = true;
    if (user.lastActiveDate == null && lastActiveDate != null) needsDbUpdate = true;
    if (user.lastActiveDate != null && lastActiveDate == null) needsDbUpdate = true;

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
  Future<int> markTodayStreak() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList('streak_marked_dates') ?? [];
    final markedDates = list.toSet();

    final now = DateTime.now();
    final todayKey =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

    if (!markedDates.contains(todayKey)) {
      markedDates.add(todayKey);
      await prefs.setStringList('streak_marked_dates', markedDates.toList());
    }

    await syncStreak();

    final user = await getCurrentUser();
    return user?.currentStreak ?? 0;
  }
}