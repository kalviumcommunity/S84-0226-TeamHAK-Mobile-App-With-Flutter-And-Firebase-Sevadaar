import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../models/user_model.dart';
import 'ngo_service.dart';

/// Handles Firebase Authentication + Firestore user profile operations.
class AuthService {
  // Lazy-load Firebase instances to handle platforms without Firebase support
  FirebaseAuth? _authInstance;
  FirebaseFirestore? _dbInstance;

  /// Lazily initialize FirebaseAuth, handling cases where it's not available
  FirebaseAuth get _auth {
    try {
      return _authInstance ??= FirebaseAuth.instance;
    } catch (e) {
      throw Exception('Firebase not initialized. Feature unavailable on this platform.');
    }
  }

  /// Lazily initialize Firestore, handling cases where it's not available
  FirebaseFirestore get _db {
    try {
      return _dbInstance ??= FirebaseFirestore.instance;
    } catch (e) {
      throw Exception('Firebase not initialized. Feature unavailable on this platform.');
    }
  }

  /// Current Firebase user (null if signed-out or Firebase unavailable).
  User? get currentUser {
    try {
      return _auth.currentUser;
    } catch (e) {
      return null;
    }
  }

  /// Auth state stream.
  Stream<User?> get authStateChanges {
    try {
      return _auth.authStateChanges();
    } catch (e) {
      // Return an empty stream on platforms without Firebase
      return Stream.empty();
    }
  }

  // ── Sign Up ─────────────────────────────────────────────────────
  /// Creates a new Firebase Auth user + writes a `users` doc in Firestore.
  /// NGO code is OPTIONAL — user signs up as volunteer.
  Future<UserModel> signUp({
    required String name,
    required String email,
    required String password,
    String? ngoCode,
  }) async {
    String? resolvedNgoId;

    // Validate NGO code if provided
    if (ngoCode != null && ngoCode.trim().isNotEmpty) {
      final ngoService = NgoService();
      final ngo = await ngoService.validateJoinCode(ngoCode.trim());
      if (ngo == null) throw Exception('Invalid NGO code. Please check and try again.');
      resolvedNgoId = ngo.ngoId;
    }

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
      ngoId: resolvedNgoId,
      orgId: resolvedNgoId,
      ngoRequestStatus: 'none',
      createdAt: DateTime.now(),
    );

    // 3. Store in Firestore `users` collection
    await _db.collection('users').doc(uid).set(user.toMap());

    // 4. Update display name in Firebase Auth
    await cred.user!.updateDisplayName(name.trim());

    return user;
  }

  // ── Google Sign-In ──────────────────────────────────────────────
  /// Signs in with Google. Returns the Firebase User credential.
  /// Checks by both UID and email to support pre-created accounts.
  /// If the user is new (no Firestore doc), returns null UserModel so
  /// the caller can redirect to the post-Google signup form.
  Future<({User firebaseUser, UserModel? profile, bool isNewUser})>
      signInWithGoogle() async {
    final googleUser = await GoogleSignIn().signIn();
    if (googleUser == null) {
      throw Exception('Google sign-in was cancelled.');
    }

    final googleAuth = await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    final cred = await _auth.signInWithCredential(credential);
    final uid = cred.user!.uid;
    final email = cred.user!.email ?? '';

    // 1. First check by UID (normal flow)
    final docByUid = await _db.collection('users').doc(uid).get();
    if (docByUid.exists) {
      return (
        firebaseUser: cred.user!,
        profile: UserModel.fromMap(docByUid.data()!, uid),
        isNewUser: false,
      );
    }

    // 2. Check by email for pre-created accounts (e.g., super admin)
    if (email.isNotEmpty) {
      final docByEmail = await _db
          .collection('users')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();

      if (docByEmail.docs.isNotEmpty) {
        final existingDoc = docByEmail.docs.first;
        final userProfile = UserModel.fromMap(existingDoc.data(), existingDoc.id);

        // Update the uid to match Firebase Auth UID for future logins (BLOCKING to prevent race condition)
        try {
          await _db.collection('users').doc(existingDoc.id).update({
            'uid': uid,
            'updatedAt': DateTime.now(),
          });
        } catch (e) {
          // Silently fail if uid update doesn't work
        }

        return (
          firebaseUser: cred.user!,
          profile: userProfile,
          isNewUser: false,
        );
      }
    }

    // 3. New Google user — no Firestore profile yet
    return (
      firebaseUser: cred.user!,
      profile: null,
      isNewUser: true,
    );
  }

  /// Completes the profile for a Google-signed-in user. ngoCode is OPTIONAL.
  Future<UserModel> completeGoogleSignUp({
    required String uid,
    required String name,
    required String email,
    String? ngoCode,
  }) async {
    String? resolvedNgoId;
    if (ngoCode != null && ngoCode.trim().isNotEmpty) {
      final ngoService = NgoService();
      final ngo = await ngoService.validateJoinCode(ngoCode.trim());
      if (ngo == null) throw Exception('Invalid NGO code. Please check and try again.');
      resolvedNgoId = ngo.ngoId;
    }

    final user = UserModel(
      uid: uid,
      name: name.trim(),
      email: email.trim(),
      role: 'volunteer',
      status: 'active',
      ngoId: resolvedNgoId,
      orgId: resolvedNgoId,
      ngoRequestStatus: 'none',
      createdAt: DateTime.now(),
    );

    await _db.collection('users').doc(uid).set(user.toMap());
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
  /// Falls back to email lookup if uid not found (for pre-created accounts).
  Future<UserModel> getUserProfile(String uid) async {
    // 1. Try by uid (normal case)
    final doc = await _db.collection('users').doc(uid).get();
    if (doc.exists) {
      return UserModel.fromMap(doc.data()!, uid);
    }

    // 2. Fallback: Try by email from Firebase Auth (handles pre-created accounts)
    final firebaseUser = _auth.currentUser;
    if (firebaseUser?.email != null && firebaseUser!.email!.isNotEmpty) {
      final emailQuery = await _db
          .collection('users')
          .where('email', isEqualTo: firebaseUser.email)
          .limit(1)
          .get();

      if (emailQuery.docs.isNotEmpty) {
        final emailDoc = emailQuery.docs.first;
        return UserModel.fromMap(emailDoc.data(), emailDoc.id);
      }
    }

    throw Exception('User profile not found in Firestore.');
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
