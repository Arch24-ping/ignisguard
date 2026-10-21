import 'package:firebase_auth/firebase_auth.dart';
import '../data/cloud_store.dart';

class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

  final FirebaseAuth _auth = FirebaseAuth.instance;

  Stream<User?> get changes => _auth.authStateChanges();
  User? get user => _auth.currentUser;

  Future<void> signUp(String email, String password) =>
      _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

  Future<void> signIn(String email, String password) =>
      _auth.signInWithEmailAndPassword(email: email.trim(), password: password);

  Future<void> resetPassword(String email) =>
      _auth.sendPasswordResetEmail(email: email.trim());

    Future<void> signOut() async {
    await _auth.signOut();
    CloudStore.instance.detach();
  }

  /// Turns a Firebase error into a message a person can act on.
  static String message(Object e) {
    if (e is FirebaseAuthException) {
      switch (e.code) {
        case 'invalid-email':
          return 'That email address is not valid.';
        case 'user-not-found':
        case 'wrong-password':
        case 'invalid-credential':
          return 'Email or password is incorrect.';
        case 'email-already-in-use':
          return 'An account with this email already exists. Sign in instead.';
        case 'weak-password':
          return 'Password is too weak. Use at least 8 characters.';
        case 'network-request-failed':
          return 'No internet connection. Connect and try again.';
        case 'too-many-requests':
          return 'Too many attempts. Wait a few minutes and try again.';
        case 'user-disabled':
          return 'This account has been disabled.';
      }
    }
    return 'Something went wrong. Please try again.';
  }
}