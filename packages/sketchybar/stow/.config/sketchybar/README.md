# SketchyBar

Hammerspoon owns workspace state and publishes
`~/.hammerspoon/state/sketchybar.json`. SketchyBar renders only live workspaces
and sends validated actions back through the `hammerspoon://wm-bar` URL handler.
Virtual-screen names are intentionally omitted; item placement and workspace
order preserve the grouping without spending bar space on labels.

- Ultrawide: hidden until `option + M` enters navigation mode.
- Built-in display: always visible, with notch-aware height enabled.
- The first keyboard-navigation session after Hammerspoon starts selects the
  rightmost control item (`clock`); later sessions restore the last selection.
- Return invokes the selected item.
- Space opens the selected item's action menu.
- With Volume selected, Space toggles mute and J/K lower/raise volume without
  leaving navigation mode. Hold J/K for continuous adjustment at the macOS
  keyboard-repeat rate.
- Escape closes the menu or exits navigation.
- Invoking any ordinary WM hotkey exits navigation first, so the modal cannot
  continue consuming typing after focus moves elsewhere.

Set `sketchybar.workspaceFocusStyle` in Hammerspoon to `background`, `border`,
`underline`, `left_bar`, or `text`. The default is `underline`; only the focused
workspace is decorated when keyboard navigation is inactive.

The previous AeroSpace-backed configuration is preserved under
`legacy/aerospace/` and is not loaded.
