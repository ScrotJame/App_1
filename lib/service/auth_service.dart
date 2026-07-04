import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:uuid/uuid.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

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

  /// Lấy backupKey hiện có, hoặc tạo mới nếu chưa có.
  Future<String?> ensureBackupKey() async {
    final user = _auth.currentUser;
    if (user == null) return null;

    final ref = _db.collection('users_profile').doc(user.uid);
    final doc = await ref.get();
    final data = doc.data();

    if (data == null) {
      final newKey = const Uuid().v4();
      await ref.set(
        {
          'email': user.email,
          'displayName': user.displayName,
          'backupKey': newKey,
          'createdAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
      return newKey;
    }

    final existing = data['backupKey'] as String?;
    if (existing != null && existing.isNotEmpty) return existing;

    // Tạo key mới
    final newKey = const Uuid().v4();
    await ref.update({'backupKey': newKey});
    return newKey;
  }

  /// Lấy backupKey (read-only, không tạo mới)
  Future<String?> getBackupKey() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return null;

    final doc = await _db.collection('users_profile').doc(uid).get();
    return doc.data()?['backupKey'] as String?;
  }
}
