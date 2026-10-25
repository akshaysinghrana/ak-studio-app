// Placeholder: this build has no Firebase project configured.
//
// To enable accounts and sync, create a Firebase project and run
//   dart pub global activate flutterfire_cli
//   flutterfire configure --platforms=android
// which overwrites this file with the project's real options
// (see docs/adr/0003-auth-and-sync.md). Never commit service-account keys.
import 'package:firebase_core/firebase_core.dart';

// ignore: avoid_classes_with_only_static_members
class DefaultFirebaseOptions {
  /// Null means "not configured": the app runs in guest mode only and the
  /// account screen says so instead of pretending sign-in works.
  static FirebaseOptions? get currentPlatform => null;
}
