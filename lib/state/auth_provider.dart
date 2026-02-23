import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';

/// Singleton instance of [AuthService].
final authServiceProvider = Provider<AuthService>((ref) => AuthService());

/// Streams the raw Firebase Auth state (User? — logged in or not).
final authStateProvider = StreamProvider<User?>((ref) {
  return ref.read(authServiceProvider).authStateChanges;
});

/// Holds the currently loaded Firestore [UserModel] after login.
/// Set explicitly after login / signup flows complete.
final currentUserProvider = StateProvider<UserModel?>((ref) => null);
