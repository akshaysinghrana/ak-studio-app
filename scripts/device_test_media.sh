#!/bin/bash
# Generates synthetic test media (if needed) and pushes it into the app's own
# external files dir on a connected Android device. No media permission is
# needed to read files there. Usage: scripts/device_test_media.sh [device-id]
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
OUT="$ROOT/build/test_media"
ADB=(adb ${1:+-s "$1"})
DEST=/sdcard/Android/data/com.akshayrana.video_music_app/files/test_media
if [ ! -f "$OUT/ump_long.mp4" ]; then
  mkdir -p "$OUT"
  bash "$ROOT/scripts/gen_test_media.sh" "$OUT"
fi
"${ADB[@]}" shell mkdir -p "$DEST"
"${ADB[@]}" push "$OUT/." "$DEST/" >/dev/null
# Dirs/files created by adb are owned by `shell` (mode 770/660); let the app read them.
"${ADB[@]}" shell chmod -R a+rwX "${DEST%/files/test_media}"
"${ADB[@]}" shell ls "$DEST"
"${ADB[@]}" shell "touch $DEST/.ready && chmod a+r $DEST/.ready"
