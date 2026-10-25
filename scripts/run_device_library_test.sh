#!/bin/bash
# Runs integration_test/library_test.dart against the real MediaStore.
# Places synthetic media in Movies/UMP_Test and Music/UMP_Test, grants the
# test build READ_MEDIA_VIDEO/AUDIO, and removes the files and their
# MediaStore rows afterwards (also on failure).
# Usage: scripts/run_device_library_test.sh <device-id>
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DEVICE="$1"
PKG=com.akshayrana.video_music_app
ADB=(adb -s "$DEVICE")
OUT="$ROOT/build/test_media"
cd "$ROOT"
[ -f "$OUT/ump_long.mp4" ] || { mkdir -p "$OUT"; bash scripts/gen_test_media.sh "$OUT"; }

# Playback checks need the app in the foreground, so wait for an unlock.
for i in $(seq 1 100); do
  "${ADB[@]}" shell "dumpsys window | grep -q 'isKeyguardShowing=false'" && break
  [ "$i" = 1 ] && echo "[runner] >>> unlock the phone to continue (waiting up to 5 min)"
  sleep 3
done

scan() { "${ADB[@]}" shell content call --uri content://media --method scan_volume --arg external_primary >/dev/null 2>&1 || true; }
cleanup() {
  "${ADB[@]}" shell rm -rf /sdcard/Movies/UMP_Test /sdcard/Music/UMP_Test
  scan
  echo "[runner] test media removed from shared storage"
}
trap cleanup EXIT

"${ADB[@]}" shell mkdir -p /sdcard/Movies/UMP_Test /sdcard/Music/UMP_Test
"${ADB[@]}" push "$OUT/ump_long.mp4" "$OUT/ump_portrait.mp4" /sdcard/Movies/UMP_Test/ >/dev/null
"${ADB[@]}" push "$OUT/ump_tone.mp3" /sdcard/Music/UMP_Test/ >/dev/null
scan

"${ADB[@]}" uninstall "$PKG" >/dev/null 2>&1 || true
(
  until "${ADB[@]}" shell pm path "$PKG" >/dev/null 2>&1; do sleep 0.5; done
  "${ADB[@]}" shell pm grant "$PKG" android.permission.READ_MEDIA_VIDEO
  "${ADB[@]}" shell pm grant "$PKG" android.permission.READ_MEDIA_AUDIO
  echo "[runner] media permissions granted"
) &
flutter test integration_test/library_test.dart -d "$DEVICE"
