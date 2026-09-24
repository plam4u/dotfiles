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

Thin vertical segments sit three pixels from the top and left edges of each
region. Focusing a group briefly expands every segment in that region into an
opaque label with its application names. A blue border marks the focused group.

Shortcut | Action
---|---
meh + = | Save the current stack model
hyper + = | Load and restore the saved stack model
meh + U/I/O | Move the focused window into a new left/center/right group
hyper + U/I/O | Add the focused window to the active left/center/right group
hyper + P | Extract the focused window into its own group
option + H/L | Navigate west/east through group members and regions, then fall back to geometric navigation
option + J/K | Focus the next/previous group, or navigate south/north when there is no other live group
option + shift + K/J | Move the active workspace earlier/later without moving its windows
option + I/, | Always navigate north/south geometrically
hyper + H/L | Shrink/grow the focused member in a two-window group
hyper + ; | Reset a two-window group to equal widths

Managed state is saved to `~/.hammerspoon/state/stacks.json` only when the save
hotkey is pressed. Hammerspoon restores that snapshot once during startup or
reload; the load hotkey can reapply it later. Groups are restored by application
bundle ID. Window minimum widths are learned when an application refuses a
requested width and are included in the next manual save.

When a second window joins a group, its current width is preserved when the
region and both applications' minimum widths allow it. Use `hyper + ;` to opt
into an equal split.

After a reload, saving an empty model is blocked when a snapshot already
exists. A non-empty setup can always be saved, while the guard prevents an
accidental empty snapshot from erasing the saved groups.

The older `modules/wm/persistence.lua` implementation is retained as reference
but is not loaded.

## Configuration reloads

`reload.lua` uses `hs.pathwatcher` directly rather than
`ReloadConfiguration.spoon`. By default, changes to `.lua` and `.json` files
reload Hammerspoon, while everything below `state/` is ignored. Configure the
behavior in `init.lua` with `includeSuffixes` and relative `excludePaths`.
