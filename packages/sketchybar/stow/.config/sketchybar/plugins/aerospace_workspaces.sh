#!/bin/bash

focused="$(aerospace list-workspaces --focused 2>/dev/null)"
active="$(aerospace list-workspaces --monitor all --empty no 2>/dev/null)"
workspace_order=(1 2 3 4 5 6 7 8 9 Q W E R T Y U I O P A S D F G H J K L Z X C V B N M)

sketchybar --query bar | jq -r '.items[]' | grep '^space\.' | while read -r item; do
  sketchybar --remove "$item"
done

for sid in "${workspace_order[@]}"; do
  if echo "$active" | grep -qx "$sid"; then
    drawing=off; [ "$sid" = "$focused" ] && drawing=on
    sketchybar --add item "space.$sid" left \
      --set "space.$sid" icon.drawing=off label="$sid" label.font="SF Pro:Semibold:14.0" \
        label.align=center label.width=30 label.padding_left=0 label.padding_right=0 \
        background.color=0x40ffffff background.corner_radius=8 background.height=30 \
        background.drawing="$drawing" click_script="aerospace workspace $sid" \
        script="$CONFIG_DIR/plugins/aerospace.sh $sid" \
      --subscribe "space.$sid" aerospace_workspace_change
  fi
done
