# Claude Code Project Instructions — Unified Media Player

## Read first
Before coding, read `MEDIA_PLAYER_SPEC.md` from beginning to end. It is the product and engineering source of truth.

## Non-negotiable rules
- Inspect the existing repository, Git status, toolchain and baseline tests before editing. Preserve unrelated user work.
- Implement in small, testable phases; do not generate the entire application in one pass.
- Phase 1 must prove MP3/MP4 playback, 10-second seeking, video zoom, actual decoded-frame screenshot feasibility, and MP4 audio continuing when locked with the setting enabled. Test on physical devices; do not assume Flutter lifecycle callbacks alone provide background playback.
- Write `docs/adr/0001-media-engine.md` with the selected player architecture, package/license trade-offs and device evidence before committing to the media engine.
- Keep a single playback coordinator as the source of truth for media, queue, position, playback intent and background state. Never allow two audible engines to play simultaneously.
- Current local MP4/MP3 playback, library, queues and playlists must work offline and as guest. Authentication and sync must be real when configured; never fake a successful login.
- Local media files and media content are never uploaded by default. Sync only documented metadata with strict per-user authorization.
- Verify current stable dependency versions and their platform support at implementation time. Check package licenses, build compatibility and known issues before adding packages.
- Do not imitate another app's exact branding/assets. Use an original, accessible Material 3 interface.
- After changes run `dart format`, `flutter analyze`, relevant tests, and builds where practical. Do not claim checks passed unless they were actually run.
- Do not make a control appear functional if it is only a mock. Explain any missing credentials, permissions, physical-device checks or platform limitations.
- Do not upgrade Flutter, Gradle, Kotlin, Android SDK or Xcode just to remove warnings unless there is a demonstrated compatibility requirement. Record baseline failures first.

## Required reporting after each phase
1. Summary of behavior implemented.
2. Exact files changed.
3. Commands/tests/builds run and their actual results.
4. Known limitations, device-only checks still needed, and blockers.
5. The smallest next implementation step.

## Start command
Use the initial prompt in Section 17 of `MEDIA_PLAYER_SPEC.md`. Start with repository audit and the media-engine proof of concept, not UI polish.
