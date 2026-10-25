# Phase 1 — physical device results

- **Device:** Motorola Edge 50 Pro (`eqe`), Android 16 (API 36), secure lock screen with biometrics.
- **Build:** debug, `video_player_android` 2.12.2 (Media3 1.9.2), `audio_service` 0.18.19 with the local patch in `third_party/audio_service/UMP_PATCH.md`.
- **Date:** 2026-10-26
- **Media:** synthetic files from `scripts/gen_test_media.sh`, pushed to the app's own storage. No personal media was used. Every video frame encodes its own second, so screenshots can be checked automatically.

## How it was run

| Suite | Command | What it drives |
|---|---|---|
| Engine (on device) | `scripts/run_device_engine_tests.sh <id> engine_test.dart` | Real coordinator + ExoPlayer: seeks, frame capture, MP3, errors, queue, background policy |
| Zoom (on device) | `scripts/run_device_engine_tests.sh <id> zoom_test.dart` | Synthesized pinch/pan/double-tap on the real video texture |
| OS lifecycle (host) | `python3 -I scripts/device_lifecycle_checks.py <id> [checks]` | Real lock, Home, media keys, notification shade, lock-screen card, PiP, battery saver, task removal, measured with `dumpsys media_session` / `dumpsys audio` / screenshots |

## Results

"Players" = started `AudioPlaybackConfiguration`s owned by the app's uid (`dumpsys audio`). **1** means exactly one audible engine.

| # | Check | Result | Evidence |
|---|---|---|---|
| 1 | MP4 plays | PASS | Engine suite, 4/4 runs |
| 2 | ±10 s exact, clamped at 0 and at the end | PASS | Positions 30→40→20 s, 4→0 s, 115→120 s, within 300 ms. Lock-screen keys: 93.4→104.3 s, 104.4→95.0 s |
| 3 | Clip shorter than 10 s clamps both ways | PASS | Engine suite |
| 4 | Zoom / pan / reset | PASS | Double-tap 2× and reset on the real texture: mean row diff 52.3 zoomed vs 0.0 after reset, position unchanged while paused. `zoom_test` on device covered pinch out (above 1.5×), clamp at 4.0×, pinch in clamped at 1.0×, hard pans in 4 directions still covering the viewport, Reset, and double-tap 2× and back with no seek |
| 5 | Frame capture | PASS | 1280×720 PNG (source resolution, not screen size) in `Pictures/Media Player Screenshots`. The encoded second matched the player position (47.53 s → 17 mod 30; 58.71 s → 28). Engine suite: 7 positions on landscape and portrait files |
| 6 | Setting off + lock → pause, stays paused | PASS | PLAYING → PAUSED, keyguard=True, players=0. Still PAUSED at the same position after wake |
| 7 | Setting off + Home → pause | PASS | No auto-resume on return |
| 8 | Setting on + lock 90 s → MP4 audio continues | PASS (4 runs) | Advanced 90.2 s over 90.2 s with keyguard=True, players=1 |
| 9 | System media keys while locked | PASS | Pause, play, +10, −10, next (MP4→MP3), previous (MP3→MP4), players=1 |
| 9b | Notification shade media controls | PASS | Play, Pause and Next changed real playback. Coordinates fallback was used; see notes |
| 9c | Lock-screen media card | PASS for pause, play, next | Taps on the real card with keyguard=True. Pause and play passed in 2/2 runs; next passed when allowed 2.5 s to load. Previous restarted the current item because it came about 3 s after next (spec 7.1 restart rule). With a shorter 1.2 s wait, next had not loaded yet, so a sub-3 s previous cannot be timed reliably through the UI. The go-back path is covered by #9 (media keys) and the engine suite |
| 10 | Unlock after background MP4 audio → picture in sync, one stream | PASS | Secure lock for 90 s+, then unlocked by a person. PLAYING; session 38.3–38.8 s; on-screen frame decoded to second 38 (8 mod 30); players=1 |
| 10b | Home 20 s with the setting on → reopen | PASS | Background PLAYING with players=1. After reopen, session 25.3–25.7 s and on-screen frame second 25; players=1 |
| 11 | Setting on → background keeps playing; turned off → background pauses | PASS | |
| 12 | MP3 (setting off) locked 150 s | PASS | Advanced 150.2 s over 150.1 s, players=1 |
| 13 | Audio focus taken by another app | PASS | Files by Google preview played: we went to PAUSED and stayed PAUSED after it stopped |
| 14 | Headphones unplugged / Bluetooth disconnect | NOT RUN | Needs physical headphones. The coordinator pauses on `becomingNoisyEventStream` |
| 15 | Headset hook / play-pause key | PASS | PLAYING → PAUSED → PLAYING → PAUSED |
| — | Explicit PLAY/PAUSE keys (Bluetooth AVRCP, cars) are idempotent | PASS **after patch** | Before the patch, PAUSE while paused **started playback**. See the bugs section |
| 16 | Corrupt file → error | PASS | ExoPlayer source error surfaced as an error state with a message |
| 17 | Queue advance and 3 s previous rule | PASS | Engine suite |
| 18 | Battery saver + setting on + lock 60 s | PASS | Advanced 60.2 s over 60.1 s. Battery saver restored to its original value |
| 19 | Task removed from recents | PASS | Session gone, players=0, notification removed |
| — | Picture-in-picture | PASS | Window pinned, still PLAYING with players=1, expanded back to the full UI |

## Bugs found on the device and fixed

1. **Session stuck in "loading" after a queue advance.** Change detection carried the previous engine's `isPlaying` over, so the new item's PLAYING state was never broadcast. Audio played, but the lock screen and notification showed loading. Fixed in `PlaybackCoordinator._loadCurrent`. The engine suite now asserts the session reaches ready+playing.
2. **Explicit PLAY/PAUSE media keys toggled playback** (upstream `audio_service` behaviour). A Bluetooth or car PAUSE while paused started audio, which violates spec 4.2. Fixed with a 3-line patch in a vendored `audio_service` (`third_party/audio_service/UMP_PATCH.md`).

## Notes and limitations

- **Secure lock:** this phone's keyguard becomes secure some time after screen-off; it was engaged at 90 s and not at 4 s. adb cannot dismiss it, so a secure unlock always needs a person.
- **Accessibility snapshots:** `uiautomator dump` fails while media plays (the seek bar's semantics never go idle) and can return a stale `checked` value. The script pauses for dumps and reads the setting's true value from the app's debug log.
- **Notification shade:** another app's live countdown notification kept SystemUI from ever being idle. The shade buttons were tapped at coordinates measured from a screenshot (`UMP_SHADE_BUTTONS`, `UMP_LOCKSCREEN_BUTTONS`). Those coordinates are specific to this device.
- **Stale media-button receiver after reinstall:** right after the app is reinstalled, Android routes media keys to the previous install's cancelled `PendingIntent`, and our new session stays inactive until it plays once. Keys then do nothing until playback starts in the app. Related real-world gap: if the process was killed, a headset Play cannot resume because the queue is not yet restored after process death (Phase 4).
- **Screen-off check (10a):** with this phone's lock settings the secure keyguard engaged within 6 s of screen-off in a later run, so 10a cannot run unattended. 10 (real lock) and 10b (Home) cover it.
- **One unexplained timeout:** the first engine-suite run once timed out waiting for autoplay while the app was still launching. It did not reproduce in 3 later runs.
