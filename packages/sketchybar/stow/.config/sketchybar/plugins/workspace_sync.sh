#!/usr/bin/env bash

CONFIG_DIR="${CONFIG_DIR:-${HOME}/.config/sketchybar}"
state_file="${HOME}/.hammerspoon/state/sketchybar.json"
[[ -r "$state_file" ]] || exit 0

collapsed="$(jq -r '.collapsed' "$state_file")"
suspended="$(jq -r '.suspended' "$state_file")"
selected="$(jq -r '.navigation.selected // ""' "$state_file")"
focus_style="$(jq -r '.navigation.focusStyle // "underline"' "$state_file")"
display_mode="$(jq -r '.workspaceDisplayMode // "icon"' "$state_file")"
active_label="$(jq -r '.workspaceActiveLabel // true' "$state_file")"
group_separator="$(jq -r '.workspaceGroupSeparator // ">"' "$state_file")"
group_separator_gap="$(jq -r '.workspaceGroupSeparatorGap // 4' "$state_file")"
workspace_icon_width="$(jq -r '.workspaceIconWidth // 23' "$state_file")"
workspace_icon_offset="$(jq -r '.workspaceIconOffset // 0' "$state_file")"
workspace_focus_inset="$(jq -r '.workspaceFocusInset // 0' "$state_file")"
workspace_label_gap="$(jq -r '.workspaceLabelGap // 0' "$state_file")"
workspace_label_character_width="$(jq -r '.workspaceLabelCharacterWidth // 9' "$state_file")"
workspace_label_extra_width="$(jq -r '.workspaceLabelExtraWidth // 0' "$state_file")"
workspace_icon_content_width=$((workspace_icon_width - (workspace_focus_inset * 2)))
(( workspace_icon_content_width < 1 )) && workspace_icon_content_width=1
[[ "$display_mode" == "icon+label" ]] && display_mode="icon_label"

workspace_pattern='^wm\.(group\.|label\.|[^.]+\.[0-9]+$)'
existing_items="$(sketchybar --query bar | jq -r --arg pattern "$workspace_pattern" '.items[] | select(test($pattern))')"

desired_items="$(jq -r '
  .groups[] |
  "wm.group.\(.id)",
  (.id as $group | .workspaces[] | "wm.\($group).\(.index)", "wm.label.\($group).\(.index)")
' "$state_file")"

while IFS= read -r item; do
  [[ -n "$item" ]] || continue
  if ! grep -Fqx "$item" <<< "$desired_items"; then
    sketchybar --remove "$item"
  fi
done <<< "$existing_items"

group_number=0
left_order=(front_app)
center_order=()

while IFS=$'\t' read -r group_id group_active; do
  [[ -n "$group_id" ]] || continue
  group_number=$((group_number + 1))

  if [[ "$collapsed" == "true" ]]; then
    position="left"
  else
    position="center"
  fi

  marker="wm.group.${group_id}"
  if ! grep -Fqx "$marker" <<< "$existing_items"; then
    sketchybar --add item "$marker" "$position"
  fi
  if [[ "$group_number" -eq 1 || -z "$group_separator" ]]; then
    sketchybar --set "$marker" position="$position" drawing=off width=0
  else
    sketchybar --set "$marker" \
      position="$position" drawing=on width=dynamic padding_left="$group_separator_gap" padding_right="$group_separator_gap" \
      icon="$group_separator" icon.drawing=on icon.width=dynamic icon.align=center icon.color=0x99ffffff \
      icon.font.size=18 icon.padding_left=0 icon.padding_right=0 label.drawing=off background.drawing=off
  fi
  if [[ "$collapsed" == "true" ]]; then
    left_order+=("$marker")
  else
    center_order+=("$marker")
  fi

  workspace_filter='.groups[] | select(.id == $group) | .workspaces[]'

  while IFS=$'\t' read -r workspace_index workspace_name bundle_id active; do
    [[ -n "$workspace_index" ]] || continue
    item="wm.${group_id}.${workspace_index}"
    label_item="wm.label.${group_id}.${workspace_index}"
    focused=false
    is_active=false
    [[ "$selected" == "$item" ]] && focused=true
    [[ "$group_active" == "true" && "$active" == "true" ]] && is_active=true
    [[ -z "$selected" && "$is_active" == "true" ]] && focused=true

    if ! grep -Fqx "$item" <<< "$existing_items"; then
      sketchybar --add item "$item" "$position"
    fi
    if ! grep -Fqx "$label_item" <<< "$existing_items"; then
      sketchybar --add item "$label_item" "$position"
    fi

    content=(
      position="$position" width="$workspace_icon_width" padding_left=0 padding_right=0
      icon=" " icon.drawing=on icon.width="$workspace_icon_content_width" icon.align=center
      icon.padding_left="$workspace_focus_inset" icon.padding_right="$workspace_focus_inset" label.drawing=off
      icon.background.drawing=off label.background.drawing=off
      background.drawing=on background.color=0x00000000 background.height=28 background.corner_radius=7
      background.image.drawing=off background.image.padding_left="$workspace_icon_offset" background.image.padding_right="-$workspace_icon_offset"
    )
    if [[ "$display_mode" == "label" ]]; then
      content+=(width=dynamic icon.drawing=off label.drawing=on label="${workspace_index} ${workspace_name}" label.max_chars=0)
    elif [[ -n "$bundle_id" ]]; then
      content+=(background.image="app.${bundle_id}" background.image.drawing=on background.image.scale=0.72)
    else
      content+=(icon="$workspace_index")
    fi

    style=(background.border_width=0)
    if [[ "$focused" == "true" ]]; then
      case "$focus_style" in
        background) style+=(background.color=0xff3b82f6) ;;
        text) style+=(label.color=0xff60a5fa) ;;
        *)
          if [[ "$display_mode" == "label" ]]; then
            style+=(label.background.color=0xff3b82f6 label.background.height=3 label.background.corner_radius=0 label.background.y_offset=-12 label.background.drawing=on)
          else
            style+=(icon.background.color=0xff3b82f6 icon.background.height=3 icon.background.corner_radius=0 icon.background.y_offset=-12 icon.background.drawing=on)
          fi
          ;;
      esac
    fi

    sketchybar --set "$item" \
      "${content[@]}" "${style[@]}" \
      label.color="$([[ "$suspended" == "true" ]] && printf '0x66ffffff' || printf '0xffffffff')" \
      click_script="${CONFIG_DIR}/plugins/workspace_click.sh ${group_id} ${workspace_index}"

    show_label=false
    if [[ "$display_mode" == "icon_label" || ("$display_mode" == "icon" && "$active_label" == "true" && "$is_active" == "true") ]]; then
      show_label=true
    fi
    label_gap=0
    [[ "$show_label" == "true" ]] && label_gap="$workspace_label_gap"
    label_width=0
    if [[ "$show_label" == "true" ]]; then
      label_width=$((${#workspace_name} * workspace_label_character_width + workspace_label_extra_width))
    fi
    label_focused=false
    [[ "$show_label" == "true" && "$focused" == "true" ]] && label_focused=true
    sketchybar --set "$label_item" \
      position="$position" width="$label_width" padding_left=0 padding_right="$label_gap" icon.drawing=off \
      label.width="$label_width" \
      label.drawing=on label="${workspace_name}" label.max_chars=0 label.align=center \
      label.padding_left=0 label.padding_right=0 \
      background.drawing=off \
      label.background.color=0xff3b82f6 label.background.height=3 label.background.corner_radius=0 \
      label.background.y_offset=-12 label.background.drawing="$([[ "$label_focused" == "true" ]] && printf 'on' || printf 'off')" \
      click_script="${CONFIG_DIR}/plugins/workspace_click.sh ${group_id} ${workspace_index}"
    if [[ "$display_mode" == "label" ]]; then
      sketchybar --set "$label_item" drawing=off label.width=0
    else
      sketchybar --set "$label_item" drawing=on
    fi

    if [[ "$collapsed" == "true" ]]; then
      left_order+=("$item" "$label_item")
    else
      center_order+=("$item" "$label_item")
    fi
  done < <(jq -r --arg group "$group_id" "${workspace_filter} | [.index, .name, (.members[0].bundleID // \"\"), .active] | @tsv" "$state_file")
done < <(jq -r '.groups[] | select((.workspaces | length) > 0) | [.id, .active] | @tsv' "$state_file")

if [[ "$collapsed" == "true" && "${#left_order[@]}" -gt 1 ]]; then
  sketchybar --reorder "${left_order[@]}"
elif [[ "${#center_order[@]}" -gt 0 ]]; then
  sketchybar --reorder "${center_order[@]}"
fi

static_items=(front_app)
while IFS= read -r item; do
  [[ -n "$item" ]] && static_items+=("$item")
done < <(jq -r '.rightItemOrder[]?' "$state_file")

for item in "${static_items[@]}"; do
  if [[ "$selected" == "$item" ]]; then
    sketchybar --set "$item" background.drawing=on background.color=0xff3b82f6 background.corner_radius=7 background.height=28
  else
    sketchybar --set "$item" background.drawing=off
  fi
done
