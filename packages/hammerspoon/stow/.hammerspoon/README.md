# Hammerspoon Configuration

The window manager uses two modifier sets:

- `meh`: shift + control + option
- `hyper`: shift + control + option + command

## Managed regions and groups

The 5120x1440 display is divided into three fixed regions:

- left: 1280x1440
- center: 2560x1440
- right: 1280x1440

Each region contains an ordered stack of groups. A group contains one or two
windows. Two-window groups share their region using a persisted divider.

Shortcut | Action
---|---
meh + = | Save the current stack model
hyper + = | Load and restore the saved stack model
meh + U/I/O | Move the focused window into a new left/center/right group
hyper + U/I/O | Add the focused window to the active left/center/right group
hyper + P | Extract the focused window into its own group
option + U/O | Focus the previous/next group in the current region
option + H/L | Focus the member or active group to the west/east
hyper + H/L | Shrink/grow the focused member in a two-window group
hyper + 0 | Reset a two-window group to equal widths

Managed state is saved to `~/.hammerspoon/state/stacks.json` only when the save
hotkey is pressed. The file is loaded and restored only when the load hotkey is
pressed; Hammerspoon startup and reload do not touch it. Groups are restored by
application bundle ID. Window minimum widths are learned when an application
refuses a requested width and are included in the next manual save.

The older `modules/wm/persistence.lua` implementation is retained as reference
but is not loaded.
