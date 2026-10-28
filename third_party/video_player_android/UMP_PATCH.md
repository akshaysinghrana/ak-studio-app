# Local patch of video_player_android 2.12.2 (BSD-3-Clause)

Vendored from pub.dev `video_player_android` 2.12.2 (`example/` and `test/` omitted)
and wired in through `dependency_overrides` in the app's `pubspec.yaml`.

## Change

- `VideoPlayer.setVideoTrackDisabled(boolean)` toggles
  `DefaultTrackSelector.setTrackTypeDisabled(TRACK_TYPE_VIDEO, …)`.
- `VideoPlayerPlugin` registers the method channel
  `com.akshayrana.video_music_app/video_player_ump` with one method:
  `setAudioOnly(bool)`. It applies the setting to every live player.
- The app's `PlaybackCoordinator` calls it when it keeps a video's audio
  playing in the background (setting on), and turns it off on return to the
  foreground and when a new item loads.

## Why

Upstream keeps the video renderer and its hardware `MediaCodec` running while
only the audio is heard. Android's media resource manager can reclaim codecs
from background apps, which stops playback. This was reported on a Motorola
Edge 50 Pro (Android 16) on 2026-10-28: background audio stopped after a few
minutes. Releasing the decoder in audio-only mode avoids that and saves
power. Re-enabling restores the picture at the current position.

Waiting for the OS to destroy the video surface is not a reliable trigger:
Flutter does that only under memory pressure, as verified on the emulator.

## Maintenance

Re-apply when upgrading `video_player_android`, or drop the patch if upstream
adds an audio-only mode.
