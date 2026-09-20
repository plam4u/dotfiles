#!/bin/bash
set -u

CONFIG_DIR="${CONFIG_DIR:-$HOME/.config/sketchybar}"
state="$HOME/.cache/adaptive-window-manager/display.json"
mode="laptop"

if [ -r "$state" ] && command -v jq >/dev/null 2>&1; then
  detected="$(jq -r '.mode // "laptop"' "$state" 2>/dev/null)"
  [ "$detected" = "ultrawide" ] && mode="ultrawide"
fi

"$CONFIG_DIR/layouts/$mode.sh"
