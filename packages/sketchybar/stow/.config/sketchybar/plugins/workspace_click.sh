#!/usr/bin/env bash

group="$1"
index="$2"

/usr/bin/open -g "hammerspoon://wm-bar?command=workspace&group=${group}&index=${index}"
