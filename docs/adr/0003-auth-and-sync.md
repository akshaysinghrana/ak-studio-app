# ADR 0003 — Authentication and sync

- **Status:** Accepted (code and tests). The live backend is **not configured** yet; see "Enabling".
- **Date:** 2026-10-26

## Decision

- **Provider:** Firebase Authentication with email and password, plus Cloud Firestore for metadata.
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

1. Create a Firebase project and enable **Authentication → Email/Password**, plus a **Cloud Firestore** database.
2. Run `dart pub global activate flutterfire_cli`, then `flutterfire configure --platforms=android`. This overwrites `lib/firebase_options.dart`.
3. Deploy the rules: `firebase deploy --only firestore:rules`.
4. Never commit service-account keys. `firebase_options.dart` contains only client identifiers.

## Tests

- **`test/unit/sync/sync_service_test.dart`** covers two-device propagation by fingerprint, the privacy of the payload, consent, last-write-wins in both directions, deletion and resurrection, preservation of missing-file entries, favourites, settings, sign-out data retention, and error recording.
- **Still to do:** end-to-end tests against the Firebase emulator or a real project once one is configured.
