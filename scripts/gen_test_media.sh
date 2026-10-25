#!/bin/bash
# Synthetic test media for device checks (requires ffmpeg).
# Videos: left half = ffmpeg testsrc, right half = flat grey whose luma is
# 16 + 7 * (floor(seconds) mod 30) (limited range), so a captured frame can be
# decoded back to the second it came from (modulo 30, tolerant to +/-3 levels). Audio: sine tones. Usage: gen_test_media.sh <dir>
set -e
cd "$1"
mk() { # name w h dur freq
  local hw=$(( $2 / 2 ))
  ffmpeg -hide_banner -loglevel error -y \
   -f lavfi -i "testsrc=duration=$4:size=${hw}x$3:rate=30" \
   -f lavfi -i "color=c=black:size=${hw}x$3:rate=30:duration=$4,format=yuv420p,geq=lum=16+7*mod(floor(T)\,30):cb=128:cr=128" \
   -f lavfi -i "sine=frequency=$5:duration=$4" \
   -filter_complex "[0:v][1:v]hstack,format=yuv420p[v]" -map "[v]" -map 2:a \
   -c:v libx264 -crf 12 -preset fast -c:a aac -b:a 128k -movflags +faststart -metadata title="$1" "$1.mp4"
}
mk ump_long 1280 720 120 440
mk ump_portrait 720 1280 30 550
mk ump_short 640 360 6 660
ffmpeg -hide_banner -loglevel error -y -f lavfi -i "sine=frequency=330:duration=180" -c:a libmp3lame -b:a 128k -metadata title="UMP Test Tone" -metadata artist="Synthetic" ump_tone.mp3
ffmpeg -hide_banner -loglevel error -y -f lavfi -i "sine=frequency=880:duration=20" -c:a libmp3lame -b:a 128k ump_short_tone.mp3
head -c 300000 /dev/urandom > ump_corrupt.mp4
