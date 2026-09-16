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

if [[ -n "${KEEP_TAG:-}" ]]; then
  TAG="$KEEP_TAG"
  VER="${TAG#v}"
  URL="https://github.com/${REPO}/releases/download/${TAG}/Keep-${VER}.dmg"
else
  echo "Finding the latest published Keep release..."
  API="https://api.github.com/repos/${REPO}/releases/latest"
  JSON="$(curl -fsSL "$API")" || die "Could not read GitHub latest release. Publish the draft first."
  URL="$(printf '%s' "$JSON" | sed -n 's/.*"browser_download_url": "\([^"]*\.dmg\)".*/\1/p' | head -1)"
  [[ -n "$URL" ]] || die "Latest release has no DMG. Publish a draft that includes Keep-x.y.z.dmg."
fi

DMG="$TMP/Keep.dmg"
echo "Downloading $URL"
curl -fL --progress-bar "$URL" -o "$DMG" || die "Download failed."

MOUNT="$TMP/mnt"
mkdir -p "$MOUNT"
hdiutil attach -nobrowse -readonly -mountpoint "$MOUNT" "$DMG" >/dev/null \
  || die "Could not mount the disk image."
detach() {
  hdiutil detach "$MOUNT" >/dev/null 2>&1 || true
}
trap 'detach; rm -rf "$TMP"' EXIT

SRC="$MOUNT/$APP_NAME"
[[ -d "$SRC" ]] || die "The disk image does not contain $APP_NAME."

TARGET="$DEST/$APP_NAME"
if [[ -e "$TARGET" ]]; then
  echo "Replacing $TARGET"
  rm -rf "${DEST:?}/${APP_NAME:?}" || die "Could not remove the existing app. Quit Keep from the menu extra and try again."
fi

ditto "$SRC" "$TARGET" || die "Could not copy $APP_NAME to $DEST."
xattr -dr com.apple.quarantine "$TARGET" 2>/dev/null || true

detach
trap 'rm -rf "$TMP"' EXIT

echo "Installed $APP_NAME to $DEST."
echo "Opening Keep..."
open "$TARGET"
