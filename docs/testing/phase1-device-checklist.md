# Phase 1 — physical Android device checklist (spec 8.4)

An emulator does not count as evidence. Run a **debug** build: `flutter run` with the phone connected over USB, and keep the on-screen DEBUG panel and the `[playback]` log lines visible.

Prepare these files on the phone: a long MP4 with audio, a clip shorter than 10 s, a portrait MP4, an MP3, and a corrupt or renamed `.mp4`.

Record for each run: device model, Android version, result (pass/fail) and notes. Then paste the results into `docs/adr/0001-media-engine.md` → Evidence.

| # | Steps | Expected |
|---|---|---|
| 1 | Choose files → long MP4 | Video and audio play |
| 2 | Tap −10 / +10 several times, then near the start and the end | Moves exactly 10 s and stops at 0 and at the duration. "−10s"/"+10s" feedback appears |
| 3 | Short clip (<10 s): ±10 | Stays at 0 or at the end. No crash |
| 4 | Pinch to zoom, pan, double-tap, Reset zoom, Crop/Fit | Zoom works between 1× and 4×. The video cannot be panned off-screen. Reset works |
| 5 | Capture frame (controls visible) | Photo in the gallery album "Media Player Screenshots" shows the video frame only, at full resolution, with no controls. Share works |
| 6 | Setting **off**, MP4 playing → lock screen | Audio pauses. After unlock, it stays paused at the same position |
| 7 | Setting **off**, MP4 playing → home button / switch app | Audio pauses |
| 8 | Setting **on**, MP4 playing → lock screen for ≥2 min | Audio continues. The lock-screen controls show the title |
| 9 | While test 8 runs: pause, play, ±10, next, previous from the lock screen and the notification | Each one changes real playback |
| 10 | Unlock after test 8 | Video shows at the current position, A/V is in sync, and only **one** audio stream plays |
| 11 | Setting on → background → open the app → turn the setting off → background again | Audio pauses |
| 12 | MP3 (setting off) → lock for ≥5 min | Audio continues without stutter |
| 13 | During playback: incoming call, or play a YouTube video | Playback pauses. After a user pause it does not resume on its own |
| 14 | Unplug wired headphones or disconnect Bluetooth | Playback pauses |
| 15 | Headset play/pause button | Toggles playback |
| 16 | Corrupt `.mp4` | An error message appears, not an endless spinner |
| 17 | Queue: add 3 items, tap a queue item, let an item finish | Jumps to the tapped item. Advances on completion. Stops cleanly at the end |
| 18 | Battery saver on, repeat test 8 | Note the result |
| 19 | Swipe the app away from recents while playing | Playback stops and the notification is removed |
