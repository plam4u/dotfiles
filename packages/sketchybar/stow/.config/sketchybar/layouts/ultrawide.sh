#!/bin/bash
# The physical bar remains transparent/full-width. Outer spacer items consume
# 25% of the actual usable width, leaving the visual content in the center 50%.
state="$HOME/.cache/adaptive-window-manager/display.json"
quarter=1280
if [ -r "$state" ] && command -v jq >/dev/null 2>&1; then
  detected="$(jq -r '(.frame.w // 5120) / 4 | floor' "$state" 2>/dev/null)"
  case "$detected" in (*[!0-9]*|'') ;; (*) quarter="$detected" ;; esac
fi
sketchybar --bar position=top height=40 margin=0 y_offset=0 blur_radius=0 color=0x00000000
sketchybar --set adaptive.center.left drawing=on width="$quarter" \
           --set adaptive.center.right drawing=on width="$quarter"
