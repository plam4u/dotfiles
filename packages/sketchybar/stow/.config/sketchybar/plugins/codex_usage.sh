#!/usr/bin/env bash

# SketchyBar may be launched without the interactive zsh PATH.
status_bin="${HOME}/dotfiles/packages/codex/bin/codex_status"
if ! details=$("$status_bin"); then
  sketchybar --set "$NAME" label="Codex ?"
  exit 0
fi

state_dir="$HOME/Library/Caches/SketchyBar"
mkdir -p "$state_dir"
state_file=$(mktemp "$state_dir/.codex_usage.XXXXXX")
printf '%s\n' "$details" >"$state_file"
mv "$state_file" "$state_dir/codex_usage.json"

label=$(jq -r '
  .fiveHour.remainingPercent as $five
  | .weekly.remainingPercent as $weekly
  | if $five != null and $weekly != null then
      "\($five | round)% \($weekly | round)%"
    elif $five != null then "5h \($five | round)%"
    elif $weekly != null then "W \($weekly | round)%"
    else "?" end
' <<<"$details")

sketchybar --set "$NAME" label="$label"
