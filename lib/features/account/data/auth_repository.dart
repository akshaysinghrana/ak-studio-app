import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../../google_sign_in_options.dart';

enum SignInMethod { password, google }

class AppUser {
  const AppUser({
    required this.uid,
    this.email,
    this.displayName,
    this.photoUrl,
    this.methods = const {},
  });

  final String uid;
  final String? email;
  final String? displayName;
  final String? photoUrl;

  /// How this account can sign in (password and/or Google).
  final Set<SignInMethod> methods;

  bool get usesGoogle => methods.contains(SignInMethod.google);
  bool get usesPassword => methods.contains(SignInMethod.password);
}

/// User-facing authentication failure (never contains tokens).
class AuthFailure implements Exception {
  const AuthFailure(this.message, {this.code});

  final String message;
  final String? code;

  /// The user closed the Google account picker: not an error to show.
  bool get isCancelled => code == 'canceled';

  @override
  String toString() => message;
}

/// Account authentication (spec 9.1): email/password and Google, backed by
/// Firebase Auth behind the app's own screens. Local playback never depends
/// on it; guests use the whole app offline.
abstract interface class AuthRepository {
  /// False when no backend is configured for this build.
  bool get isConfigured;

  Stream<AppUser?> authStateChanges();
  AppUser? get currentUser;

  Future<AppUser> signIn(String email, String password);
  Future<AppUser> register(String email, String password);

  /// Shows Google's account picker and signs in to Firebase with the chosen
  /// account (creating the Firebase account on first use).
  Future<AppUser> signInWithGoogle();

  Future<void> sendPasswordReset(String email);
  Future<void> signOut();

  /// Deletes the account. Providers demand a recent sign-in: password
  /// accounts pass [password]; Google accounts confirm with Google again.
  /// [beforeDelete] runs after re-authentication and before the account is
  /// removed (e.g. deleting cloud data while still allowed).
  Future<void> deleteAccount({
    String? password,
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
  Future<AppUser> signInWithGoogle() => throw _failure;

  @override
  Future<void> sendPasswordReset(String email) => throw _failure;

  @override
  Future<void> signOut() async {}

  @override
  Future<void> deleteAccount({
    String? password,
    Future<void> Function()? beforeDelete,
  }) => throw _failure;
}

class FirebaseAuthRepository implements AuthRepository {
  FirebaseAuthRepository(this._auth, {GoogleSignIn? google})
    : _google = google ?? GoogleSignIn.instance;

  final FirebaseAuth _auth;
  final GoogleSignIn _google;
  Future<void>? _googleInit;

  @override
  bool get isConfigured => true;

  static AppUser? _map(User? u) => u == null
      ? null
      : AppUser(
          uid: u.uid,
          email: u.email,
          displayName: u.displayName,
          photoUrl: u.photoURL,
          methods: {
            for (final p in u.providerData)
              if (p.providerId == GoogleAuthProvider.PROVIDER_ID)
                SignInMethod.google
              else if (p.providerId == EmailAuthProvider.PROVIDER_ID)
                SignInMethod.password,
          },
        );

  @override
  Stream<AppUser?> authStateChanges() => _auth.userChanges().map(_map);

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
  Future<AppUser> signInWithGoogle() => _guard(() async {
    final c = await _auth.signInWithCredential(await _googleCredential());
    return _map(c.user)!;
  });

  /// Google account picker → Firebase credential from the Google ID token.
  Future<AuthCredential> _googleCredential() async {
    _googleInit ??= _google.initialize(serverClientId: googleWebClientId);
    try {
      await _googleInit;
      final account = await _google.authenticate();
      final idToken = account.authentication.idToken;
      if (idToken == null) {
        throw const AuthFailure(
          'Google did not return a sign-in token. Check the Web client ID '
          'and SHA-1 fingerprint in the Firebase setup.',
          code: 'no-id-token',
        );
      }
      return GoogleAuthProvider.credential(idToken: idToken);
    } on GoogleSignInException catch (e) {
      throw switch (e.code) {
        GoogleSignInExceptionCode.canceled ||
        GoogleSignInExceptionCode.interrupted => const AuthFailure(
          'Google sign-in was cancelled.',
          code: 'canceled',
        ),
        GoogleSignInExceptionCode.clientConfigurationError ||
        GoogleSignInExceptionCode.providerConfigurationError =>
          const AuthFailure(
            'Google sign-in is not set up for this app yet (Firebase Web '
            'client ID or SHA-1 fingerprint missing).',
            code: 'google-not-configured',
          ),
        GoogleSignInExceptionCode.uiUnavailable => const AuthFailure(
          'Google sign-in could not open. Check that Google Play services are '
          'available and try again.',
          code: 'google-ui-unavailable',
        ),
        _ => AuthFailure(
          'Google sign-in failed. Please try again.',
          code: 'google-${e.code.name}',
        ),
      };
    }
  }

  @override
  Future<void> sendPasswordReset(String email) =>
      _guard(() => _auth.sendPasswordResetEmail(email: email.trim()));

  @override
  Future<void> signOut() async {
    await _auth.signOut();
    // Also forget the Google account choice, so the picker shows next time.
    if (_googleInit != null) {
      try {
        await _google.signOut();
      } on Exception {
        // Not signed in with Google on this device: nothing to clear.
      }
    }
  }

  @override
  Future<void> deleteAccount({
    String? password,
    Future<void> Function()? beforeDelete,
  }) => _guard(() async {
    final user = _auth.currentUser;
    if (user == null) throw const AuthFailure('You are not signed in.');
    final me = _map(user)!;
    if (me.usesPassword && password != null && user.email != null) {
      await user.reauthenticateWithCredential(
        EmailAuthProvider.credential(email: user.email!, password: password),
      );
    } else if (me.usesGoogle) {
      await user.reauthenticateWithCredential(await _googleCredential());
    } else {
      throw const AuthFailure('Enter your password to confirm.');
    }
    await beforeDelete?.call();
    await user.delete();
    await signOut();
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
    'account-exists-with-different-credential' =>
      'This email already has an account with a password. Sign in with your '
          'password instead.',
    'weak-password' => 'Choose a stronger password (at least 6 characters).',
    'too-many-requests' => 'Too many attempts. Try again later.',
    'network-request-failed' =>
      'No connection. Check your network; playback still works offline.',
    'requires-recent-login' => 'Please sign in again to confirm.',
    'user-mismatch' => 'Choose the same Google account you signed in with.',
    'operation-not-allowed' =>
      'This sign-in method is not enabled for this project.',
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
