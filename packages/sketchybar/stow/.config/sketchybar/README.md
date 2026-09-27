# SketchyBar

Hammerspoon owns workspace state and publishes
`~/.hammerspoon/state/sketchybar.json`. SketchyBar renders only live workspaces
and sends validated actions back through the `hammerspoon://wm-bar` URL handler.
Virtual-screen names are intentionally omitted; item placement and workspace
order preserve the grouping without spending bar space on labels.

- Ultrawide: hidden until `option + M` enters navigation mode.
- Built-in display: always visible. Compact workspace groups remain left-aligned
  and controls remain right-aligned; `sketchybar.notchWidth` controls the
  reserved center width.
- The first keyboard-navigation session after Hammerspoon starts selects the
  rightmost control item (`clock`); later sessions restore the last selection.
- `sketchybar.rightItemOrder` in Hammerspoon's `init.lua` defines the static
  controls from left to right for both display and keyboard navigation. It is
  reapplied automatically after `sketchybar --reload`.
- The Caffeine control reuses the Hammerspoon module's empty/filled coffee icon,
  shows `Off`/`On`, and stays synchronized with menubar clicks, its hotkey, and
  SketchyBar clicks. Space toggles it directly without opening a menu.
- Return invokes the selected item.
- Space opens the selected item's action menu.
- Selecting the Codex item shows its usage popup. J/K moves between the Codex
  item and the 5-hour, weekly, and manual-reset rows. Space on the 5-hour row
  toggles between an `in   HH:mm` countdown and percentage plus reset time. Space on the weekly row
  toggles between percentage plus reset date and `in` plus `today`, `1 day`, or `2–7 days`. The manual-reset row is
  read-only. Both rows initially show the `in` remaining-time view. Moving to
  another item or leaving navigation closes the popup.
- Selecting the Key Lights item opens its control popup. J/K
  selects all-power, then power, temperature, and brightness for the left and
  right lights. H/L adjusts temperature in 50 K steps and brightness in 5%
  steps, repeats while held, and otherwise keeps navigating the bar. Space or
  Return toggles power rows; on temperature and brightness it cycles through
  maximum, minimum, and the value captured when cycling began.
  Left/Right leaves the item, and any WM action closes the popup with the bar.
- Selecting the Plex item opens its status popup. Space on the bar item starts
  or stops Plex Media Server. J/K moves between the item, the read-only stream
  count, Open Plex, and Update Libraries; Space invokes the selected action.
  Open Plex and Update Libraries close SketchyBar after invocation. H/L returns
  to normal bar navigation and closes the popup. The integration
  reads the local Plex token at runtime from the standard macOS preferences
  file and never stores it in the dotfiles.
- With Volume selected, Space toggles mute and J/K lower/raise volume without
  leaving navigation mode. Hold J/K for continuous adjustment at the macOS
  keyboard-repeat rate.
- Escape closes the menu or exits navigation.
- Invoking any ordinary WM hotkey exits navigation first, so the modal cannot
  continue consuming typing after focus moves elsewhere.

Set `sketchybar.workspaceFocusStyle` in Hammerspoon to `background`, `border`,
`underline`, `left_bar`, or `text`. The default is `underline`; only the focused
workspace is decorated when keyboard navigation is inactive.

Set `sketchybar.workspaceDisplayMode` to `icon`, `label`, or `icon_label`
(`icon+label` is accepted as an alias). Icon mode uses the first live
application's bundle icon and is the compact default. With
`sketchybar.workspaceActiveLabel = true`, only the active workspace expands an
label next to its fixed icon. `sketchybar.workspaceGroupSeparator`
sets the separator between virtual-screen groups (`>` by default; an empty
string disables it). The symbol uses its intrinsic width so it cannot overlap
neighboring icons. `sketchybar.workspaceGroupSeparatorGap` controls equal space
on both sides, and `sketchybar.workspaceIconWidth` controls the
fixed icon slot. Set it to the rendered artwork width to avoid invisible space.
`sketchybar.workspaceIconOffset` shifts app artwork within that slot, while
`sketchybar.workspaceFocusInset` symmetrically narrows its focus
underline (zero keeps it continuous), and `sketchybar.workspaceLabelGap`
reserves space after an expanded label. Label allocation is controlled by
`workspaceLabelCharacterWidth` and `workspaceLabelExtraWidth`, avoiding the
last-glyph clipping caused by SketchyBar's dynamic width. SketchyBar and Stackline share the same unavailable-
workspace filter, toggled with `meh + D`; unavailable entries use a number
fallback when shown without an application icon. Workspace items are updated
in place, so their labels/icons do not disappear during focus changes.

On the ultrawide profile, all virtual-screen workspace groups render together
in SketchyBar's center section in Left, Center, Right order. The collapsed
laptop profile keeps the workspace strip left-aligned.

The previous AeroSpace-backed configuration is preserved under
`legacy/aerospace/` and is not loaded.
