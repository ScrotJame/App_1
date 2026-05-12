import 'package:test_abc/database/app_db.dart';

/// Identity toàn app: [globalId] (server khi đã tài khoản, không thì guest [keyOpen]).
/// Cột FK trong Drift vẫn trỏ [UsersEntrie.keyOpen] → dùng [keyOpen] / [dbUserKey].
class UserSession {
  UserSession._();
  static final UserSession instance = UserSession._();

  String _keyOpen = '';
  String? _id;

  /// PK local trong DB — mọi `userId` FK.
  String get keyOpen => _keyOpen;

  /// Cùng ý [keyOpen] (tiến độ từ, companion local, …).
  String get dbUserKey => _keyOpen;

  /// `UsersEntrie.id` khi đã link server; null nếu chỉ guest.
  String? get accountId {
    final v = _id;
    if (v == null || v.isEmpty) return null;
    return v;
  }

  /// Một id dùng chung: có tài khoản → [id], chưa → [keyOpen].
  String get globalId => accountId ?? _keyOpen;

  /// Giữ tương thích code cũ: luôn là khóa DB ([keyOpen]).
  String get userKey => dbUserKey;

  void syncFromUser(UsersEntrieData user) {
    _keyOpen = user.keyOpen;
    _id = user.id;
  }

  void clear() {
    _keyOpen = '';
    _id = null;
  }

  bool get isLoggedIn => _keyOpen.isNotEmpty;
  bool get hasLinkedAccount => accountId != null;
}
