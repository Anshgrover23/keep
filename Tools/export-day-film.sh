#!/bin/zsh
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

# xcodebuild only forwards TEST_RUNNER_* into the Keep test host.
# Frames are written in the app sandbox tmp, then this script copies them out.
export TEST_RUNNER_KEEP_DAY_FILM=1
export TEST_RUNNER_KEEP_DAY_FILM_STRIDE="${KEEP_DAY_FILM_STRIDE:-10}"

LOG="$(mktemp)"
xcodebuild -project Keep.xcodeproj -scheme Keep -configuration Debug \
  -derivedDataPath build/DerivedData \
  -destination 'platform=macOS' \
  -only-testing:KeepTests/DayFilmTests \
  test 2>&1 | tee "$LOG"

WROTE="$(/usr/bin/grep -o 'KEEP_DAY_FILM_WROTE=[^[:space:]]*' "$LOG" | /usr/bin/head -1 | /usr/bin/cut -d= -f2-)"
FALLBACK="$HOME/Library/Containers/app.keep.desktop/Data/tmp/keep-day-film"
if [[ -z "$WROTE" || ! -d "$WROTE" ]]; then
  WROTE="$FALLBACK"
fi
if ! /bin/ls "$WROTE"/frame-*.png >/dev/null 2>&1; then
  echo "No PNG frames. Looked at: ${WROTE:-none}" >&2
  echo "Run this script, not a bare xcodebuild test." >&2
  exit 1
fi

DEST="${KEEP_DAY_FILM_OUT:-$HOME/Desktop/Keep-day-film}"
mkdir -p "$DEST"
find "$DEST" -maxdepth 1 \( -name 'frame-*.png' -o -name 'hero-*.png' -o -name 'day.mp4' \) -delete
/bin/cp "$WROTE"/*.png "$DEST"/
COUNT="$(/bin/ls -1 "$DEST"/frame-*.png | /usr/bin/wc -l | /usr/bin/tr -d ' ')"
echo "Copied $COUNT PNG frames to $DEST"
/usr/bin/open "$DEST"

if command -v ffmpeg >/dev/null 2>&1; then
  ffmpeg -y -framerate 24 -i "$DEST/frame-%04d.png" \
    -c:v libx264 -pix_fmt yuv420p -crf 18 "$DEST/day.mp4"
  echo "MP4 at $DEST/day.mp4"
else
  echo "ffmpeg not found. PNGs are on the Desktop. For MP4:"
  echo "ffmpeg -y -framerate 24 -i \"$DEST/frame-%04d.png\" -c:v libx264 -pix_fmt yuv420p -crf 18 \"$DEST/day.mp4\""
fi
