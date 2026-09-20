#!/bin/bash
set -u

workspace="${AEROSPACE_FOCUSED_WORKSPACE:-}"
[ -n "$workspace" ] || exit 0

if command -v sketchybar >/dev/null 2>&1; then
  sketchybar --trigger aerospace_workspace_change FOCUSED_WORKSPACE="$workspace" >/dev/null 2>&1 || true
fi
/usr/bin/open -g "hammerspoon://aerospace-workspace-changed?workspace=${workspace}" >/dev/null 2>&1 || true
