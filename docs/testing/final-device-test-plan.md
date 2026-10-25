# Final device test plan (end of development)

Run this once, on the physical Android phone, after all features are built (agreed 2026-10-26). Automated suites run first; the manual rows need a person, mainly for the PIN unlock and system dialogs.

**Setup:** connect the phone with USB debugging, unlock it, and keep it unlocked for the automated parts. Scripts keep the screen on (`svc power stayon usb`) and restore the setting afterwards.

## A. Automated (about 25 min)

| Suite | Command | Covers |
|---|---|---|
| Unit + widget | `flutter test` | Domain rules, repositories, sync, migrations, UI states |
| Engine | `scripts/run_device_engine_tests.sh <id> engine_test.dart` | Playback, ±10 s, clamping, frame capture, MP3, errors, queue, background policy |
| Zoom | `scripts/run_device_engine_tests.sh <id> zoom_test.dart` | Pinch, pan bounds, reset, double-tap on the debug engine screen. **Extend first** to the full-screen video player (pan only while zoomed, swipe gestures) |
| Library | `scripts/run_device_library_test.sh <id>` | Real MediaStore scan, metadata, thumbnails, `content://` playback, progress resume |
| OS lifecycle | `python3 -I scripts/device_lifecycle_checks.py <id>` (see README) | Lock/Home with the setting on/off, media keys, notification and lock-screen card, PiP, battery saver, task removal, explicit PLAY/PAUSE keys |

## B. Manual: features built after the Phase 1 evidence

| # | Area | Steps | Expected |
|---|---|---|---|
| 1 | First launch | Fresh install, then open | Home empty state; no permission prompt until **Scan library** |
| 2 | Permission dialog | Scan → **Don't allow**; scan again → deny twice | Snackbar explains; second time offers **Settings**. Choose files still works |
| 3 | Partial access (Android 14+) | Scan → "Select photos and videos" → pick 2 videos | Only those are indexed; message says "only videos you selected" |
| 4 | Import | Choose files → MP4 + MP3; force-stop; reopen | Items still play (persisted grant), no file copy |
| 5 | Missing file | Delete an indexed video with Files; Rescan | Item stays listed as **Unavailable**; Rescan/Remove offered; playlists keep it |
| 6 | Video player | Play a video; tap, wait 3 s, pause | Controls hide while playing and stay visible while paused |
| 7 | Double-tap zones | Double-tap left / centre / right; zoom in, then double-tap left | −10 s / 2× zoom / +10 s; while zoomed, double-tap only resets zoom |
| 8 | Fit / fullscreen / rotation lock | Aspect ratio Fit/Crop/Stretch; Fullscreen; Lock rotation; back | Modes apply; orientation and system bars restored on exit |
| 9 | Controls lock | Lock controls, then tap | Only the unlock button appears; gestures ignored |
| 10 | Screenshot | Capture in the full-screen player | Saved to the album at video resolution, without controls |
| 11 | Music player | Play an MP3 with and without tags/artwork | Artwork or placeholder; artist/album only when tagged |
| 12 | Queue | Play next / Add to queue; drag reorder; swipe remove; clear upcoming | Current item never restarts |
| 13 | Repeat / shuffle | Repeat one/all, shuffle on a 5-item queue | One repeats; all wraps; shuffle plays each once before ending |
| 14 | Queue restore | Queue 3 items, play the 2nd at 1:00, force-stop, reopen | Queue restored, paused at about 1:00; no auto-play |
| 15 | Playlists | Create, add with duplicate prompt, reorder, remove + undo, rename, delete (confirm), Play vs Add to queue, save queue as playlist | Behaves as described |
| 16 | Favourites | Favourite from list and music player | Appears in Favourites; heart shown |
| 17 | Speed | 0.5× / 2× on video and MP3 | Audible speed change; carries to the next item |
| 18 | Sleep timer | 5 min; "End of current item" | Pauses on time; stops after the item without advancing |
| 19 | Subtitles | Load an SRT and a VTT; size; delay ±; turn off | Captions show and sync; unsupported file gives a clear error |
| 20 | Audio tracks | Video with 2 audio tracks | Menu entry appears; switching changes language |
| 21 | Gestures | Enable brightness and volume gestures; swipe left/right halves; leave the player | Brightness and volume change; app brightness restored on exit; off by default |
| 22 | Notification | Tap the media notification | Opens Now Playing; status-bar icon is a clean glyph |
| 23 | Headphones | Unplug wired headphones / disconnect Bluetooth during playback | Pauses and does not auto-resume (Phase 1 #14) |
| 24 | Account (not configured) | Settings → Account | "Accounts are not set up in this build" |
| 25 | Account (after Firebase setup) | Register, sign out, sign in, reset email, sync on 2 devices, delete account | Real backend; consent before attaching guest playlists; no media uploaded |
| 26 | Large text / TalkBack | Font size max; TalkBack through Home, player, queue | No clipped controls; all buttons announced |
| 27 | Theme | Settings → Light / System | Applies immediately and persists |
| 28 | Icon | Launcher, themed icons on (Android 13+) | Original icon; monochrome version when themed |
