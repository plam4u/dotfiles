#!/usr/bin/env bash

item="$1"
action="${2:-}"

if [[ -n "$action" ]]; then
  /usr/bin/open -g "hammerspoon://wm-bar?command=action&item=${item}&action=${action}"
else
  /usr/bin/open -g "hammerspoon://wm-bar?command=click&item=${item}&button=${BUTTON:-left}"
fi
