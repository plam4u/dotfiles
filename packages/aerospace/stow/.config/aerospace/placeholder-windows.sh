#!/bin/bash
set -euo pipefail

CONFIG_DIR="${HOME}/.config/aerospace"
CACHE_DIR="${HOME}/.cache/aerospace-placeholder-windows"
APP_DIR="${CACHE_DIR}/AeroSpace Placeholders.app"
CONTENTS_DIR="${APP_DIR}/Contents"
MACOS_DIR="${CONTENTS_DIR}/MacOS"
SOURCE="${CONFIG_DIR}/placeholder-windows.swift"
EXECUTABLE="${MACOS_DIR}/AeroSpacePlaceholders"
PLIST="${CONTENTS_DIR}/Info.plist"

mkdir -p "$MACOS_DIR"

if [ ! -x "$EXECUTABLE" ] || [ "$SOURCE" -nt "$EXECUTABLE" ]; then
  /usr/bin/swiftc -O -framework AppKit "$SOURCE" -o "$EXECUTABLE"
  /usr/bin/plutil -create xml1 "$PLIST"
  /usr/bin/plutil -insert CFBundleExecutable -string AeroSpacePlaceholders "$PLIST"
  /usr/bin/plutil -insert CFBundleIdentifier -string local.aerospace.placeholders "$PLIST"
  /usr/bin/plutil -insert CFBundleName -string 'AeroSpace Placeholders' "$PLIST"
  /usr/bin/plutil -insert CFBundlePackageType -string APPL "$PLIST"
  /usr/bin/plutil -insert LSUIElement -bool true "$PLIST"
  /usr/bin/codesign --force --sign - "$APP_DIR" >/dev/null 2>&1
fi

if /usr/bin/pgrep -f '/AeroSpacePlaceholders$' >/dev/null 2>&1; then
  exit 0
fi

/usr/bin/open -g "$APP_DIR"

# The three real windows are created at 25/50/25. Once AeroSpace adopts them,
# reinforce the wider center node. Existing gaps mean visible pixel sizes are
# slightly smaller than 1280/2560/1280, but the tiling ratio remains 1:2:1.
for _ in {1..20}; do
  windows="$(/opt/homebrew/bin/aerospace list-windows \
    --app-bundle-id local.aerospace.placeholders \
    --monitor all \
    --format '%{window-id}|%{window-title}' 2>/dev/null || true)"
  [ "$(printf '%s\n' "$windows" | grep -c '^' || true)" -ge 3 ] && break
  sleep 0.1
done

# No post-adoption move/resize commands are issued. They can normalize the
# widths or create nested containers. The native windows are born at the exact
# left/center/right frames, with short notification intervals between them.
