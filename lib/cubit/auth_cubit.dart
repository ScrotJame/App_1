import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../commons/enums.dart';
import '../repository/user_repository.dart';
import '../service/auth_service.dart';

part 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  final AuthService _authService;
  final UserRepository _userRepository;
  StreamSubscription<User?>? _authSub;

  AuthCubit(this._authService, this._userRepository)
      : super(const AuthState());

  // ─── Khởi tạo: lắng nghe auth state ────────────────────────────────────

  Future<void> init() async {
    _authSub = _authService.authStateChanges.listen(_onAuthChanged);
    await checkAuthStatus();
  }

  Future<void> checkAuthStatus() async {
    final user = _authService.getCurrentFirebaseUser();
    if (user != null) {
      await _onAuthSuccess(user);
    } else {
      emit(const AuthState(status: AuthStatus.unauthenticated));
    }
  }

  void _onAuthChanged(User? user) {
    if (user == null && state.status == AuthStatus.authenticated) {
      emit(const AuthState(status: AuthStatus.unauthenticated));
    }
  }

  // ─── Sign in with Google ───────────────────────────────────────────────

  Future<void> signInWithGoogle() async {
    emit(state.copyWith(status: AuthStatus.loading));
    try {
      final user = await _authService.signInWithGoogle();
      if (user != null) {
        await _onAuthSuccess(user);
      } else {
        emit(state.copyWith(
          status: AuthStatus.unauthenticated,
          errorMessage: 'Đăng nhập Google bị hủy',
        ));
      }
    } catch (e) {
      emit(state.copyWith(
        status: AuthStatus.error,
        errorMessage: 'Đăng nhập Google thất bại: $e',
      ));
    }
  }

  // ─── Sign in with Email ────────────────────────────────────────────────

  Future<void> signInWithEmail(String email, String password) async {
    if (email.trim().isEmpty || password.trim().isEmpty) {
      emit(state.copyWith(
        status: AuthStatus.error,
        errorMessage: 'Email và mật khẩu không được để trống',
      ));
      return;
    }
    emit(state.copyWith(status: AuthStatus.loading));
    try {
      final user = await _authService.signInWithEmail(email, password);
      if (user != null) {
        await _onAuthSuccess(user);
      } else {
        emit(state.copyWith(
          status: AuthStatus.error,
          errorMessage: 'Đăng nhập thất bại',
        ));
      }
    } on FirebaseAuthException catch (e) {
      emit(state.copyWith(
        status: AuthStatus.error,
        errorMessage: _mapFirebaseError(e.code),
      ));
    } catch (e) {
      emit(state.copyWith(
        status: AuthStatus.error,
        errorMessage: 'Đăng nhập thất bại: $e',
      ));
    }
  }

  // ─── Register with Email ──────────────────────────────────────────────

  Future<void> registerWithEmail(String email, String password) async {
    if (email.trim().isEmpty || password.trim().isEmpty) {
      emit(state.copyWith(
        status: AuthStatus.error,
        errorMessage: 'Email và mật khẩu không được để trống',
      ));
      return;
    }
    emit(state.copyWith(status: AuthStatus.loading));
    try {
      final user = await _authService.registerWithEmail(email, password);
      if (user != null) {
        await _onAuthSuccess(user);
      } else {
        emit(state.copyWith(
          status: AuthStatus.error,
          errorMessage: 'Đăng ký thất bại',
        ));
      }
    } on FirebaseAuthException catch (e) {
      emit(state.copyWith(
        status: AuthStatus.error,
        errorMessage: _mapFirebaseError(e.code),
      ));
    } catch (e) {
      emit(state.copyWith(
        status: AuthStatus.error,
        errorMessage: 'Đăng ký thất bại: $e',
      ));
    }
  }

  // ─── Sign out ─────────────────────────────────────────────────────────

  Future<void> signOut() async {
    await _authService.signOut();
    emit(const AuthState(status: AuthStatus.unauthenticated));
  }

  // ─── Internal: xử lý sau auth thành công ──────────────────────────────

  Future<void> _onAuthSuccess(User user) async {
    try {
      // Link Firebase UID vào user local
      await _userRepository.linkAccount(user.uid);

      emit(state.copyWith(
        status: AuthStatus.authenticated,
        firebaseUser: user,
        backupKey: user.uid,
        clearError: true,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: AuthStatus.error,
        errorMessage: 'Kết nối tài khoản thất bại: $e',
      ));
    }
  }

  // ─── Map Firebase error code sang tiếng Việt ──────────────────────────

  String _mapFirebaseError(String code) {
    switch (code) {
      case 'user-not-found':
        return 'Tài khoản không tồn tại';
      case 'wrong-password':
        return 'Sai mật khẩu';
      case 'email-already-in-use':
        return 'Email đã được sử dụng';
      case 'weak-password':
        return 'Mật khẩu quá yếu (tối thiểu 6 ký tự)';
      case 'invalid-email':
        return 'Email không hợp lệ';
      case 'too-many-requests':
        return 'Quá nhiều lần thử. Vui lòng đợi một lát.';
      default:
        return 'Lỗi xác thực: $code';
    }
  }

  @override
  Future<void> close() {
    _authSub?.cancel();
    return super.close();
  }
}
