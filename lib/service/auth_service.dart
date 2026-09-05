import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final FirebaseAuth? _customAuth;
  final FirebaseFirestore? _customDb;

  AuthService({FirebaseAuth? auth, FirebaseFirestore? firestore})
      : _customAuth = auth,
        _customDb = firestore;

  FirebaseAuth get _auth => _customAuth ?? FirebaseAuth.instance;
  FirebaseFirestore get _db => _customDb ?? FirebaseFirestore.instance;

  // ─── Stream & getter ────────────────────────────────────────────────────

  /// Stream theo dõi trạng thái auth (dùng cho AuthCubit.init)
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// User hiện tại (null nếu chưa đăng nhập)
  User? get currentUser => _auth.currentUser;

  User? getCurrentFirebaseUser() => _auth.currentUser;

  // ─── Profile Firestore ──────────────────────────────────────────────────

  Future<void> _ensureProfile(User user) async {
    final ref = _db.collection('users_profile').doc(user.uid);
    final doc = await ref.get();
    if (!doc.exists) {
      await ref.set({
        'email': user.email,
        'displayName': user.displayName,
        'backupKey': null,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
  }

  // ─── Register / Sign in ─────────────────────────────────────────────────

  Future<User?> registerWithEmail(String email, String password) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email, password: password,
    );
    if (cred.user != null) await _ensureProfile(cred.user!);
    return cred.user;
  }

  Future<User?> signInWithEmail(String email, String password) async {
    final cred = await _auth.signInWithEmailAndPassword(
      email: email, password: password,
    );
    return cred.user;
  }

  Future<User?> signInWithGoogle() async {
    final GoogleSignInAccount googleUser =
        await GoogleSignIn.instance.authenticate();

    final googleAuth = googleUser.authentication;

    final clientAuth =
        await googleUser.authorizationClient.authorizeScopes(['email', 'profile']);

    final credential = GoogleAuthProvider.credential(
      idToken: googleAuth.idToken,
      accessToken: clientAuth.accessToken,
    );

    final cred = await _auth.signInWithCredential(credential);
    if (cred.additionalUserInfo?.isNewUser == true) {
      await _ensureProfile(cred.user!);
    }
    return cred.user;
  }

  Future<User?> signInWithApple() async {
    final provider = AppleAuthProvider()
      ..addScope('email')
      ..addScope('name');

    final cred = await _auth.signInWithProvider(provider);
    if (cred.additionalUserInfo?.isNewUser == true) {
      await _ensureProfile(cred.user!);
    }
    return cred.user;
  }

  // ─── Sign out ─────────────────────────────────────────────────────────

  Future<void> logout() async {
    // Sign out Google nếu đang dùng
    try {
      await GoogleSignIn.instance.signOut();
    } catch (_) {}
    await _auth.signOut();
  }

  Future<void> signOut() => logout();

  // ─── Backup key ───────────────────────────────────────────────────────
  //
  // Không tự sinh uuid nữa. Dùng thẳng `uid` — Firebase Auth đã tự tạo sẵn,
  // đảm bảo duy nhất toàn hệ thống, không cần round-trip Firestore để lấy
  // hay tạo key riêng.

  /// Backup key hiện tại = uid (null nếu chưa đăng nhập).
  String? get backupKey => _auth.currentUser?.uid;

  /// Giữ signature Future để không phải sửa chỗ gọi cũ (BackupRepository).
  Future<String?> getBackupKey() async => _auth.currentUser?.uid;
}