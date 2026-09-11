#!/bin/bash

TARGET="$1"
CURRENT="$(aerospace list-workspaces --focused)"

if [ "$CURRENT" = "$TARGET" ]; then
  aerospace workspace-back-and-forth
else
  aerospace workspace "$TARGET"
fi
