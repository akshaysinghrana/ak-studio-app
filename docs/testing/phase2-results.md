# Phase 2 — app shell, local persistence and library: results

- **Device:** Motorola Edge 50 Pro, Android 16
- **Date:** 2026-10-26

## Automated

| Suite | Result |
|---|---|
| `flutter analyze` | No issues |
| Unit + schema tests (`test/unit`, `test/drift`) | 39 passed. Covers scan reconciliation, stable IDs across rescans, missing → unavailable → restored, per-kind scans, paging, import and grants, `verifyAvailability`, remove + cascade, LIKE escaping, sort orders, continue list, progress store, preferences, scan permission flows (granted / limited / denied / permanently denied), schema v1 export |
| Widget tests (`test/widget`) | 3 passed: empty state, metadata and unavailable labels, music artist/search |
| `integration_test/library_test.dart` on device | 4 passed against the **real MediaStore**: permissions, scan metadata (duration, size, 1280×720, `Movies/UMP_Test/`, ID3 title and artist, album null), idempotent rescan, thumbnails, `content://` playback, frame capture, DB progress save and resume (~45 s) |
| `engine_test` + `zoom_test` on device (Phase 2 code) | 8 + 1 passed |
| First-launch UI on device | Home empty state with Scan library / Choose files, bottom navigation, no permission prompt at launch |

## Found and fixed

1. MediaStore reports the folder name as the album for untagged MP3s, so the scanner now drops it.
2. Second-precision dates broke "last played" ordering, so dates are now stored as ISO-8601 text.
3. `permission_handler` 13 needs compileSdk 37, so it is pinned to 12.0.3 (ADR 0002).

## Not yet covered

- Granting or denying the runtime permission through the real system dialog (tests grant with `pm grant`). The dialog flow and Android 14 "selected videos only" need a person at the device.
- Persisted grants of imported documents across a device reboot.
