# ADR 0003 — Authentication and sync

- **Status:** Accepted (code and tests). The live backend is **not configured** yet; see "Enabling".
- **Date:** 2026-10-26

## Decision

- **Provider:** Firebase Authentication (email/password and Google), behind the app's own sign-in screens, plus Cloud Firestore for metadata. No Firebase UI package is used.
- **Google sign-in:** `google_sign_in` 7.2.0 (BSD-3) on Android Credential Manager. The flow is `authenticate()`, then the Google ID token, then `GoogleAuthProvider.credential`, then Firebase. Closing the picker is not reported as an error. Signing out also clears the Google account choice. To delete a Google account, the user confirms with Google again; there is no password prompt.
  - Package versions: `firebase_core` 5.1.0, `firebase_auth` 7.0.1, `cloud_firestore` 7.1.0, all BSD-3.
  - These need compileSdk 34 and minSdk 24, so they are compatible with the current toolchain.
- **Guest-first:** the whole app works signed out and offline.
- **When Firebase is not configured:** `lib/firebase_options.dart` is a stub that returns null. The app then uses `UnconfiguredAuthRepository`, and the Account screen says accounts are not set up. Sign-in is never faked.
- **Auth flows:**
  - sign in, create account, password reset, and sign out;
  - auth-state restore;
  - client-side validation, with friendly messages for provider error codes;
  - account deletion with password re-authentication. Cloud data is deleted after re-authentication and before the account is removed.

## What syncs (spec 9.2, 9.3)

| Record | Firestore path | Fields |
|---|---|---|
| Playlist the user attached to the account | `users/{uid}/playlists/{playlistId}` | `name`, `updatedAt` (ms), `deleted`, `entries` (fingerprints) |
| Favourite | `users/{uid}/favorites/{fingerprint}` | `favorite`, `updatedAt` |
| Sync-eligible preference (background video audio, theme) | `users/{uid}/settings/{key}` | `value`, `updatedAt` |

**Never uploaded:**
- media files, file names, paths, URIs, titles or thumbnails;
- listening or viewing history;
- playback progress.

Media is referenced only by a fingerprint: SHA-256 of kind, file name, size and rounded duration, truncated to 32 hex characters. It is computed on the device, and the same file matches across devices. A unit test checks that no names, titles or URIs reach the remote store.

## Consent and scoping

- After sign-in, if the device has guest playlists, the user is asked whether to add them to the account. Without consent they stay local (`user_id` null) and are never uploaded.
- Only playlists with `user_id = uid` sync. Playlists from another account on the same device are not uploaded to a different account.
- **Sign out** keeps local data by default. "Sign out and remove" deletes that account's playlists from the device. Media is never deleted.
- **Security rules** (`firestore.rules`):
  - only the owner may read or write `users/{uid}/**`, and everything else is denied;
  - field whitelists and size limits apply.

## Conflict strategy

- **Per-record last write wins** by millisecond `updatedAt`. A newer local change is never overwritten by an older remote copy (tested with two simulated devices).
- **Deletions** are recorded as local tombstones (`sync_tombstones`) and pushed as `deleted: true`. An edit made after a remote deletion wins and restores the playlist.
- **Files not on this device:** playlist entries for them stay in the account copy, so syncing from a phone with fewer files never removes them for others.
- **Clock skew:** devices' clocks are trusted. A device with a badly wrong clock can win or lose conflicts incorrectly. Acceptable for personal metadata; revisit with server timestamps if needed.

## Triggers and errors

- Sync runs on sign-in (after consent), on app start for a signed-in user with sync on, and on **Sync now**.
- Failures record `sync_metadata.last_error` and show "Your data on this device is unchanged". They never block playback.

## Enabling (needs the project owner)

1. Create a Firebase project. Enable **Authentication → Email/Password** and **Google**, and create a **Cloud Firestore** database.
2. Under Project settings → Android app `com.akshayrana.video_music_app`, add the SHA fingerprints of every signing key. Google sign-in fails with a configuration error without them. The debug key on the dev machine has these fingerprints:
   - SHA-1 `8E:C0:F5:6D:A0:DE:B9:7C:C8:33:A4:D7:BE:F6:CC:AE:19:1C:0C:81`
   - SHA-256 `BD:D2:50:EA:14:D0:E5:9D:03:12:A6:19:15:16:8F:11:27:67:38:62:AD:23:DB:D7:38:AF:97:C1:39:FD:94:7E`

   Add the release (upload) key's fingerprints too, and Play App Signing's when publishing. Get them with `keytool -list -v -keystore <file> -alias <alias>`.
3. Run `npm i -g firebase-tools`, `firebase login`, `dart pub global activate flutterfire_cli`, then `flutterfire configure --platforms=android`. This overwrites `lib/firebase_options.dart`.
4. Set the **Web client ID** (Authentication → Sign-in method → Google → Web SDK configuration) in `lib/google_sign_in_options.dart`, or pass `--dart-define=GOOGLE_WEB_CLIENT_ID=...`. It is a public identifier, not a secret.
5. Deploy the rules: `firebase deploy --only firestore:rules`.
6. Never commit service-account keys. `firebase_options.dart` and the client ID are client identifiers only.

## Tests

- **`test/unit/sync/sync_service_test.dart`** covers two-device propagation by fingerprint, the privacy of the payload, consent, last-write-wins in both directions, deletion and resurrection, preservation of missing-file entries, favourites, settings, sign-out data retention, and error recording.
- **Still to do:** end-to-end tests against the Firebase emulator or a real project once one is configured.
