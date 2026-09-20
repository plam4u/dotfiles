#!/bin/bash
set -u

window_id="${AEROSPACE_WINDOW_ID:-}"
[ -n "$window_id" ] || exit 0

/usr/bin/open -g "hammerspoon://aerospace-window-detected?window_id=${window_id}" >/dev/null 2>&1 || true
