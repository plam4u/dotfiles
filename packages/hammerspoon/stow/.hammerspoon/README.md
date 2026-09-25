# Hammerspoon Configuration

The window manager uses two modifier sets:

- `meh`: shift + control + option
- `hyper`: shift + control + option + command

## Workspace groups and display profiles

Workspaces belong to stable, named groups. The default groups are:

- left
- center
- right

On the 5120x1440 ultrawide the groups occupy 25%, 50%, and 25% of the display.
On the built-in display all groups share the main frame, and only one workspace
is raised at a time. Next/previous workspace navigation flows across group
boundaries. Group order and ultrawide weights live in `init.lua` and can be
changed at runtime.

Each group contains an ordered list of workspaces. A workspace contains one or
two windows. Two-window workspaces share their region using a persisted divider.
Empty restoration placeholders are retained internally but omitted from both
Stackline and SketchyBar.

Thin vertical segments sit three pixels from the top and left edges of each
region. Focusing a workspace briefly expands the relevant Stackline and shows
the group and application names. A blue border marks the focused workspace.

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
hyper + ,/. | Move the current workspace group earlier/later
hyper + [/] | Shrink/grow the current ultrawide group
hyper + M | Pause/resume all WM hotkeys and layout changes
option + M | Show SketchyBar and enter keyboard navigation
option + mouse wheel | Cycle live workspaces in the virtual-screen group under the pointer

Set `stacking.config.workspaceScrollDirection` to `standard` for wheel-up =
previous and wheel-down = next, or `natural` to reverse those directions.
`stacking.config.workspaceScrollThrottle` controls gesture rate limiting.

While SketchyBar navigation is active, use H/L or the arrow keys to move,
Return to invoke the primary action, Space to open an action menu, and Escape
to close the menu or leave navigation. The bar hides again on the ultrawide and
remains visible on the built-in display.
The first navigation session after Hammerspoon starts selects the rightmost
control item (`clock`), configurable through `sketchybar.initialSelectedItem`.
Later sessions restore the item selected when navigation last closed.
With the Volume item selected, Space toggles mute while J/K lower/raise volume;
these direct adjustments keep SketchyBar navigation open. Holding J/K repeats
the adjustment using the macOS keyboard-repeat delay and rate.
Invoking another WM hotkey exits SketchyBar navigation before running that
command, preventing the navigation modal from consuming subsequent typing.

`sketchybar.workspaceFocusStyle` controls the focused-workspace decoration.
Supported values are `background`, `border`, `underline`, `left_bar`, and
`text`; the default configuration uses `underline`.

Native-fullscreen windows are never moved, resized, parked, or raised by the
WM. The rest of the manager remains active unless it is explicitly paused with
`hyper + M`.

The WM starts JankyBorders' `borders` process during setup if it is not already
running, and checks it again whenever the WM is resumed with `hyper + M`.

Managed state is saved to `~/.hammerspoon/state/stacks.json` only when the save
hotkey is pressed. Hammerspoon restores that snapshot once during startup or
reload; the load hotkey can reapply it later. Workspaces are restored by application
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
