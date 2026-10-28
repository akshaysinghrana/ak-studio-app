// Google sign-in configuration (not a secret: OAuth client IDs are public).
//
// Android needs the Firebase project's *Web client ID* to obtain the ID token
// that Firebase Auth verifies. It is taken from, in order:
//   1. --dart-define=GOOGLE_WEB_CLIENT_ID=<id>.apps.googleusercontent.com
//   2. [kGoogleWebClientId] below
//   3. the `default_web_client_id` string generated from google-services.json
//      (added by `flutterfire configure`)
// See docs/adr/0003-auth-and-sync.md → "Enabling".

/// Paste the Web client ID here (Firebase console → Authentication → Sign-in
/// method → Google → Web SDK configuration), or leave null to use the
/// dart-define / google-services.json.
const String? kGoogleWebClientId = null;

String? get googleWebClientId {
  const fromDefine = String.fromEnvironment('GOOGLE_WEB_CLIENT_ID');
  return fromDefine.isNotEmpty ? fromDefine : kGoogleWebClientId;
}
