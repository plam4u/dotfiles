-- Run with luajit tests/caffeine_menu.lua
package.path = 'stow/.hammerspoon/?.lua;stow/.hammerspoon/?/init.lua;' .. package.path
local noop = function() end
local state = { enabled = false, mode = 'idle', keepDisplayOn = false, showLabel = true }
local callback
package.loaded['modules.caffeine'] = {
    getState = function() return state end,
    subscribe = function(fn) callback = fn; fn(state) end,
    caffeineClicked = function() state.enabled = not state.enabled; callback(state) end,
    toggleMode = function() state.mode = state.mode == "idle" and "system" or "idle"; callback(state) end,
    toggleLabel = function() state.showLabel = not state.showLabel; callback(state) end,
    toggleDisplay = function() state.keepDisplayOn = not state.keepDisplayOn; callback(state) end,
}
for _, name in ipairs({ 'modules.keyboard', 'modules.wm.hotkeys', 'modules.wm.stacking',
    'modules.wm.sketchybar.key_lights', 'modules.wm.sketchybar.plex',
    'modules.wm.sketchybar.transmission' }) do
    package.loaded[name] = { closeDetails = noop, invokeSelected = function() return false end,
        handleHorizontal = function() return false end, handleVertical = function() return false end,
        syncDetails = noop, stopRepeat = noop }
end
package.loaded['modules.wm.sketchybar.items'] = { all = function() return {} end }
local panel = require('modules.wm.sketchybar.caffeine')
local ui = dofile('stow/.hammerspoon/modules/wm/sketchybar.lua')
ui.run, ui.publish, ui.applySelection, ui.updateCaffeine, ui.syncCodexUsageDetails = noop, noop, noop, noop, noop
ui.itemEnabled = function() return true end
ui.active = true
ui.navigableItems = { { id = 'caffeine', type = 'static' }, { id = 'plex', type = 'static' } }
local exits = 0
ui.modal = { exit = function() exits = exits + 1 end }
panel.setup({}, ui)
ui.moveSelection(0)
assert(panel.detailsVisible and panel.rowIndex == 1 and ui.menuIndex == nil)
ui.handleSpace()
assert(state.enabled and exits == 0)
ui.handleVerticalNavigation(1)
ui.invokeSelected()
assert(state.mode == 'system' and panel.rowIndex == 2 and exits == 0)
ui.handleVerticalNavigation(1)
ui.handleSpace()
assert(state.keepDisplayOn and panel.detailsVisible)
ui.handleVerticalNavigation(1)
ui.handleSpace()
assert(not state.showLabel and panel.detailsVisible and exits == 0)
ui.handleHorizontalNavigation(1)
assert(ui.selectedIndex == 2 and not panel.detailsVisible)
ui.handleHorizontalNavigation(-1)
assert(ui.selectedIndex == 1 and panel.detailsVisible)
ui.handleVerticalNavigation(-1)
assert(panel.rowIndex == 4)
ui.handleURL(nil, { command = 'caffeine-hover' })
assert(panel.detailsVisible)
ui.handleURL(nil, { command = 'caffeine-row', index = '4' })
assert(state.showLabel and exits == 0)
print('caffeine panel navigation tests passed')
