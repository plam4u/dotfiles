# AeroSpace placeholder windows

`placeholder-windows.sh` builds and launches a tiny local AppKit application
containing three standard windows. Unlike Hammerspoon canvases, these windows
are visible to AeroSpace and participate in its tiling tree.

The application uses bundle id `local.aerospace.placeholders`, runs as an
accessory app so it is absent from Cmd-Tab, and exits when all placeholders are
closed. AeroSpace starts it automatically. To launch it manually:

```sh
~/.config/aerospace/placeholder-windows.sh
```

To close every placeholder:

```sh
pkill -x AeroSpacePlaceholders
```

The windows are created left/center/right at their final coordinates, with a
short synchronous notification interval between creations. No later AeroSpace
move command is used because that can introduce nested containers. For
`LG HDR DQHD`, AeroSpace gaps are zeroed using per-monitor gap rules. The
original 2/4-pixel gaps remain active on every other monitor.
