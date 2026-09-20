# Adaptive AeroSpace + Hammerspoon + SketchyBar

## Architecture

- AeroSpace owns workspaces, focus, movement, and normal laptop tiling.
- Its `on-window-detected` callback sends the detected `AEROSPACE_WINDOW_ID`
  to Hammerspoon through a background `hammerspoon://` URL.
- Hammerspoon identifies the window with the same macOS window id, resolves
  its actual AeroSpace workspace, and uses `hs.screen:frame()` for usable
  geometry (so menu bar, SketchyBar, Dock, and screen origin are respected).
- Exact regions float and are positioned by Hammerspoon. Preset `9` returns
  the window to AeroSpace tiling. No placeholder windows are used.
- AeroSpace's workspace callback triggers both the registered SketchyBar
  event and Hammerspoon restoration.

## Display detection

`window_manager/config.lua` defines the external mode as 5120x1440. The
observed display name, `LG HDR DQHD`, is also checked as a configurable pattern
for scaled modes. The current result and observed display metadata are cached
at `~/.cache/adaptive-window-manager/display.json`. Unknown modes fail safe to
laptop behavior. Update `namePatterns` if the monitor is renamed or replaced.

## Placement UI

The first window in an ultrawide workspace is automatically placed in the
center 50%. Later windows open the overlay.

Window counts exclude AeroSpace's `macos_native_window_of_hidden_app` entries.
The focused workspace is reconciled on Hammerspoon reload, display changes,
and workspace changes, so an already-open single window is also centered.
The side quarters are real empty screen space; placeholder processes are not
created because floating geometry preserves the same 25/50/25 result cleanly.

- Arrow keys: move the selection by one cell.
- Shift + arrows: shrink/expand the selection.
- 1/2/3: left 25%, center 50%, right 25%.
- 4/5: left/right 50%.
- 6/7: left/right 75%.
- 8: full usable frame, Hammerspoon-managed.
- 9: hand the workspace back to AeroSpace tiling. Existing custom floating
  assignments in that workspace are tiled too, preventing overlap.
- Return: commit. Escape: cancel.
- Ctrl+Alt+Cmd+P: place the focused window manually.
- Clicking a grid cell selects that cell; Return commits it.

Regions are declarative in `window_manager/regions.lua`. The base grid is 4x2
and can be changed in `window_manager/config.lua`.

## Persistence and manual moves

Assignments are stored in `hs.settings`. They are reapplied on workspace and
display changes and cleaned up when windows disappear. If a user manually
moves/resizes an assigned window by more than 24 total points, Hammerspoon
releases that assignment instead of fighting the user.

While placement is open, the pending window is temporarily floated and raised
without taking keyboard focus. Escape restores its original tiled state (or
preserves an app rule that already made it floating).

## Debugging

Set `debug = true` in `window_manager/config.lua`, reload Hammerspoon, and open
the Hammerspoon Console. Useful commands:

```sh
aerospace list-monitors --json
aerospace list-windows --all --json
aerospace list-exec-env-vars
cat ~/.cache/adaptive-window-manager/display.json
sketchybar --query bar
```

## Disable / revert

Remove/comment `require("window_manager").start()` in Hammerspoon, remove the
final catch-all `on-window-detected` entry in `.aerospace.toml`, and restore
the direct SketchyBar workspace callback if desired. Timestamped originals are
under each package's `backups/20260920-1925/` directory.

## Limitations

- Hammerspoon can only resolve windows in accessible/current macOS Spaces.
- Rapid windows are queued independently; a later overlay replaces an earlier
  unfinished overlay rather than stacking dialogs.
- GUI scenarios require the apps and displays to be active. Static syntax and
  config checks can run headlessly, but the full laptop/LG checklist must be
  exercised on the corresponding physical display.

## Manual acceptance checklist

On the laptop, verify that creating windows stays tiled, the overlay never
appears, workspace navigation/moves retain their existing keys, and workspace
highlighting follows focus. On the LG, verify first-window center placement;
second-window overlay choices 1-9; arrow movement and Shift-arrow resizing;
Return/Escape; three-window left/center/right placement; workspace leave/return;
moving and closing assigned windows; multiple rapid windows; reloading each
app; and both display transitions. The display-state JSON and Hammerspoon
Console should identify any failure point without enabling continuous polling.
