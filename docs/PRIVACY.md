# Privacy policy (draft placeholder)

> **Status:** draft for review. It must be completed, reviewed and published at a public URL before any public release (spec 9.3).

**AS Media** plays video and music files that are already on your device.

## Data that stays on your device
- Your video and music files are never uploaded.
- The library index is stored only in the app's local database. It contains titles, durations, sizes, folders and content URIs.
- Playback positions, the queue, playlists, favourites and settings are stored locally.
- Frame screenshots are saved to the "AS Media Screenshots" album and shared only on request.

## Permissions
- **Media access (videos and audio):** requested only when you start a library scan. On Android 14+ you can allow selected videos only.
- **Files picked with the system picker:** need no permission; access is kept per file.
- **Not requested:** all-files access and photos access.
- **Foreground service / wake lock:** to keep playing when the screen is off.
- **Internet:** used for sign-in and sync, online discovery, streaming and downloads (see below).
- **Notifications:** asked for on your first download, to show download progress.

## Optional account
If you sign in, the following sync to your account (Firebase, operated by Google):
- playlists you choose to add to the account;
- favourites;
- app settings.

Files are referenced by one-way fingerprints, not by names, paths or titles. Viewing and listening history is **not** synced. Your account email is processed by Firebase Authentication.

You can:
- sign out and keep your data on the device;
- sign out and remove the account's playlists from the device;
- delete your account, which first deletes its synced data.

## Online discovery and downloads
- **Music search (Audius, and Jamendo if you add a client ID):** your search terms and the tracks you play are sent to that service. Streams come from the service's servers.
- **YouTube (if you add an API key):** your search terms go to the YouTube Data API. Videos play in YouTube's own embedded player, which is covered by Google's privacy policy.
- **Downloads:** files are fetched from the source you chose and saved to `Music/AS Media` or `Movies/AS Media` on your device. Download history is stored only on the device.
- The YouTube API key and Jamendo client ID are stored only on the device and are never synced.
- Nothing from your local library is sent to these services.

## Analytics and advertising
None.

## Contact
_To be added by the publisher._
