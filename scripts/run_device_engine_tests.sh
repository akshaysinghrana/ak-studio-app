#!/bin/bash
# Runs on-device integration tests on a physical Android device.
# `flutter test` reinstalls the app for each test file (wiping its storage), so
# test media is pushed once the package is installed; tests wait for .ready.
# Usage: scripts/run_device_engine_tests.sh <device-id> [test-file.dart ...]
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DEVICE="$1"
shift
PKG=com.akshayrana.video_music_app
cd "$ROOT"
# Keep the screen on for the run (any power source; some phones report a USB
# cable as AC, so "stayon usb" is not enough) and restore the user's setting.
STAY_ON="$(adb -s "$DEVICE" shell settings get global stay_on_while_plugged_in | tr -d '\r')"
adb -s "$DEVICE" shell svc power stayon true
trap 'adb -s "$DEVICE" shell settings put global stay_on_while_plugged_in "${STAY_ON:-0}"' EXIT
FILES=("$@")
if [ ${#FILES[@]} -eq 0 ]; then
  # library_test.dart needs MediaStore setup: scripts/run_device_library_test.sh
  FILES=(engine_test.dart zoom_test.dart)
fi
STATUS=0
for f in "${FILES[@]}"; do
  echo "[runner] $f"
  adb -s "$DEVICE" uninstall "$PKG" >/dev/null 2>&1 || true
  (
    until adb -s "$DEVICE" shell pm path "$PKG" >/dev/null 2>&1; do sleep 1; done
    sleep 2
    "$ROOT/scripts/device_test_media.sh" "$DEVICE" >/dev/null
    echo "[runner] test media pushed"
  ) &
  flutter test "integration_test/$f" -d "$DEVICE" || STATUS=1
  wait
done
exit $STATUS
