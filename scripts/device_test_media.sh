#!/bin/bash
# Generates synthetic test media (if needed) and copies it into the installed
# debug app's private files dir (/data/user/0/<pkg>/files/test_media) through
# run-as. Shared storage is not used: on Android 16, files adb creates under
# Android/data/<pkg> are owned by the shell user and the app cannot read them.
# Needs a debuggable build installed. Usage: scripts/device_test_media.sh [device-id]
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
OUT="$ROOT/build/test_media"
ADB=(adb ${1:+-s "$1"})
PKG=com.akshayrana.video_music_app
if [ ! -f "$OUT/ump_long.mp4" ]; then
  mkdir -p "$OUT"
  bash "$ROOT/scripts/gen_test_media.sh" "$OUT"
fi
"${ADB[@]}" shell "run-as $PKG mkdir -p files/test_media"
for f in "$OUT"/ump_*; do
  name="$(basename "$f")"
  "${ADB[@]}" exec-in run-as "$PKG" sh -c "cat > files/test_media/$name" < "$f"
done
# Written last: the tests wait for it before loading media.
"${ADB[@]}" shell "run-as $PKG touch files/test_media/.ready"
"${ADB[@]}" shell "run-as $PKG ls files/test_media"
