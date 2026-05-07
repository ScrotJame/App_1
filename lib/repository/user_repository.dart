import 'package:drift/drift.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../database/app_db.dart';

abstract class IUserRepository {
  Future<UsersEntrieData?> getCurrentUser();
  Future<UsersEntrieData> createLocalUser(String username);
  Future<bool> updateUser(UsersEntrieCompanion user);
  Future<void> linkAccount(String serverId);
  Future<void> deleteLocalUser();
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

  // ── Lấy thông tin user hiện tại ───────────────────────────
  @override
  Future<UsersEntrieData?> getCurrentUser() async {
    final localKey = await _getLocalKey();
    if (localKey == null) return null;

    return (_db.select(_db.usersEntrie)
      ..where((u) => u.keyOpen.equals(localKey)))
        .getSingleOrNull();
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

    return (await getCurrentUser())!;
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
  }
}