#!/usr/bin/env bash
# Keep installer for macOS.
#
#   curl -fsSL https://raw.githubusercontent.com/Anshgrover23/keep/main/scripts/install.sh | bash
#
# Optional:
#   KEEP_TAG=v1.0.0  pin a GitHub Release tag
#   KEEP_REPO=Anshgrover23/keep
set -euo pipefail

REPO="${KEEP_REPO:-Anshgrover23/keep}"
APP_NAME="Keep.app"

die() {
  echo "keep install: $*" >&2
  exit 1
}

if [[ "$(uname -s)" != "Darwin" ]]; then
  die "Keep is a Mac app."
fi

if [[ "$(uname -m)" != "arm64" ]]; then
  die "This build is Apple Silicon only."
fi

major="$(sw_vers -productVersion | cut -d. -f1)"
if [[ "$major" -lt 14 ]]; then
  die "Keep needs macOS 14 or later."
fi

if [[ -w "/Applications" ]]; then
  DEST="/Applications"
else
  DEST="$HOME/Applications"
  mkdir -p "$DEST"
fi

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

asset_url() {
  local json="$1"
  local ext="$2"
  printf '%s' "$json" | sed -n "s/.*\"browser_download_url\": \"\\([^\"]*\\.${ext}\\)\".*/\\1/p" | head -1
}

if [[ -n "${KEEP_TAG:-}" ]]; then
  TAG="$KEEP_TAG"
  VER="${TAG#v}"
  URL="https://github.com/${REPO}/releases/download/${TAG}/Keep-${VER}.zip"
else
  echo "Finding the latest Keep release..."
  JSON="$(curl -fsSL --retry 5 --connect-timeout 15 --max-time 30 \
    "https://api.github.com/repos/${REPO}/releases/latest")" \
    || die "Could not read GitHub latest release."
  URL="$(asset_url "$JSON" zip)"
  [[ -n "$URL" ]] || die "Latest release has no zip."
fi

ZIP="$TMP/Keep.zip"
echo "Downloading Keep..."
curl -fL --retry 5 --retry-delay 2 --connect-timeout 15 --max-time 180 \
  --progress-bar -o "$ZIP" "$URL" \
  || die "Download failed."

echo "Installing to $DEST..."
ditto -x -k "$ZIP" "$TMP/unpacked" || die "Could not unpack Keep."
SRC="$TMP/unpacked/$APP_NAME"
[[ -d "$SRC" ]] || die "The archive does not contain $APP_NAME."

TARGET="$DEST/$APP_NAME"
if [[ -e "$TARGET" ]]; then
  echo "Replacing $TARGET"
  rm -rf "${DEST:?}/${APP_NAME:?}" || die "Could not remove the existing app. Quit Keep from the menu extra and try again."
fi

ditto "$SRC" "$TARGET" || die "Could not copy $APP_NAME to $DEST."
xattr -dr com.apple.quarantine "$TARGET" 2>/dev/null || true

echo "Installed $APP_NAME to $DEST."
echo "Opening Keep..."
open "$TARGET"
