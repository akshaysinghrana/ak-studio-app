# App icon

- `app_icon_source.png`: the supplied artwork (1254×1254).
- `play_store_icon_512.png`: the Play Store listing icon.
- `make_icon.py`: regenerates every launcher icon (needs Pillow):
  `python3 branding/make_icon.py branding/app_icon_source.png android/app/src/main/res branding`

How the Android icon is built:
- **Adaptive icon (Android 8+):** the logo and wordmark are fitted inside the circular mask area, so nothing is clipped on any launcher shape. The background layer is the artwork's glow, blurred.
- **Android 7:** the full original artwork is used.
- **Themed icons (Android 13+):** there is no monochrome layer, so launchers show the colour icon.
- **Notification icon:** `drawable/ic_stat_player`. It must stay a single-colour glyph; the status bar can't show the colour logo.
