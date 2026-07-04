part of 'auth_cubit.dart';

enum AuthStatus { unauthenticated, loading, authenticated, error }

const _absent = Object();

class AuthState extends Equatable {
  const AuthState({
    this.status = AuthStatus.unauthenticated,
    this.firebaseUser,
    this.backupKey,
    this.errorMessage,
  });

  final AuthStatus status;
  final User? firebaseUser;
  final String? backupKey;
  final String? errorMessage;

  bool get isAuthenticated => status == AuthStatus.authenticated;
  bool get isLoading => status == AuthStatus.loading;

  /// Email hiển thị (Google hoặc Email/Password)
  String? get displayEmail => firebaseUser?.email;

  /// Tên hiển thị (Google hoặc email prefix)
  String get displayName =>
      firebaseUser?.displayName ??
      firebaseUser?.email?.split('@').first ??
      '';

  /// Avatar URL (từ Google)
  String? get photoUrl => firebaseUser?.photoURL;

  AuthState copyWith({
    AuthStatus? status,
    Object? firebaseUser = _absent,
    Object? backupKey = _absent,
    Object? errorMessage = _absent,
    bool clearError = false,
  }) {
    return AuthState(
      status: status ?? this.status,
      firebaseUser: firebaseUser == _absent
          ? this.firebaseUser
          : firebaseUser as User?,
      backupKey: backupKey == _absent
          ? this.backupKey
          : backupKey as String?,
      errorMessage: clearError
          ? null
          : (errorMessage == _absent
              ? this.errorMessage
              : errorMessage as String?),
    );
  }

  @override
  List<Object?> get props => [status, firebaseUser?.uid, backupKey, errorMessage];
}
