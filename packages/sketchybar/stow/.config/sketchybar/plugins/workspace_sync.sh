#!/usr/bin/env bash

state_file="${HOME}/.hammerspoon/state/sketchybar.json"

[[ -r "$state_file" ]] || exit 0

existing_items="$(sketchybar --query bar | jq -r '.items[] | select(test("^wm\\.group\\.") or test("^wm\\.[^.]+\\.[0-9]+$"))')"
while IFS= read -r item; do
  [[ -n "$item" ]] && sketchybar --remove "$item"
done <<< "$existing_items"

collapsed="$(jq -r '.collapsed' "$state_file")"
suspended="$(jq -r '.suspended' "$state_file")"
selected="$(jq -r '.navigation.selected // ""' "$state_file")"
focus_style="$(jq -r '.navigation.focusStyle // "underline"' "$state_file")"
group_count="$(jq '[.groups[] | select((.workspaces | length) > 0)] | length' "$state_file")"
group_number=0

while IFS=$'\t' read -r group_id group_active; do
  [[ -n "$group_id" ]] || continue
  group_number=$((group_number + 1))

  if [[ "$collapsed" == "true" || "$group_number" -eq 1 ]]; then
    position="left"
  elif [[ "$group_number" -eq "$group_count" ]]; then
    position="right"
  else
    position="center"
  fi

  workspace_filter='.groups[] | select(.id == $group) | .workspaces[]'
  if [[ "$position" == "right" ]]; then
    # SketchyBar lays right-positioned items out in reverse insertion order.
    workspace_filter='.groups[] | select(.id == $group) | .workspaces | reverse[]'
  fi

  while IFS=$'\t' read -r workspace_index workspace_name active; do
    [[ -n "$workspace_index" ]] || continue
    item="wm.${group_id}.${workspace_index}"
    focused=false
    [[ "$selected" == "$item" ]] && focused=true
    [[ -z "$selected" && "$group_active" == "true" && "$active" == "true" ]] && focused=true

    style=(
      icon.drawing=off
      background.color=0x00000000
      background.border_width=0
      background.height=28
      background.corner_radius=7
      background.y_offset=0
      background.drawing=off
    )
    if [[ "$focused" == "true" ]]; then
      case "$focus_style" in
        background)
          style+=(background.color=0xff3b82f6 background.drawing=on)
          ;;
        border)
          style+=(background.color=0x00000000 background.border_color=0xff3b82f6 background.border_width=2 background.drawing=on)
          ;;
        left_bar)
          style+=(icon=▎ icon.drawing=on icon.color=0xff3b82f6)
          ;;
        text)
          style+=(label.color=0xff60a5fa)
          ;;
        *)
          style+=(background.color=0xff3b82f6 background.height=3 background.corner_radius=2 background.y_offset=-12 background.drawing=on)
          ;;
      esac
    fi

    sketchybar --add item "$item" "$position" \
      --set "$item" \
        icon.drawing=off \
        label="${workspace_index} ${workspace_name}" \
        label.max_chars=24 \
        label.color="$([[ "$suspended" == "true" ]] && printf '0x66ffffff' || printf '0xffffffff')" \
        background.border_color=0xff93c5fd \
        "${style[@]}" \
        click_script="${CONFIG_DIR}/plugins/workspace_click.sh ${group_id} ${workspace_index}"
  done < <(jq -r --arg group "$group_id" "${workspace_filter} | [.index, .name, .active] | @tsv" "$state_file")
done < <(jq -r '.groups[] | select((.workspaces | length) > 0) | [.id, .active] | @tsv' "$state_file")

for item in front_app clock volume battery codex; do
  if [[ "$selected" == "$item" ]]; then
    sketchybar --set "$item" background.drawing=on background.color=0xff3b82f6 background.corner_radius=7 background.height=28
  else
    sketchybar --set "$item" background.drawing=off
  fi
done
