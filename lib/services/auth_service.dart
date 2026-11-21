import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  AuthService._();
  static final instance = AuthService._();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Stream<User?> get authStateChanges => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;

  Future<void> register({
    required String firstName,
    required String lastName,
    required String role,
    required String email,
    required String password,
  }) async {
    final first = firstName.trim();
    final last = lastName.trim();
    final selectedRole = role.trim();
    if (first.isEmpty || last.isEmpty || selectedRole.isEmpty) {
      throw ArgumentError('First name, last name and role are required.');
    }
    final result = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    final user = result.user;
    if (user == null) throw StateError('Account creation failed.');
    // If this write fails, AuthGate keeps the user in the profile-recovery screen.
    await createProfileIfMissing(
      uid: user.uid,
      firstName: first,
      lastName: last,
      role: selectedRole,
    );
  }

  Future<void> createProfileIfMissing({
    required String uid,
    required String firstName,
    required String lastName,
    required String role,
  }) async {
    if (_auth.currentUser?.uid != uid) throw StateError('Sign in first.');
    final doc = _db.collection('users').doc(uid);
    // Firestore rules permit creation only, preventing timestamp reset.
    await doc.set({
      'uid': uid,
      'firstName': firstName.trim(),
      'lastName': lastName.trim(),
      'role': role.trim(),
      'registrationDateTime': FieldValue.serverTimestamp(),
    });
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>> profileStream(String uid) =>
      _db.collection('users').doc(uid).snapshots();

  Future<void> signIn(String email, String password) async =>
      _auth.signInWithEmailAndPassword(email: email.trim(), password: password);
  Future<void> signOut() => _auth.signOut();

  Future<void> updatePassword(
    String currentPassword,
    String newPassword,
  ) async {
    final user = _auth.currentUser;
    if (user?.email == null) throw StateError('Please sign in again.');
    await user!.reauthenticateWithCredential(
      EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      ),
    );
    await user.updatePassword(newPassword);
  }

  static String errorMessage(Object error) {
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'email-already-in-use':
          return 'This email is already registered. Sign in instead.';
        case 'invalid-email':
          return 'Enter a valid email.';
        case 'weak-password':
          return 'Choose a stronger password.';
        case 'wrong-password':
        case 'invalid-credential':
        case 'user-not-found':
          return 'Incorrect email or password.';
        case 'network-request-failed':
          return 'Network error. Check your connection.';
        default:
          return error.message ?? error.code;
      }
    }
    if (error is FirebaseException) return error.message ?? error.code;
    return error.toString();
  }
}
