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
- **Internet:** used for optional sign-in and metadata sync, and when you paste
  a web link to resolve or download media. Link requests go directly from your
  device to the site. The extractor may check GitHub for yt-dlp updates when it
  is first used; update failure does not prevent trying the bundled version.

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

## Analytics and advertising
None.

## Contact
_To be added by the publisher._
