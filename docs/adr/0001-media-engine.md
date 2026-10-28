# ADR 0001 — Media engine

- **Status:** Accepted for Android on 2026-10-26, based on physical-device evidence (see below). Only the headphone-unplug check is still open; it needs hardware. iOS has not been evaluated yet.
- **Date:** 2026-10-25
- **Scope:** Android first. iOS will be evaluated in its own spike before any iOS release.

## Context

The spec (sections 5, 8 and 10.3) requires these to work together:

- local MP4 and MP3 playback
- exact ±10 s seeking
- pinch zoom and pan on the real video surface
- capture of the actual decoded frame
- MP4 audio that continues on lock or in the background only when the user turns the setting on
- MP3 that always continues in the background
- one coordinator that owns all playback, so two engines are never audible at the same time

Toolchain checked on 2026-10-25: Flutter 3.47.8, Dart 3.13.7, AGP 9.1.0, Gradle 9.3.1, Kotlin 2.4.0, compileSdk/targetSdk 36, minSdk 24.

## Options considered

| Option | Background video audio | Frame capture | Zoom | Maintenance (pub.dev, 2026-10-25) | License / size |
|---|---|---|---|---|---|
| **A1. `video_player` (ExoPlayer/Media3) for MP4 *and* MP3 + `audio_service` + `audio_session`** | The same ExoPlayer keeps running. No handoff is needed (see the source findings below). | Native bridge using `MediaMetadataRetriever.getFrameAtTime(OPTION_CLOSEST)` | Texture view, so Flutter `InteractiveViewer` transforms apply | video_player 2.14.1 (2026-10-02), audio_service 0.18.19 (2026-06-29) | BSD-3 / MIT. Small, because it uses the platform decoder. |
| A2. `video_player` for MP4 + `just_audio` for MP3 | Same as A1 for video | Same as A1 | Same as A1 | just_audio 0.10.6 (2026-06-29) | MIT. Two engines means more coordinator states. |
| A3. `media_kit` (libmpv) for both | Single engine | Built-in `screenshot()` | Texture | media_kit 1.2.6 (**2025-12-13**), media_kit_libs_video 1.0.7 (2025-10-05): no release for about 10 months, which predates Flutter 3.47 / AGP 9 | Bundles libmpv and FFmpeg (LGPL obligations). Adds roughly 20–30 MB per ABI. |
| B. Native Media3 `MediaSessionService` bridge | Native | Native | Needs a platform view or texture integration | n/a (our own code) | Most build and maintenance cost |

## Decision

Adopt **A1** for the Phase 1 proof of concept:

- `PlaybackCoordinator` (`lib/features/playback/application/playback_coordinator.dart`) extends `audio_service`'s `BaseAudioHandler`. It is the only owner of the queue, the engine instance, play intent and background state. The UI, notification, lock screen and headset buttons all call into it.
- It runs one `VideoPlayerController` at a time, with `allowBackgroundPlayback: true`, for both MP4 and MP3. The previous controller is disposed *before* the next one is created, and a load-generation counter drops stale loads when the user taps quickly. Because of this, two engines can never be audible together, and no video-to-audio handoff exists.
- The background rule is a pure function (`domain/background_policy.dart`) that the coordinator applies on `AppLifecycleState.hidden/paused`:
  - audio keeps playing
  - video keeps playing only when the setting is on; otherwise it pauses and saves position
  - returning to the foreground never auto-resumes
- Frame capture is a Kotlin `MethodChannel` (`FrameCapture.kt`) that decodes the frame at the current position from the source file at full resolution. The frame is saved with `gal` into the album "AS Media Screenshots", and `share_plus` is the fallback when saving is denied.
- Zoom uses `InteractiveViewer` (1×–4×, zero boundary margin) over the texture-backed `VideoPlayer`. Double-tap toggles 2× or resets, and an explicit "Reset zoom" button is always shown. Zoom resets on each new queue entry.

### Source findings that support A1 (video_player_android 2.12.2)

- `VideoPlayer.setAudioAttributes` creates ExoPlayer with `handleAudioFocus = !mixWithOthers`. ExoPlayer therefore pauses on calls or other players and does not resume after a pause the user made. Headphone unplug ("becoming noisy") is *not* handled by the plugin, so the coordinator pauses on `audio_session.becomingNoisyEventStream`.
- `TextureVideoPlayer.onSurfaceCleanup()` only detaches the surface (`setVideoSurface(null)`) when Android destroys the surface on background or lock. It does not pause, so audio continues. `onSurfaceAvailable()` reattaches the surface on return. The same ExoPlayer drives both picture and sound, so A/V stays in sync by construction.
- The Dart `VideoPlayerController` pauses on `AppLifecycleState.paused` only when `allowBackgroundPlayback` is false. We set it to true and let the coordinator decide instead.

### Why not the others (for now)

- **A2:** `just_audio` adds gapless playback and an Android equalizer, but those are P1 features. Two engines would also double the coordinator states. Revisit when P1 audio features start; a swap would stay behind the coordinator.
- **A3:** about 10 months with no release on a toolchain that has moved twice, plus LGPL/FFmpeg packaging and app size. Keep it as the fallback if Phase 7 needs subtitle or track control, or codec coverage, beyond what ExoPlayer offers through `video_player`.
- **B:** only if A1 fails the device tests (for example, if the OS kills the Dart isolate while background audio is playing).

## Known risks / open questions

1. `MediaMetadataRetriever` decodes independently of the live player. On some devices or files, `OPTION_CLOSEST` may be slow or may return a frame that differs slightly from the one on screen. Must be checked on a device, including portrait, 4K and HDR files.
2. `video_player` exposes no audio or subtitle track API. That is P1 work and may push us to A3 or B for Phase 7.
3. `androidStopForegroundOnPause: false` keeps the notification non-dismissible while paused. It avoids Android 12+ `ForegroundServiceStartNotAllowedException` when the user resumes from the lock screen. Lock-screen resume worked on the device with this setting.
4. `file_picker` copies picked files into the app cache, which is costly for large videos. Phase 2 replaces it with MediaStore `content://` URIs and SAF documents with persistable permissions (ADR 0002).
5. Fat release APK is 50.8 MB. Distribute as an App Bundle (`flutter build appbundle`), which Play splits per device.
6. Upstream `audio_service` routes explicit `KEYCODE_MEDIA_PLAY`/`PAUSE` keys to a toggle. A Bluetooth or car PAUSE while paused started playback on the device. Patched locally (`third_party/audio_service/UMP_PATCH.md`); re-check on every upgrade.

## Evidence

Full results: `docs/testing/phase1-device-results.md`. The device was a Motorola Edge 50 Pro on Android 16.

| Check (spec 8.4) | Result |
|---|---|
| 1. MP4 plays with audio | PASS |
| 2. Lock: audio continues only when the setting is enabled | PASS. Setting off: paused, 0 players. Setting on: 90.2 s of audio over 90.2 s with a secure keyguard, 1 player (3 runs) |
| 3. Pause, seek, next and previous from system media controls | PASS: media keys, notification shade, and lock-screen card (pause/play/next) |
| 4. Unlock: video and audio in sync, audio not doubled | PASS: after a real secure unlock, the on-screen frame matches the session second and there is 1 player. The same holds after Home → reopen |
| 5. Setting off: defined pause behaviour | PASS: lock and Home both pause, with no auto-resume |
| 6. MP3 stable while locked | PASS: 150.2 s over 150.1 s |
| Frame capture is the real decoded frame | PASS: source resolution; the encoded second matches the player position |
| Zoom on the real texture | PASS: pinch, 1×–4× clamps, pan bounds, reset, double-tap (on-device `zoom_test`) |
| `flutter analyze`, unit tests, debug/release builds | PASS |
| Physical iPhone | **Not run.** The iOS platform has not been created yet |

## Phase 5 additions (2026-10-26)

- **Queue restore:** after a process restart the queue is restored from the database, paused at the saved position. It never auto-plays (spec 7.1, 12). `play()` from a headset or the notification on a restored but not-yet-loaded queue loads and plays the current item.
- **Repeat and shuffle** are exposed to the system media session (`setRepeatMode` / `setShuffleMode`) and broadcast in `PlaybackState`.
- **Notification metadata:** artist and album come from tags only, and artwork from MediaStore thumbnails. Tapping the notification opens Now Playing.
- **Single engine:** there is still one audible engine and no handoff code path, so the spec 8.3 handoff requirements do not apply.

## Phase 7 parity features (2026-10-26)

| Feature | Implementation | Notes |
|---|---|---|
| Playback speed 0.5×–2× | `VideoPlayerController.setPlaybackSpeed`, also via the media session `setSpeed` | Speed carries over to the next items |
| Sleep timer | Coordinator timer, or stop at the end of the current item instead of advancing | |
| External subtitles (SRT, WebVTT) | SAF picker, then a native text read (2 MB cap), then `SubRipCaptionFile` / `WebVTTCaptionFile` | Size setting and delay in ±0.25 s steps (`setCaptionOffset`). Kept per item for the session |
| Embedded audio tracks | `getAudioTracks` / `selectAudioTrack` | The menu entry appears only when the engine reports 2 or more tracks |
| Embedded subtitle tracks | **Not offered** | `video_player` 2.14 exposes no text-track API. Fallback options are in "Why not the others" |
| Brightness and volume gestures | Window brightness override (restored when the player closes) and `AudioManager` music stream | **Off by default.** Active only at 1× zoom and with controls unlocked, so pinch and pan are unaffected |
| Rotation lock | `SystemChrome.setPreferredOrientations` | |
| Equalizer | **Not offered** | The engine does not expose its audio session ID, so a real `android.media.audiofx.Equalizer` cannot be attached. Per the spec, no control is shown |

## Background reliability fixes (2026-10-28)

Reported on the Motorola: background audio stopped after about 5 minutes, sooner on later attempts, and lock-screen controls went missing.

- **Stock Android is fine.** On the API 37 emulator, after 8 minutes of forced Doze with the battery unplugged, the foreground service stayed alive, the ExoPlayer and AudioService wake locks were held, and the audio track was still "started".
- **Video in background releases its decoder.** Background video audio used to keep the hardware video decoder running with no surface. Android can reclaim decoders from background apps, which stops playback. `third_party/video_player_android` (see UMP_PATCH.md) adds an audio-only switch. The coordinator enables it while a video's audio plays in the background and disables it on return. Verified on the emulator:
  - background: 0 video decoders, audio playing;
  - foreground again: decoder restored and picture in sync.
- **Battery setting in Settings → Background playback.** OEM battery optimisation can still stop background media apps. This item shows whether the app's battery use is unrestricted and opens the system page to change it.
- **Media-session artwork:** cover art when present, otherwise the AS Media logo.
- **Controls overlay:** the scrim no longer absorbs touches, so double-tap seeking works while the controls are visible.
