# ADR 0002 — Local storage and media access

- **Status:** Accepted for Phase 2 (Android). iOS is out of scope until the iOS platform is added.
- **Date:** 2026-10-26

## Context

Spec 4.1 and 11 require:

- a local-first library of MP4 and MP3 files that works offline and for guests
- stable app IDs, separate from file locators
- graceful handling of missing, moved or deleted files
- least-privilege permissions
- no loading of whole files or the whole library into memory to list it
- database migrations

## Decisions

### Database: Drift on SQLite

- `drift` 2.35.3 + `drift_flutter` 0.3.1 (MIT). The database runs on a background isolate. `drift_flutter` bundles SQLite through the `sqlite3` package; `sqlite3_flutter_libs` is end-of-life and not used.
- Schema v1 tables:
  - `media_items`
  - `playback_progress`
  - `user_preferences`
- Queue and playlist tables arrive in Phase 4 as schema v2, using a tested migration.
- Each schema version is exported to `drift_schemas/` (`dart run drift_dev make-migrations`) so migrations can be verified in tests.
- Positions and durations are stored as integer milliseconds.

### Identity and locators

- `media_items.id` is an app-generated stable ID. `locator` holds the durable URI and is unique.
- MediaStore items use `content://media/external/{video|audio}/media/<id>`. A rescan matches by locator, so playback progress, favourites and future playlist entries survive metadata changes.
- Imported documents (system picker) use their SAF `content://` URI. The app calls `takePersistableUriPermission`, so access survives restarts. Files are **not** copied into app storage, which retires `file_picker` (it copied picked files into the cache).
- A file that is no longer reported by a full scan is marked `available = false`, not deleted, so history is kept. The UI offers Rescan or Remove.

### Discovery: native MediaStore adapter (no plugin)

- `MediaStoreScanner.kt` runs paged queries (500 rows) for `video/mp4` and `audio/mpeg` on a background executor.
- Without an album tag, MediaStore reports the **folder name** as the album (seen on device). The scanner drops an album equal to the containing folder's name, so no metadata is invented.
- Dates are stored as ISO-8601 text (`store_date_time_values_as_text`). Integer storage keeps whole seconds only, which made "last played" ordering tie for plays within the same second (caught by a unit test).
- Columns read:
  - all files: title, display name, MIME type, size, dates, duration, relative path (folder)
  - video: width, height
  - audio: artist, album. MediaStore's `<unknown>` is mapped to null, so no metadata is invented.
- Thumbnails come from `ContentResolver.loadThumbnail` (API 29+), with a `MediaMetadataRetriever` fallback, and are cached as small JPEGs.
- `photo_manager` was considered (Apache-2.0, maintained). It was rejected because it is photo-centric, does not expose artist or album for audio, and adds a second abstraction over MediaStore.

### Permissions: `permission_handler` 12.0.3 (MIT), requested just-in-time

- Pinned to 12.x on purpose. `permission_handler` 13.x pulls in `permission_handler_android` 14.1, which requires compileSdk 37. The project's AGP 9.1 supports at most 36, and per `CLAUDE.md` the toolchain is not upgraded for one plugin. Revisit when AGP is upgraded for another reason.

- Permissions are requested only when the user taps **Scan library**. Importing through the system picker needs no permission.
- Android 13+ uses `READ_MEDIA_VIDEO` and `READ_MEDIA_AUDIO`. Android 12L and below uses `READ_EXTERNAL_STORAGE`.
- Android 14 partial video access (`READ_MEDIA_VISUAL_USER_SELECTED`) is handled as "limited": only the selected videos are indexed, and the UI says so.
- A permanently denied permission shows an explanation and an "Open settings" action. Denial never blocks import or playback of already-indexed or imported files.

### Preferences

- Stored in the `user_preferences` table, each with a `sync_eligible` flag for Phase 6.
- Initial keys:
  - `playback.continueVideoAudioInBackground` (default false)
  - `appearance.themeMode` (default dark)

## Consequences

- One native channel owns all MediaStore access. Dart owns identity, reconciliation and persistence.
- A scan with up to tens of thousands of rows is streamed in pages and written in one transaction per page. List screens query only the rows and columns they render and use lazy builders.
- iOS needs its own adapter (Photos and Files picker) behind the same Dart interface when the iOS platform is added.

## Changes (2026-10-28)

- **Missing files are hidden** from library views (Videos, Music, folders, Home, counts). Their rows stay in the database with `available = false`, so history and playlists survive and items return automatically if the file reappears. Playlists still list missing entries as unavailable so they can be removed.
- **Automatic refresh:** a MediaStore `ContentObserver` (debounced 1.5 s), app resume and app start trigger a silent rescan with the permissions already granted. A permission prompt is never shown for this. Files deleted by other apps disappear without a manual scan.
- **Delete:**
  - **Move to trash** uses `MediaStore.createTrashRequest` (Android 11+); the file is restorable from the Files app for about 30 days.
  - **Delete permanently** uses `createDeleteRequest`, or a `RecoverableSecurityException` flow on Android 10.
  - Imported documents are deleted with `DocumentsContract.deleteDocument`.
  - Android always shows its own confirmation. The library and queue update only after the user allows it.
  - Folder delete removes that folder's videos or songs, not other files.
- **Sorting:**
  - folders by name, most items, size or recently added;
  - files by name, date added, date modified, last played, duration or size.

  Sort choices are remembered per tab.
- **MP3 cover art:** the embedded ID3 picture is read first. Without one, a generated gradient artwork is shown, which is clearly generic, not a fabricated cover.
