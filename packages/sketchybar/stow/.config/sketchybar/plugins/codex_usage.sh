#!/usr/bin/env bash

# Find the most recently modified Codex session log.
latest=$(
  find "$HOME/.codex/sessions" -type f -name '*.jsonl' -print0 2>/dev/null |
    xargs -0 ls -t 2>/dev/null |
    head -1
)

if [[ -z "$latest" ]]; then
  sketchybar --set "$NAME" label="Codex ?"
  exit 0
fi

# Pick the newest token_count event that contains rate-limit data.
usage=$(
  jq -rs '
    [
      .[]
      | select(
          .type == "event_msg"
          and .payload.type == "token_count"
          and .payload.rate_limits != null
        )
      | .payload.rate_limits
    ]
    | last
  ' "$latest" 2>/dev/null
)

if [[ -z "$usage" || "$usage" == "null" ]]; then
  sketchybar --set "$NAME" label="Codex ?"
  exit 0
fi

# Identify the 5-hour and weekly windows by their duration rather
# than assuming primary/secondary always have the same meaning.
read -r five_used weekly_used < <(
  jq -r '
    [
      .primary,
      .secondary
    ]
    | map(select(. != null))
    | [
        (
          map(
            select(
              .window_minutes >= 290
              and .window_minutes <= 310
            )
          )
          | first
          | .used_percent // ""
        ),
        (
          map(
            select(.window_minutes >= 10000)
          )
          | first
          | .used_percent // ""
        )
      ]
    | @tsv
  ' <<<"$usage"
)

five_left=""
weekly_left=""

if [[ -n "$five_used" ]]; then
  five_left=$(
    awk -v n="$five_used" \
      'BEGIN { printf "%.0f", 100 - n }'
  )
fi

if [[ -n "$weekly_used" ]]; then
  weekly_left=$(
    awk -v n="$weekly_used" \
      'BEGIN { printf "%.0f", 100 - n }'
  )
fi

if [[ -n "$five_left" && -n "$weekly_left" ]]; then
  label="${five_left}% ${weekly_left}%"
elif [[ -n "$five_left" ]]; then
  label="5h ${five_left}%"
elif [[ -n "$weekly_left" ]]; then
  label="W ${weekly_left}%"
else
  label="?"
fi

sketchybar --set "$NAME" label="$label"
