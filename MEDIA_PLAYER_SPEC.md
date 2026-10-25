---
title: "Unified Media Player"
subtitle: "Product Requirements & Engineering Build Specification"
author: "Claude Code implementation brief"
date: "25 October 2026"
lang: en
---

**Document purpose:** This is the source of truth for building a Flutter mobile application that plays local MP4 videos and MP3 audio, with advanced player controls, background audio, queues, playlists, and user accounts. Keep this file in the repository root and read it before changing code.

**Working title:** Unified Media Player. The final brand name, logo, and colors can be changed later without changing the architecture.

**Product defaults used in this specification:** Android and iOS are the target platforms; playback is local-first and works offline; MP4 and MP3 are the required formats; signing in is available for account sync, but local playback must also work in guest mode; media files stay on the user's device and are not uploaded to the account backend.

# Contents

1. Product summary and goals  
2. Scope and release priorities  
3. User journeys and navigation  
4. Functional requirements  
5. Video-player requirements  
6. Music-player requirements  
7. Queue and playlist behavior  
8. Background playback and lock-screen behavior  
9. Account, cloud sync, and privacy  
10. Architecture and technology choices  
11. Data model and persistence  
12. UX, accessibility, and quality requirements  
13. Suggested project structure  
14. Phased implementation plan  
15. Acceptance criteria and test matrix  
16. Risks, constraints, and engineering decisions  
17. Claude Code working rules and first prompt  
18. Reference documentation

# 1. Product summary and goals

Build a polished Flutter media-player app combining a local video player similar in capability to a modern Android video player and a local music player. Do not copy another application's branding, artwork, or exact interface. Aim for familiar, reliable media-player behavior with an original, consistent interface.

## Primary goals

- Find and play local MP4 videos and MP3 files from the device, and let users import individual files through the operating system's file picker.
- Provide consistent 10-second rewind and 10-second forward controls for video and audio.
- Support pinch-to-zoom and pan for video, with sensible fit/fill/crop options.
- Capture the current decoded video frame as an image, save it to the device's photo/gallery area, and share it.
- Support media controls from the lock screen, Android notification, iOS Control Center, headset buttons, and Bluetooth controls where the platform supports them.
- Let users choose whether video audio continues after the app is backgrounded or the phone is locked.
- Provide a live editable Now Playing queue, create/edit playlists, and keep playback from restarting when upcoming queue items are modified.
- Provide account registration, sign-in, sign-out, password recovery, and optional cloud sync for playlists/settings/history.
- Persist playback position and user preferences, recover gracefully after process termination, and remain useful offline.

## Out of scope for the first working release

Video streaming subscriptions, DRM, user-uploaded media hosting, public/social profiles, public playlist sharing, collaborative queues across multiple users, advertisements, paid subscriptions, Chromecast/AirPlay casting, and desktop/web versions are not required for the first release. The architecture should avoid blocking these future additions, but do not implement them before the core player is dependable.

## Definition of success

A user can open the app, grant appropriate media access or select files, play MP4/MP3 files, skip exactly 10 seconds, zoom a video, take a frame screenshot, queue/reorder the next items while playback continues, save a playlist, lock the phone and retain audio when the relevant setting is enabled, and sign in to sync supported metadata. All core functions must work without network access except authentication and cloud sync.

# 2. Scope and release priorities

Use the following priorities to avoid building an untestable collection of features all at once.

| Priority | Meaning | Scope |
|---|---|---|
| P0 - Core release | Required for first usable release | MP4/MP3 local playback, media library/import, 10-second seek, video zoom, current-frame screenshot, queue, playlists, persistent settings/history, background audio behavior, account flow, essential lock-screen controls, tests |
| P1 - Player parity | Add after P0 is stable | External subtitles, embedded audio/subtitle track selection where supported, playback speed, sleep timer, equalizer where supported, orientation/rotation, brightness/volume gestures, picture-in-picture, advanced sorting/folders, richer metadata |
| P2 - Future enhancements | Separate planning decision | Additional formats beyond MP4/MP3, casting, lyrics/waveforms, network streams, downloads, multi-device collaborative queue, social sharing, car integrations |

“MX Player features” and “music-app features” are interpreted as a broad feature set, not a promise to reproduce every feature of a named app. Implement in priority order, document any platform-specific gaps, and never show a control that does not work.

# 3. User journeys and navigation

## Main navigation

Use a Material 3 interface with a persistent bottom navigation bar on phone-sized screens. Recommended destinations:

1. **Home / Library** - Recently played, continue watching/listening, recently added, favorites, and shortcuts into media categories.
2. **Videos** - Scanned/imported video library with grid/list toggle, folder grouping, sorting, search, and duration/thumbnail metadata.
3. **Music** - Audio library with songs, artists, albums, folders, recently played, and favorites. If reliable metadata is unavailable, do not invent artist/album values.
4. **Playlists** - User-created playlists, saved queues, and playlist editing.
5. **Profile / Settings** - Account state, sync status, playback preferences, permissions, appearance, and app information.

A compact mini-player remains visible above bottom navigation whenever a media item is active. Tapping it opens the full Now Playing screen. Video items open the video player; audio items open the music player. A queue panel/sheet is accessible from both players.

## Key user journeys

- **First launch:** brief welcome -> explain local-media access -> request only the permissions needed for the user's chosen action -> show library or an empty state with “Scan library” and “Choose files” actions. Permit guest use.
- **Play a file:** select media -> show loading state -> start playback -> expose controls -> persist progress periodically and on pause/background/exit.
- **Queue next item:** use “Play next” or “Add to queue” -> queue updates immediately -> current item continues uninterrupted -> next item starts on completion or skip.
- **Capture a video frame:** open video controls -> tap screenshot -> capture the decoded video frame without player controls -> save to gallery/photos -> show success/failure and optional Share action.
- **Use account sync:** create account/sign in -> validate credentials -> sync supported app data -> show last-sync/error status -> keep local playback functional if the network is unavailable.

# 4. Functional requirements

## 4.1 Local media library and import (P0)

- Support scanning device media for MP4 videos and MP3 audio, and refreshing the library without blocking the UI.
- Support single/multiple file import using the system picker. Also allow the user to open a chosen file directly in the relevant player.
- Use platform-appropriate media APIs and permissions. On modern Android, request the granular video/audio media permissions that are actually required; do not request broad “manage all files” access as a shortcut. For files selected through a document picker, retain valid access where the operating system supports it.
- On iOS, respect Photos/files picker permission boundaries and provide a useful manual-import flow. Do not imply that the app can silently scan every location on iOS.
- Index title, URI/path or durable locator, MIME/container, duration, size when available, media type, thumbnail/cover if available, last modified, date added, and last played position/time.
- Provide search by title/file name and sorting by name, duration, date added, date modified, last played, and size where available.
- Handle missing, moved, inaccessible, renamed, or deleted files gracefully. Mark the item unavailable and offer rescan/remove; never crash the entire library.
- Do not read full media files into memory just to list them. Use thumbnails and paginated/lazy lists. Large library scans must run off the UI thread where appropriate.
- A file path or URI is a locator, not a guaranteed permanent identifier. Store a stable app media ID and refresh metadata/locator when scanning.

## 4.2 Shared player controls (P0)

- Play, pause, previous, next, seek bar, elapsed time, total duration, playback state, buffering/loading indicator, and a clear error state.
- Rewind 10 seconds and forward 10 seconds using explicit controls. Optional double-tap left/right zones can mirror the same action. Display temporary “-10s”/“+10s” feedback after a seek.
- Clamp seeks to valid boundaries: never seek before 0 or beyond duration. Tests must verify short files and end-of-file behavior.
- Support configurable playback speed in P1 (at minimum 0.5x, 0.75x, 1x, 1.25x, 1.5x, 2x where supported). The default is 1x.
- Show clear disabled/loading controls when the engine cannot perform an action. Prevent race conditions from repeated taps during initialization or media changes.
- On audio focus loss/interruption (phone call, navigation prompt, another player taking focus), apply platform conventions and resume only when appropriate; do not force playback back on after a user-initiated pause.
- Offer repeat-off, repeat-one, repeat-all and shuffle where appropriate. Queue state must be shared across player UI and background media controls.
- Persist the current media, position, volume/mute state if applicable, repeat/shuffle, and queue. Throttle progress writes; do not write on every animation frame.

## 4.3 Video player (P0/P1)

P0 requirements are detailed in Section 5. The first release must handle common MP4 files and the app's defined supported codec profile. On unsupported/corrupt media, show an actionable error rather than a spinner forever.

P1 should add subtitles and track controls as supported by the selected playback engine: external subtitle loading (at least SRT/VTT if technically supported), subtitle enable/disable, subtitle size/style, selection of embedded audio/subtitle tracks, and subtitle delay if available. Do not claim a subtitle format or codec works until verified on physical devices.

## 4.4 Music player (P0/P1)

P0 requirements are detailed in Section 6. Music playback must continue while the screen is off by default, unless the user pauses, the queue ends, an interruption requires pause, or the operating system stops playback for a legitimate reason.

P1 may add Android equalizer presets, bass/treble controls when supported, a waveform/progress visualization, lyrics display, and more metadata views. Do not present platform-specific equalizer controls as universally available on iOS.

## 4.5 Queue and playlists (P0)

Detailed rules are in Section 7. Live queue edits must not reload or restart the currently playing item unless the user explicitly selects another item or the current item changes naturally.

## 4.6 Account and settings (P0)

- Provide create account, sign in, sign out, forgot password, password reset, loading/error states, and a profile/settings screen.
- Implement real authentication through a configured provider; never fake success or hard-code credentials. Email/password auth is the default. Social sign-in can follow once the provider is configured.
- Guest mode must allow local library, playback, queues, playlists, and settings. Prompt the user to sign in only when they choose sync/account-only features or from Profile.
- Add a clear setting for video background audio, plus settings for seek step (10 seconds default), theme, scan behavior, and playback options.

# 5. Video-player requirements

## 5.1 Main controls

- Play/pause, seek bar with position/duration, rewind 10 seconds, forward 10 seconds, next/previous queue item, playback speed (P1), lock controls overlay (prevent accidental touches), and fullscreen/exit fullscreen.
- Tap video surface to show/hide controls. Controls auto-hide after a configurable short interval while playback is active; they stay visible while paused or while the user is interacting with them.
- Support portrait and landscape presentation, system orientation restoration after fullscreen, and an explicit fit mode menu.
- Fit modes: contain/fit (show full frame), cover/crop (fill surface), and stretch only if it is offered as an explicit option. Preserve aspect ratio by default.

## 5.2 Zoom and pan (P0)

- Pinch with two fingers to zoom in/out; drag to pan while zoomed; double-tap to toggle a useful zoom level or reset; provide a visible reset-zoom action.
- Define minimum and maximum zoom (starting proposal: 1.0x to 4.0x) and prevent panning so far that the entire video moves permanently off-screen.
- Zoom and pan must not accidentally trigger the 10-second double-tap seek gestures. Implement gesture arbitration deliberately and test it.
- Reset zoom on a new media item; do not reset it on every progress update. Behavior on rotation should preserve a reasonable framing where possible.
- Ensure transforms apply to the actual video surface and work with the selected native texture/platform view. If Flutter gesture transforms fail for a particular engine/view type, use an appropriate native/view integration rather than shipping nonfunctional zoom controls.

## 5.3 Screenshot / capture current frame (P0)

- Capture the actual decoded frame at the current playback position, at the best practical source resolution. Do not capture the controls, seek bar, black overlay, or Flutter UI as part of the saved frame.
- Save to a named app album/folder where the platform allows it (for example, “Media Player Screenshots”), and provide share/copy confirmation.
- Request photo-library/write permissions only when needed and explain denial behavior. If saving is blocked, offer Share or Save As if supported.
- File naming must avoid overwriting existing images; add timestamp or unique suffix.
- The implementation must use the video engine's frame-capture capability or a native frame extraction bridge. Do not assume `RepaintBoundary` captures a hardware-decoded video texture reliably.
- Add automated/manual checks for portrait, landscape, high-resolution and HDR/unsupported cases. If exact frame capture is unsupported for an asset, show a clear error.

## 5.4 Additional MX-style controls (P1)

- Volume gesture and app/system brightness gesture, each configurable and disabled by default until tuned. Restore app brightness when leaving the player. System brightness changes may require Android-specific permission and should not be required for basic playback.
- Screen lock/control lock so accidental touches do not affect playback.
- Rotation lock, aspect-ratio menu, playback speed, subtitle menu, audio-track menu, sleep timer, and picture-in-picture where supported.
- Optional swipe gestures should never hide essential accessible buttons or be the only way to use a control.

# 6. Music-player requirements

## 6.1 Now Playing screen (P0)

- Show track title and available artist/album/artwork metadata. If metadata/artwork is absent, show a neutral placeholder, not fabricated information.
- Play/pause, previous, next, rewind 10 seconds, forward 10 seconds, seek bar, elapsed/total time, repeat mode, shuffle, queue button, favorite toggle, and playback speed in P1.
- Support a compact mini-player across app tabs and a full Now Playing view.
- Background playback must update track title, artist, artwork, position, duration, play/pause state, and next/previous actions in Android media notification and iOS lock screen/Control Center where supported.
- Support headset/media button events and audio session interruptions according to platform expectations.

## 6.2 Library views (P0/P1)

P0: songs, folders, recently played, favorites, and search. P1: albums, artists, album art, sorting options, and richer tag editing/metadata. Ensure large lists use lazy rendering and stable item keys.

## 6.3 Optional audio enhancements (P1/P2)

- Sleep timer with a clear countdown and option to stop at end of current track.
- Gapless playback if the selected backend and sources support it.
- Equalizer and audio effects only when the OS/backend provides a real implementation; document Android/iOS differences.
- Lyrics and waveform visualization are optional enhancements, not blockers for the first release.

# 7. Queue and playlist behavior

## 7.1 Live Now Playing queue (P0)

The queue is an editable, persistent list of media items, including audio and video items. Provide the same queue model to the foreground player and the background media session.

Required actions:

- Add to queue, play next, add multiple selected items, remove an upcoming item, drag to reorder, clear upcoming items, jump to a queue item, and save the current queue as a playlist.
- Display the current item distinctly from upcoming items. Show queue count and empty states.
- Queue changes must be observable immediately by all relevant UI and playback layers. Editing upcoming items must not interrupt the current item.
- Preserve duplicates in the queue if the user deliberately adds the same file more than once. In a saved playlist, prevent duplicate entries by default or ask before adding a duplicate; document the behavior.
- On completion, advance to next item according to repeat/shuffle rules. If the queue is empty and repeat is off, stop cleanly and retain a useful completed state.
- Shuffle should not unexpectedly repeat items before exhausting the shuffled set. Previous-item behavior: if playback has progressed beyond 3 seconds, restart the current item; otherwise go to the previous item when available. The threshold can be configurable later.
- “Play next” inserts the item immediately after the current item without clearing other queued items.
- Support saving/restoring queue order, active index, repeat/shuffle setting, and current position after process recreation.

**Terminology assumption:** “Live queueing” means the user can mutate the current queue while media is playing, without restarting the current item. A queue collaboratively edited by multiple signed-in users in real time is a separate P2 feature and is not included in P0.

## 7.2 Playlists (P0)

- Create, rename, delete, reorder, add/remove items, view duration/count, and start playback from a playlist.
- Save the queue as a playlist, and load a playlist into the queue with clear choices (replace queue or append).
- Persist playlists locally for guest and signed-in users. Keep playback usable offline.
- Handle missing media items in a playlist without deleting the entire playlist. Mark them unavailable and allow removal/relinking.
- Support favorites as a built-in playlist/collection.
- Confirm destructive actions such as deleting a playlist; do not confirm every ordinary queue edit.

# 8. Background playback and lock-screen behavior

This section is a release-critical requirement. OS lifecycle and native media-session behavior must be implemented and tested, not simulated in Dart UI state.

## 8.1 User-facing setting

Add **Continue video audio in background** under Settings -> Playback and expose a quick toggle in the video-player overflow/settings panel. Default: **Off** until the user enables it. Explain: “When enabled, video audio can continue while the app is in the background or the device is locked. The video picture is not shown on the locked screen.” Regular MP3 playback continues in the background by default.

## 8.2 Expected behavior

| Scenario | Setting off | Setting on |
|---|---|---|
| User locks screen during MP4 playback | Pause the media and save position | Continue the video's audio; video surface is not visible while locked |
| User switches to another app during MP4 playback | Pause and save position | Continue audio in background |
| User unlocks/reopens app | Resume only after the user presses Play, unless the pause was caused by a transient UI transition that should preserve play intent | Show video at the current playback position with video/audio synchronized and no duplicate audio |
| User starts another queue item while backgrounded | Follow the paused/session policy and do not unexpectedly autoplay | Queue advances normally; if the next item is a video, its audio may continue without a visible picture |
| User explicitly pauses from lock screen/notification/headset | Pause immediately and persist paused state | Pause immediately and persist paused state |
| User disables the setting during background video audio | Pause background audio and preserve position | N/A |

MP3/audio-only media should keep playing while locked unless explicitly paused, interrupted, stopped, or the queue finishes.

## 8.3 Engineering requirements

- Implement a single playback coordinator/state source as the authority for current media, queue, intent, position and playback status. UI, notification, lock screen, headset and native background components must send commands through it.
- On Android, use a suitable foreground/background media service and media session with properly configured notification/permissions for the chosen SDK/plugin stack. Verify behavior with the app in the background and screen locked; do not rely on a Flutter timer or a foreground Activity staying alive.
- On iOS, configure the audio session and Background Modes audio capability as required. Verify the selected video engine does not automatically pause the audio when its video surface is backgrounded; this is a known platform-specific integration point.
- For separate foreground-video and background-audio engines, perform an explicit handoff: capture position and play intent, prevent duplicate audio, start background audio at the matching position, then on foreground return synchronize position and restore video. Keep the queue and lock-screen metadata consistent. This approach must pass the spike tests before adoption.
- If the handoff is not reliable, implement a small native media bridge (Android Media3/ExoPlayer session and iOS AVPlayer-based implementation) or select a compatible backend. Record the choice in an Architecture Decision Record (ADR). Do not hide this risk behind UI code.
- Handle audio focus, phone calls, Bluetooth/headphones, route changes, user pausing, queue changes, app termination, and system task removal consistently.
- Add a small status/debug surface in development builds to observe current engine, foreground/background state, active queue item, position, and handoff errors. Do not show debug details in production.

## 8.4 Mandatory early proof of concept

Before completing library screens or polishing the UI, build a minimal test screen that proves all of the following on a physical Android device and a physical iPhone where available:

1. Play an MP4 with audio.
2. Lock the phone and confirm the audio continues only when the setting is enabled.
3. Pause, seek, next and previous from system media controls.
4. Unlock and confirm video/audio position is synchronized and audio is not doubled.
5. Turn the setting off and verify the defined pause behavior.
6. Repeat for MP3 and verify audio remains stable.

A simulator/emulator alone is not sufficient evidence for background-audio acceptance.

# 9. Account, cloud sync, and privacy

## 9.1 Authentication (P0)

Use Firebase Authentication as the default candidate unless the repository already has a working backend that should be retained. Implement email/password registration and sign-in, sign-out, password reset, auth-state restoration, validation, loading indicators, and user-friendly errors. Add Google/Apple sign-in only after the base provider is stable and configured.

Never hard-code credentials, private keys, service-account JSON, or user tokens. Use FlutterFire configuration appropriate to the development environment. If Firebase configuration is not available, implement the integration boundary and a documented local/emulator setup, but do not claim real authentication works until verified against a configured backend.

## 9.2 Local-first behavior and cloud sync (P0 account foundation; sync P1 if needed)

- Local media files never upload by default. Cloud data is limited to user-owned metadata such as playlists, app settings, favorites and optional playback history. Clearly document which fields sync.
- Local playback, file scanning, local queue editing and local playlists continue when signed out or offline.
- Sign-in should trigger a defined sync operation. Display sync status and recover from network errors without blocking playback.
- Use user-scoped database paths and restrictive security rules. A user must never read or modify another user's records.
- Use stable IDs, updated-at timestamps and a documented conflict strategy. Suggested initial strategy: per-record last-write-wins for simple preferences, transaction/version handling for playlists, and never overwrite a newer local change with a stale sync response.
- Add sign-out behavior that leaves local data on the device by default and explicitly asks before clearing local data.
- Add account deletion and deletion of associated cloud metadata in a later hardening pass; document any provider-console or re-authentication requirements. Do not retain orphaned personal records silently.

## 9.3 Data minimization

- Collect only what is needed for playback, sync and crash/error diagnosis.
- Do not send local file names, absolute paths, media content, thumbnails, or viewing/listening history to the backend unless a clearly documented opt-in feature requires it.
- Avoid analytics by default. If analytics are added later, disclose the events and avoid storing sensitive paths or media titles.
- Provide a privacy policy placeholder and in-app account/privacy controls before public release.

# 10. Architecture and technology choices

## 10.1 Architecture principles

- Use a feature-first, layered architecture: UI/presentation -> application/use cases -> domain models/interfaces -> data/native adapters.
- Keep playback logic out of widgets. UI subscribes to streams/state and sends commands to a `PlaybackCoordinator` or equivalent application service.
- Use repository interfaces for media library, playlists, queue persistence, preferences and account/sync operations.
- Use typed domain models, immutable state where practical, explicit error states, dependency injection, and unit tests for business rules.
- Keep platform-specific file permissions, frame capture, audio sessions and media-service setup isolated behind platform adapters.
- Avoid premature microservices, over-abstraction, or a huge single Dart file. Choose simple modules with clear ownership.

## 10.2 Candidate stack (validate before pinning)

| Concern | Candidate | Notes |
|---|---|---|
| App UI | Flutter + Material 3 | Android and iOS first; responsive phone layouts |
| State management | Riverpod | Use one established state approach consistently |
| Navigation | go_router | Deep links can be considered later |
| Local relational storage | Drift over SQLite | Suitable for media index, playlists, queue, preferences and schema migrations |
| Auth/cloud metadata | Firebase Auth + Cloud Firestore | Only if project configuration and privacy requirements fit |
| MP3 playback | just_audio | Strong queue/seek/repeat primitives; combine with audio_service for advanced background behavior |
| Background controls | audio_service | Lock-screen/notification/headset handling; requires native platform setup |
| Video playback candidate A | Flutter video_player | Official Flutter plugin, backed by native platform players; test codec, zoom, frame capture and background behavior |
| Video playback candidate B | media_kit + video packages | Offers broader playback features including track/subtitle controls and screenshot APIs; audit size, native compatibility and licensing before choosing |
| Media discovery | photo_manager or platform MediaStore adapter | Use scoped, least-privilege permissions and device media APIs |
| Manual file import | file_picker / system document picker | Use for user-selected media and subtitle files |
| Permissions | platform-specific permission handling | Request just-in-time; prefer native pickers where they avoid broad permissions |

These are candidates, not blindly fixed versions. At implementation time inspect the existing `pubspec.yaml`, Flutter/Dart version, current stable package releases, platform support, licenses and open issues. Resolve compatible stable versions together, pin them through `pubspec.lock`, and record any important limitation in an ADR. Do not add two plugins for the same responsibility without a documented reason.

## 10.3 Most important architecture decision: media engine

The foreground video UI, MP3 background service, video-audio-in-background behavior, frame screenshot, zoom, subtitles and track selection interact. Do not finalize the player library before the Section 8.4 spike.

Evaluate two paths:

**Path A - Flutter-plugin composition:** use `video_player` or `media_kit` for foreground video, plus `just_audio`/`audio_service` for MP3/background controls. If required, implement a coordinated handoff from a video player to an audio-only background player when the app is locked/backgrounded. Prove that the chosen audio backend can play the audio stream from the target MP4 container and remain synchronized. Avoid duplicate playback during handoff.

**Path B - Native session bridge:** use Android Media3/ExoPlayer with a `MediaSessionService` and an iOS AVPlayer/audio-session implementation behind a Flutter interface. This may be needed if Path A cannot deliver seamless video-audio background behavior. Keep the Dart interface stable so the rest of the app is not tied to native details.

Choose based on a working Android/iOS proof of concept, codec coverage, lock-screen controls, screenshot/track capabilities, licensing, build complexity, package maintenance and app size. Write `docs/adr/0001-media-engine.md` with the selected approach and rejected alternative. Do not claim screen-lock playback is solved until device tests pass.

## 10.4 App state ownership

The playback coordinator is the sole authority for:

- current media ID and type;
- current playback position, duration and play/pause/buffering/error state;
- current queue, current queue index, shuffle/repeat mode;
- playback intent across foreground/background transitions;
- mapping of queue items to system `MediaItem` metadata;
- persisted resume position and restoration.

The UI must not instantiate its own competing audio player or derive queue truth separately. Avoid two audible engines playing simultaneously. Any handoff must have a well-defined state transition and be covered by tests.

# 11. Data model and persistence

Use Drift/SQLite or an equivalent mature local database with migrations. Keep local records authoritative for local media state. Suggested tables/models:

| Model | Key fields |
|---|---|
| `MediaItem` | `id`, `mediaType` (audio/video), `title`, `uriOrPath`, `mimeType`, `durationMs`, `sizeBytes`, `modifiedAt`, `addedAt`, `metadataJson`, `availability`, `thumbnailRef` |
| `PlaybackProgress` | `mediaId`, `positionMs`, `lastPlayedAt`, `completed`, `updatedAt` |
| `QueueState` | `id`, `entries`, `currentIndex`, `shuffleMode`, `repeatMode`, `updatedAt` |
| `QueueEntry` | `id`, `mediaId`, `orderIndex`, `addedAt`, optional source/metadata snapshot |
| `Playlist` | `id`, `ownerScope` (local/user), `userId` nullable, `name`, `createdAt`, `updatedAt`, `sortOrder` |
| `PlaylistEntry` | `id`, `playlistId`, `mediaId`, `orderIndex`, `addedAt` |
| `UserPreference` | `key`, `value`, `updatedAt`, sync eligibility |
| `Favorite` | `mediaId`, `createdAt` |
| `SyncMetadata` | `userId`, `lastSyncAt`, per-record version or sync token, error status |

Implementation guidance:

- Store durations and positions as integer milliseconds or `Duration` wrappers at the domain boundary; avoid floating-point seconds for persisted positions.
- Queue entries need their own IDs so the same media file can appear more than once.
- Use database migrations and write tests for migration paths.
- Store a platform-appropriate durable URI/security grant where relevant, not just an ephemeral temporary path.
- Reconcile scanned files without deleting saved playlists/history by default. If a file disappears, keep the library record marked unavailable until the user removes it or rescan policy decides otherwise.
- Add indexes for title search, media type, recent play and foreign keys. Do not load the entire library for every list render.
- Store cloud-synced records separately or clearly flag them so guest/local data cannot accidentally leak to a signed-in account.

# 12. UX, accessibility, and quality requirements

## Visual system

- Use Material 3 with a polished dark theme as the default and a light theme option. Keep colors, spacing, radii, typography and player control sizing in a small design-token layer.
- Use original icons/branding. Use familiar playback iconography, consistent placement of seek buttons, large touch targets and readable contrast.
- Provide list and grid modes where useful, sensible empty/loading/error states, skeletons only where they improve perceived performance, and confirmations only for destructive actions.
- Keep Now Playing and queue usable one-handed. Do not require gesture-only interactions.

## Accessibility

- Use semantic labels for all icon buttons, screen-reader-friendly playback status, sufficient contrast and scalable text.
- Controls should have a practical touch target (aim for at least 48 logical pixels where layout allows).
- Ensure dialogs, bottom sheets and navigation work with TalkBack/VoiceOver and keyboard navigation where applicable.
- Do not use color as the sole means of indicating the active queue item or favorite state.

## Reliability and performance

- Avoid blocking the main isolate with directory scans, metadata extraction or thumbnail generation.
- Dispose of native controllers, event subscriptions, timers and stream listeners correctly.
- Handle rotation, app lifecycle, permissions revoked in Settings, Bluetooth route changes, low storage, corrupted files, unsupported codecs, file deletion and database migration failures.
- Restore only a valid playback state. Do not auto-play unexpectedly after a crash unless user settings and platform policy explicitly permit it.
- Log diagnostic error categories in debug builds; do not log authentication tokens or unnecessary personal/media data.

# 13. Suggested project structure

Adapt to the repository if it already has a good structure. Do not replace working code just to match this tree.

```text
lib/
  main.dart
  app/
    app.dart
    router.dart
    theme/
    bootstrap/
  core/
    errors/
    logging/
    permissions/
    platform/
    utils/
    widgets/
  features/
    library/
    video_player/
    music_player/
    playback/
    queue/
    playlists/
    account/
    settings/
    sync/
  shared/
    models/
    repositories/
    services/
test/
  unit/
  widget/
integration_test/
docs/
  adr/
  testing/
```

Each feature can contain `data/`, `domain/`, and `presentation/` subfolders as needed. Use the naming conventions of any existing project where appropriate. Avoid a generic `services.dart` or `utils.dart` that grows into a dumping ground.

# 14. Phased implementation plan

Claude Code must implement, test and commit coherent phases. Do not generate the entire app in one unreviewed code dump.

## Phase 0 - Repository and toolchain audit

- Inspect repository tree, Git status, `pubspec.yaml`, Flutter/Dart versions, Android Gradle/Kotlin/SDK configuration, iOS deployment target, lint rules and current tests.
- Run `flutter doctor -v`, `flutter pub get`, `flutter analyze`, and existing tests. Record existing failures before editing.
- Identify project name/package ID and whether the repo is new or an existing app. Preserve unrelated user work.
- Produce a short implementation plan, risks list and initial ADR outline.
- Exit gate: baseline is recorded; no existing configuration is silently overwritten.

## Phase 1 - Media engine/background-audio proof of concept (highest risk)

- Build a small temporary/player test screen for MP3 and MP4.
- Validate foreground controls, exact 10-second seeks, Android lock-screen notification/remote controls, iOS lock-screen/Control Center, and MP4 audio continuing in background when the setting is enabled.
- Validate pause behavior when setting is disabled, no duplicate audio, unlock position synchronization, queue next/previous, audio focus/interruptions and screen locked on real devices.
- Decide on video engine and screenshot strategy; audit licenses and package compatibility; write ADR.
- Exit gate: proof works on at least one physical Android device; iOS behavior is validated on a physical device before public iOS release. Any unsupported behavior is explicitly recorded, not hidden.

## Phase 2 - App shell and local persistence

- Add theme, navigation, feature structure, local database, preferences, permission service and empty/loading/error states.
- Add media scan/import and lazy library browsing.
- Exit gate: library refresh, indexing, permission denial/recovery, missing files and migrations are tested.

## Phase 3 - Core players

- Implement MP3 and MP4 playback using the chosen abstraction; play/pause, seek bar, ±10 seconds, next/previous, completion, basic queue and resume position.
- Add Now Playing and video zoom/pan/reset and test screenshot save/share.
- Exit gate: core player acceptance tests pass; no leaked controllers or duplicate audio.

## Phase 4 - Queue and playlists

- Complete live queue insert/remove/reorder, shuffle/repeat, previous behavior, save queue as playlist, edit playlists and unavailable-file handling.
- Exit gate: queue tests prove the current item is unaffected by edits to future items.

## Phase 5 - Background and system integration

- Finalize background audio toggle and engine handoff/native implementation, media session metadata, lock-screen/notification controls, headset events, audio interruptions, and iOS background mode.
- Exit gate: Section 8.4 test suite passes on physical devices; capture logs and manual test notes.

## Phase 6 - Accounts and sync

- Configure auth provider, sign-up/sign-in/reset/profile screens, guest mode, sync metadata/preferences/playlists, offline conflict handling and security rules.
- Exit gate: authenticated user isolation/security rules tested; app remains functional offline and as guest.

## Phase 7 - Player parity features

- Add external subtitles and track selection, speed, sleep timer, screen lock, gesture options, optional equalizer and picture-in-picture based on P1 plan.
- Exit gate: each control has a real implementation and a platform/feature test; unsupported features are hidden or explicitly marked.

## Phase 8 - Hardening and release preparation

- Test broad device/orientation/media cases, battery interruptions, large libraries, accessibility, performance and recovery after force-stop/process death.
- Review privacy disclosures, account deletion path, release signing, package ID, icons and store permissions.
- Run all automated tests, `flutter analyze`, release builds and documented smoke tests.
- Exit gate: no known P0 defects; all remaining limitations are documented.

# 15. Acceptance criteria and test matrix

A feature is not “done” because it compiles. It is done when its behavior is demonstrated by automated tests where practical and by the manual device checks below.

## P0 acceptance checklist

- [ ] User can scan/import and play local MP4 and MP3 on Android and iOS.
- [ ] Play/pause, seek bar, previous/next, and rewind/forward each move by 10 seconds within the media bounds.
- [ ] Pinch zoom/pan/reset works on real video frames, without conflicts with double-tap seeking.
- [ ] Screenshot captures the actual current video frame without controls and saves/shares successfully, or returns a clear actionable error.
- [ ] Add-to-queue, play-next, remove and reorder update the queue immediately without restarting the current item.
- [ ] Playlist create/rename/delete/edit and save-current-queue operations survive app restart.
- [ ] MP3 continues when the screen is locked and lock-screen/notification controls change real playback state.
- [ ] MP4 audio continues after lock/background only when the setting is enabled; disabled mode pauses and saves position.
- [ ] Unlocking after background MP4 audio resumes video at a synchronized position with no audible double playback.
- [ ] Phone-call/audio-focus interruptions and user-initiated pauses do not trigger unwanted auto-resume.
- [ ] Guest mode works without network. Account create/sign-in/reset work against configured auth, not a mock.
- [ ] User data is scoped to the signed-in user; media files themselves are not uploaded.
- [ ] `flutter analyze` and unit/widget/integration test suites pass; debug and release builds succeed.

## Device and scenario matrix

| Area | Minimum manual coverage |
|---|---|
| Android | At least one physical device on a recent Android release; one older supported Android version if available; lock/unlock; notification controls; app switch; battery saver; permission denial/regrant |
| iOS | At least one physical iPhone before release; lock/unlock; Control Center; app switch; Silent switch; audio interruption; photo permission handling |
| Media files | Short clip (<10 s), long MP4, portrait and landscape, silent video, video with audio, MP3 with/without metadata, corrupt/unsupported file |
| Queue | Single item, empty queue, last item, duplicates, shuffle, repeat one/all, reorder while playing, remove upcoming item, app process restart |
| Screenshot/zoom | Multiple aspect ratios, zoom min/max, reset, frame captured while controls visible, permission denied, low storage |
| Account/sync | Guest, sign-up, wrong password, reset, offline sign-in state, two users, sync conflict, sign-out, local data retention |

## Suggested automated tests

- Unit tests: seek arithmetic at file boundaries; queue insertion/reordering; shuffle/repeat transitions; previous-item threshold; playlist validation; missing-media reconciliation; background-state machine; sync conflict rules.
- Widget tests: empty library, loading/error states, player controls, queue sheet and playlist editor.
- Integration tests: library -> play -> seek -> queue -> next; create playlist; persistence after restart; basic account form flows with Firebase emulator/test setup.
- Native/manual tests: actual OS background media session, screen lock, screenshot of hardware-decoded video frame, audio-session interruptions, PiP and platform-specific permissions.

# 16. Risks, constraints, and engineering decisions

| Risk | Mitigation |
|---|---|
| MP4 audio stops when locked on iOS or Android | Prove the background architecture in Phase 1 on physical devices; use a native service/session if plugin composition is unreliable |
| Two player engines drift or play simultaneously | One coordinator owns play intent/position; handoff is explicit and tested; ensure only one engine is audible at a time |
| Screenshot captures black/controls instead of video frame | Use native decoder/player screenshot or frame extraction, not UI-widget capture as the only solution |
| Plugin versions conflict with current Flutter/Gradle/Xcode | Audit installed toolchain first; choose compatible stable versions and lock them; do not randomly upgrade the entire toolchain |
| Video zoom breaks with platform texture/view | Test real device rendering and gesture interactions during POC; select compatible backend/view type |
| Broad filesystem permissions rejected by platform/store | Use media APIs and system pickers with least privilege; don't request all-files access for convenience |
| Account sync overwrites local state or leaks user data | User-scoped security rules, stable IDs, conflict strategy, emulator tests and no media uploads |
| “All MX Player features” grows without limit | Maintain P0/P1/P2 scope, add features only with acceptance criteria, and document gaps by platform |

## Architecture Decision Records (ADRs)

At minimum create:

- `docs/adr/0001-media-engine.md` - engine selection, physical-device test evidence, package/license trade-offs and background audio behavior.
- `docs/adr/0002-local-storage-and-media-access.md` - Drift/SQLite schema, Android/iOS media access and stable URI strategy.
- `docs/adr/0003-auth-and-sync.md` - provider, guest mode, sync scope, security rules and conflict handling.

# 17. Claude Code working rules and first prompt

## Mandatory working rules

1. Start by inspecting the repository. Do not assume it is empty, and do not overwrite unrelated work.
2. Read this specification and the root `CLAUDE.md` before coding. Treat this spec as the product source of truth; when something is technically impossible or platform-dependent, explain the limitation and record an alternative.
3. Build in phases. At the start of each phase, list files to change and acceptance checks; after the phase, run relevant commands and summarize results.
4. Use current stable, mutually compatible dependencies. Verify package documentation and licenses at implementation time. Never add a package based only on its name or a stale blog post.
5. Do not make mock UI look like a working feature. If a provider key, Firebase config, signing identity or device permission is missing, document exactly what is needed and keep the app in a safe, testable state.
6. Keep the app runnable after each phase. Run `dart format`, `flutter analyze`, relevant tests and builds where practical. Do not suppress warnings or errors without explaining why.
7. Do not change Flutter/Gradle/Kotlin/Xcode versions globally unless the project actually requires it. Record baseline failures before making changes.
8. Do not upload local files or personal library information to the cloud. Do not add analytics or ads unless separately approved.
9. Prioritize media playback correctness, queue correctness and background lifecycle behavior over animations and decorative polish.
10. Report what was implemented, how it was tested, commands that passed/failed, platform-specific limitations and the next smallest step. Never state that a test passed unless it was run.

## Initial prompt to give Claude Code

> Read `CLAUDE.md` and `MEDIA_PLAYER_SPEC.md` completely. First inspect this repository, current Git changes, Flutter/Dart toolchain, dependencies and Android/iOS configuration. Do not edit or delete existing user work. Report the current baseline (`flutter doctor -v`, `flutter pub get`, `flutter analyze`, existing tests/build where possible), then propose a phased implementation plan mapped to the acceptance criteria in the spec. Start with Phase 1's smallest media-engine proof of concept: MP3 playback plus MP4 playback, 10-second seek, video zoom feasibility, true frame screenshot feasibility, and especially MP4 audio continuing when the phone is locked with the setting enabled on a physical Android device and iPhone when available. Compare viable player-stack options, verify current package compatibility/licenses, and write ADR 0001 before choosing. Do not build all screens first or claim background playback works without device evidence. Implement only the next phase, run tests and analyze, and summarize exact files changed, results, blockers, and the next phase.

# 18. Reference documentation

Use official or package-maintainer documentation as the starting point. Verify the latest documentation and compatibility at implementation time.

1. Flutter `video_player`: https://pub.dev/packages/video_player
2. Flutter `media_kit`: https://pub.dev/packages/media_kit
3. `just_audio`: https://pub.dev/packages/just_audio
4. `audio_service`: https://pub.dev/packages/audio_service
5. Android Media3 background playback and media sessions: https://developer.android.com/media/media3/session/background-playback
6. Apple AVFoundation media playback configuration: https://developer.apple.com/documentation/avfoundation/configuring-your-app-for-media-playback
7. Android shared media storage: https://developer.android.com/training/data-storage/shared/media
8. Android 13+ granular media permissions: https://developer.android.com/about/versions/13/behavior-changes-13
9. Firebase Authentication for Flutter: https://firebase.google.com/docs/auth/flutter/start
10. `photo_manager`: https://pub.dev/packages/photo_manager
11. `file_picker`: https://pub.dev/packages/file_picker
12. Drift/SQLite persistence: https://pub.dev/packages/drift

---

**Build order in one sentence:** prove background media behavior first, then ship a stable local player and queue, then playlists and account sync, then add advanced player-parity features in tested increments.
