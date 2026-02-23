import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

/// Handles Firebase Authentication + Firestore user profile operations.
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Current Firebase user (null if signed-out).
  User? get currentUser => _auth.currentUser;

  /// Auth state stream.
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // ── Sign Up ─────────────────────────────────────────────────────
  /// Creates a new Firebase Auth user + writes a `users` doc in Firestore.
  /// All new users register as **Volunteer** by default (as per LLD).
  Future<UserModel> signUp({
    required String name,
    required String email,
    required String password,
  }) async {
    // 1. Create auth account
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );

    final uid = cred.user!.uid;

    // 2. Build profile model
    final user = UserModel(
      uid: uid,
      name: name.trim(),
      email: email.trim(),
      role: 'volunteer',
      status: 'active',
      createdAt: DateTime.now(),
    );

    // 3. Store in Firestore `users` collection
    await _db.collection('users').doc(uid).set(user.toMap());

    // 4. Update display name in Firebase Auth
    await cred.user!.updateDisplayName(name.trim());

    return user;
  }

  // ── Sign In ─────────────────────────────────────────────────────
  /// Signs in with email & password, returns the Firestore user profile.
  Future<UserModel> signIn({
    required String email,
    required String password,
  }) async {
    final cred = await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );

    return await getUserProfile(cred.user!.uid);
  }

  // ── Get User Profile ────────────────────────────────────────────
  /// Reads the Firestore doc for the given uid.
  Future<UserModel> getUserProfile(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    if (!doc.exists) {
      throw Exception('User profile not found in Firestore.');
    }
    return UserModel.fromMap(doc.data()!, uid);
  }

  // ── Sign Out ────────────────────────────────────────────────────
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // ── Password Reset ──────────────────────────────────────────────
  Future<void> resetPassword(String email) async {
    await _auth.sendPasswordResetEmail(email: email.trim());
  }

  // ── Helpers ─────────────────────────────────────────────────────
  /// Translates FirebaseAuthException codes into user-friendly messages.
  static String getFriendlyError(FirebaseAuthException e) {
    switch (e.code) {
      case 'email-already-in-use':
        return 'An account with this email already exists.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'weak-password':
        return 'Password must be at least 6 characters.';
      case 'user-not-found':
        return 'No account found with this email.';
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      case 'too-many-requests':
        return 'Too many attempts. Try again later.';
      case 'invalid-credential':
        return 'Invalid email or password.';
      default:
        return e.message ?? 'An unexpected error occurred.';
    }
  }
}
