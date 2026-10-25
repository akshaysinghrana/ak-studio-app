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
FILES=("$@")
if [ ${#FILES[@]} -eq 0 ]; then
  FILES=($(cd integration_test && ls *_test.dart))
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
