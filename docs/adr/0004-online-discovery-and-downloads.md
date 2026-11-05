# ADR 0004: Online discovery (YouTube, music catalogues) and downloads

- **Status:** Accepted. Audius works without setup. YouTube and Jamendo need the owner's credentials; until then their sections say they are not set up.
- **Date:** 2026-11-06
- **Context:** The spec lists network streams and downloads as P2, "separate planning decision". The owner requested YouTube, Spotify-like music search and a downloader for a personal APK, keeping every local feature intact.

## Decision

The app has two playback systems that never play at the same time.

| | Local and catalogue playback | YouTube |
|---|---|---|
| Engine | `PlaybackCoordinator` (ExoPlayer via `video_player`) | Official YouTube IFrame player (`youtube_player_iframe` 6.0.2, BSD-3) |
| Sources | Library files, Audius/Jamendo streams, downloads | YouTube video IDs from the Data API v3 |
| Background, lock screen, queue | Yes | No. The player pauses when the app leaves the foreground |
| Download | Only where the source permits it | **Never** |

Opening a YouTube video pauses the coordinator. YouTube is never routed through the coordinator, no stream URLs are extracted, and YouTube audio is never converted. This follows the YouTube API Services Developer Policies: no downloading or offline copies, no separating audio from video, and no background play through an API client.

### Music discovery

The catalogue sources are behind a `MusicCatalog` interface.

- **Audius** (`api.audius.co`, no key; requests carry `app_name=AS_Media`):
  - trending tracks and playlists;
  - search for tracks, artists and playlists;
  - artist tracks and playlist tracks.
- **Playback:** only tracks with `is_streamable` true and not stream-gated are shown. They play from `/v1/tracks/{id}/stream`, which redirects to an MP3 that supports range requests.
- **Downloads:** offered only when the artist enabled them (`is_downloadable` true and not download-gated).
- **Jamendo** (optional, needs a free client ID from devportal.jamendo.com): popular and search. Downloads are offered only when `audiodownload_allowed` is true. Jamendo music is Creative Commons licensed.
- Online tracks play through the coordinator, so the queue, lock-screen and notification controls, sleep timer and speed all work.
- Online items are not library items. The saved queue and resume positions skip them (both stores already ignore unknown IDs), and favourites and playlists are offered after download instead.

### Downloads

- **Package:** `background_downloader` 9.6.5 (BSD-3). It uses WorkManager, or UIDT jobs on Android 14+, for downloads that survive the app closing. It provides pause and resume through HTTP Range, retries, Wi-Fi-only mode, a concurrency limit and progress notifications. 9.6.6 was published the day before this decision, so the previous release is pinned.
- **Sources:**
  - catalogue tracks whose source permits download;
  - a direct `http(s)` URL the user is entitled to download.
  - Direct URLs on YouTube or Google video hosts are refused.
  - Only MP3 and MP4 are accepted, matching what the library plays. The type is validated before the file is added.
- **Flow:**
  1. Download into app storage.
  2. Validate the file.
  3. Move it to `Music/AS Media` or `Movies/AS Media` through MediaStore. No storage permission is needed on Android 10+.
  4. The existing MediaStore observer rescans, and the file appears in the library.
  5. Optionally add it to the "Downloads" playlist.
- **History** is kept in a new `downloads` table (schema v5): source, source ID, title, status, bytes and the final path.
- **Duplicates** are detected by source and source ID; the user is asked before downloading again.
- **Settings:**
  - Wi-Fi only;
  - simultaneous downloads (1–3);
  - add to the "Downloads" playlist;
  - Jamendo quality: MP3 96 kbps or VBR high.
  - There is no video-quality setting, because no supported source offers video variants.
- **New permissions:**
  - `POST_NOTIFICATIONS`, for download progress. It is requested on the first download only.
  - `RUN_USER_INITIATED_JOBS`, for long downloads on Android 14+.

### Credentials

- The YouTube Data API key and the Jamendo client ID are entered in **Settings → Online sources**.
- They are stored only in the local preferences table. They are never synced and never committed.
- Each one can also be supplied at build time with `--dart-define=YOUTUBE_API_KEY=…` or `--dart-define=JAMENDO_CLIENT_ID=…`.
- Restrict the YouTube key to the Android app (package name plus the SHA-1 fingerprint) in Google Cloud Console.

## Consequences

- The app now uses the network for discovery, streaming and downloads. Local playback, library, queue and playlists still work offline and as a guest.
- Privacy: search terms go to the chosen service. Nothing from the local library is sent.
- Not in this ADR:
  - YouTube account login (OAuth);
  - online favourites and recently played lists;
  - formats beyond MP3/MP4;
  - an equalizer.
