#!/usr/bin/env bash

coproc CODEX_SERVER {
  codex app-server --stdio 2>/dev/null
}

# 1. Initialize.
printf '%s\n' \
  '{"method":"initialize","id":1,"params":{"clientInfo":{"name":"sketchybar-codex-usage","title":"SketchyBar Codex Usage","version":"1.0"},"capabilities":{"experimentalApi":true}}}' \
  >&"${CODEX_SERVER[1]}"

# Wait for the initialize response.
while IFS= read -r line <&"${CODEX_SERVER[0]}"; do
  if jq -e '.id == 1' >/dev/null 2>&1 <<<"$line"; then
    break
  fi
done

# 2. Finish the handshake.
printf '%s\n' \
  '{"method":"initialized"}' \
  >&"${CODEX_SERVER[1]}"

# 3. Request current rate limits.
printf '%s\n' \
  '{"method":"account/rateLimits/read","id":2}' \
  >&"${CODEX_SERVER[1]}"

response=""

while IFS= read -r line <&"${CODEX_SERVER[0]}"; do
  if jq -e '.id == 2' >/dev/null 2>&1 <<<"$line"; then
    response="$line"
    break
  fi
done

# We have what we need; terminate the ephemeral app server.
kill "$CODEX_SERVER_PID" 2>/dev/null

if [[ -z "$response" ]]; then
  sketchybar --set "$NAME" label="Codex ?"
  exit 0
fi

usage=$(
  jq -r '
    if .result.rateLimits == null then
      empty
    else
      .result.rateLimits
      | [.primary, .secondary]
      | map(select(. != null))
      | [
          (
            map(
              select(
                .windowDurationMins >= 290
                and .windowDurationMins <= 310
              )
            )
            | first
            | .usedPercent // ""
          ),
          (
            map(
              select(
                .windowDurationMins >= 10000
                and .windowDurationMins <= 10100
              )
            )
            | first
            | .usedPercent // ""
          )
        ]
      | @tsv
    end
  ' <<<"$response"
)

if [[ -z "$usage" ]]; then
  sketchybar --set "$NAME" label="Codex ?"
  exit 0
fi

IFS=$'\t' read -r five_used weekly_used <<<"$usage"

five_left=""
weekly_left=""

if [[ -n "$five_used" ]]; then
  five_left=$(awk -v n="$five_used" 'BEGIN { printf "%.0f", 100 - n }')
fi

if [[ -n "$weekly_used" ]]; then
  weekly_left=$(awk -v n="$weekly_used" 'BEGIN { printf "%.0f", 100 - n }')
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
