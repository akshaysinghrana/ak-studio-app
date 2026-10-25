import 'package:firebase_auth/firebase_auth.dart';

class AppUser {
  const AppUser({required this.uid, this.email});

  final String uid;
  final String? email;
}

/// User-facing authentication failure (never contains tokens).
class AuthFailure implements Exception {
  const AuthFailure(this.message, {this.code});

  final String message;
  final String? code;

  @override
  String toString() => message;
}

/// Email/password authentication (spec 9.1). Local playback never depends on
/// it; guests use the whole app offline.
abstract interface class AuthRepository {
  /// False when no backend is configured for this build.
  bool get isConfigured;

  Stream<AppUser?> authStateChanges();
  AppUser? get currentUser;

  Future<AppUser> signIn(String email, String password);
  Future<AppUser> register(String email, String password);
  Future<void> sendPasswordReset(String email);
  Future<void> signOut();

  /// Deletes the account; requires the password because providers demand a
  /// recent sign-in. [beforeDelete] runs after re-authentication and before
  /// the account is removed (e.g. deleting cloud data while still allowed).
  Future<void> deleteAccount(
    String password, {
    Future<void> Function()? beforeDelete,
  });
}

class UnconfiguredAuthRepository implements AuthRepository {
  const UnconfiguredAuthRepository();

  static const _failure = AuthFailure(
    'Accounts are not set up in this build. Everything else works without '
    'an account.',
    code: 'not-configured',
  );

  @override
  bool get isConfigured => false;

  @override
  Stream<AppUser?> authStateChanges() => Stream.value(null);

  @override
  AppUser? get currentUser => null;

  @override
  Future<AppUser> signIn(String email, String password) => throw _failure;

  @override
  Future<AppUser> register(String email, String password) => throw _failure;

  @override
  Future<void> sendPasswordReset(String email) => throw _failure;

  @override
  Future<void> signOut() async {}

  @override
  Future<void> deleteAccount(
    String password, {
    Future<void> Function()? beforeDelete,
  }) => throw _failure;
}

class FirebaseAuthRepository implements AuthRepository {
  FirebaseAuthRepository(this._auth);

  final FirebaseAuth _auth;

  @override
  bool get isConfigured => true;

  static AppUser? _map(User? u) =>
      u == null ? null : AppUser(uid: u.uid, email: u.email);

  @override
  Stream<AppUser?> authStateChanges() => _auth.authStateChanges().map(_map);

  @override
  AppUser? get currentUser => _map(_auth.currentUser);

  @override
  Future<AppUser> signIn(String email, String password) => _guard(() async {
    final c = await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    return _map(c.user)!;
  });

  @override
  Future<AppUser> register(String email, String password) => _guard(() async {
    final c = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    return _map(c.user)!;
  });

  @override
  Future<void> sendPasswordReset(String email) =>
      _guard(() => _auth.sendPasswordResetEmail(email: email.trim()));

  @override
  Future<void> signOut() => _auth.signOut();

  @override
  Future<void> deleteAccount(
    String password, {
    Future<void> Function()? beforeDelete,
  }) => _guard(() async {
    final user = _auth.currentUser;
    if (user == null || user.email == null) {
      throw const AuthFailure('You are not signed in.');
    }
    await user.reauthenticateWithCredential(
      EmailAuthProvider.credential(email: user.email!, password: password),
    );
    await beforeDelete?.call();
    await user.delete();
  });

  Future<T> _guard<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on FirebaseAuthException catch (e) {
      throw AuthFailure(messageFor(e.code), code: e.code);
    }
  }

  /// Friendly messages for provider error codes.
  static String messageFor(String code) => switch (code) {
    'invalid-email' => 'That email address is not valid.',
    'user-disabled' => 'This account has been disabled.',
    'user-not-found' ||
    'wrong-password' ||
    'invalid-credential' => 'Email or password is incorrect.',
    'email-already-in-use' => 'An account already exists for that email.',
    'weak-password' => 'Choose a stronger password (at least 6 characters).',
    'too-many-requests' => 'Too many attempts. Try again later.',
    'network-request-failed' =>
      'No connection. Check your network; playback still works offline.',
    'requires-recent-login' => 'Please enter your password again.',
    'operation-not-allowed' => 'Email sign-in is not enabled for this project.',
    _ => 'Something went wrong ($code). Please try again.',
  };
}

/// Client-side checks before calling the provider.
abstract final class AuthValidation {
  static final _email = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  static String? email(String? v) =>
      v == null || !_email.hasMatch(v.trim()) ? 'Enter a valid email.' : null;

  static String? password(String? v) =>
      v == null || v.length < 6 ? 'Use at least 6 characters.' : null;
}
