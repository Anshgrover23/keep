#!/bin/bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
killall Keep 2>/dev/null || true
xcodebuild -project Keep.xcodeproj -scheme Keep -configuration Debug -derivedDataPath build/DerivedData build
KEEP_GLASS_CYCLE=1 "$ROOT/build/DerivedData/Build/Products/Debug/Keep.app/Contents/MacOS/Keep" || true
SRC="$HOME/Library/Containers/app.keep.desktop/Data/Library/Application Support/KeepGlassCycle"
OUT="$ROOT/demo/out/glass-cycle-native"
mkdir -p "$OUT"
if ls "$SRC"/native-*.png >/dev/null 2>&1; then
  ffmpeg -y -framerate 30 -i "$SRC/native-%04d.png" -c:v libx264 -pix_fmt yuv420p -crf 16 -movflags +faststart "$OUT/keep-glass-native.mp4"
  cp "$SRC/native-0001.png" "$SRC/native-0120.png" "$SRC/native-0150.png" "$SRC/native-0180.png" "$SRC/native-0240.png" "$SRC/native-0300.png" "$OUT/"
  cp "$SRC/record-log.txt" "$OUT/" 2>/dev/null || true
fi
