# Local patch of audio_service 0.18.19 (MIT)

Vendored from pub.dev `audio_service` 0.18.19 (`example/` and `test/` omitted)
and wired in via `dependency_overrides` in the app's `pubspec.yaml`.

## Change

`android/src/main/java/com/ryanheise/audioservice/AudioService.java`,
`MediaSessionCallback.onMediaButtonEvent`: `KEYCODE_MEDIA_PLAY` now calls
`onPlay()` and `KEYCODE_MEDIA_PAUSE` calls `onPause()`. Upstream routes both
to `onClick(MediaButton.media)`, which toggles.

## Why

Found on a physical device (Motorola Edge 50 Pro, Android 16) on 2026-10-26.
`adb shell cmd media_session dispatch pause` while paused **started**
playback, and `play` while playing paused it. Bluetooth AVRCP devices and
car head units send these explicit keys, so a PAUSE (for example on disconnect)
could start audio unexpectedly. That violates spec 4.2 / 15: no unwanted
resume after a user pause.

Trade-off: if an Android version reroutes a headset single-click into PLAY or
PAUSE, multi-click detection (double-click = next) is lost for that click.
It is still correct for a single click. `KEYCODE_MEDIA_PLAY_PAUSE` and
`KEYCODE_HEADSETHOOK` keep upstream click and multi-click handling.

## Maintenance

Re-apply when upgrading `audio_service`, or drop this override if upstream
fixes it. Device check: `explicit_keys` in `scripts/device_lifecycle_checks.py`.
