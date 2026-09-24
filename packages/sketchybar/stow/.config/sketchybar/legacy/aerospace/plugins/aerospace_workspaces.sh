#!/bin/bash

for item in $(sketchybar --query bar | jq -r '.items[]' | grep '^space\.'); do
  sketchybar --remove "$item"
done

for sid in $(aerospace list-workspaces --all); do
  sketchybar --add item "space.$sid" left \
    --set "space.$sid" \
    icon="$sid" \
    label.drawing=off \
    background.color=0x40ffffff \
    background.corner_radius=5 \
    background.height=25 \
    click_script="aerospace workspace $sid" \
    script="$CONFIG_DIR/plugins/aerospace.sh $sid" \
    --subscribe "space.$sid" aerospace_workspace_change
done
