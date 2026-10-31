-- Run from packages/hammerspoon: luajit tests/window_rules.lua
package.path = 'stow/.hammerspoon/?.lua;' .. package.path
local focused, windows
hs = {
    axuielement = { windowElement = function(w) return w.ax end },
    window = { focusedWindow = function() return focused end, filter = { new = function() return {
        setDefaultFilter = function() end, setOverrideFilter = function() end,
        setSortOrder = function() end, getWindows = function() return windows end,
    } end } },
    timer = { doAfter = function() error('excluded popup scheduled work') end },
}
local rules = require('modules.wm.window_rules')
rules.setup({exclude = {
    {bundleID='com.openai.codex', title='Spotlight Window'},
    {bundleID='calendar', titlePattern='^Edit Event'},
}})
local function window(id, title, bundleID)
    local w = {name=title, bundle=bundleID or 'com.openai.codex', standard=true,
        sub='AXStandardWindow', resizable=true, modal=false}
    w.id = function() return id end
    w.title = function(self) return self.name end
    w.application = function(self) return {
        bundleID=function() return self.bundle end, name=function() return 'App' end,
        pid=function() return 42 end, isRunning=function() return true end,
    } end
    w.isStandard = function(self) return self.standard end
    w.isFullScreen = function() return false end
    w.isVisible = function() return true end
    w.role = function() return 'AXWindow' end
    w.subrole = function(self) return self.sub end
    w.ax = {
        attributeValue=function() return w.modal end,
        isAttributeSettable=function() return w.resizable end,
    }
    w.setFrame = function() error('popup resized') end
    w.focus = function() error('popup focused') end
    w.raise = function() error('popup raised') end
    return w
end
local popup, main = window(1, 'Spotlight Window'), window(2, 'ChatGPT')
assert(not rules.isEligible(popup) and rules.isEligible(main))
assert(rules.isEligible(window(3, 'Spotlight Window', 'other.app')))
assert(not rules.isEligible(window(4, 'Edit Event: Meeting', 'calendar')))
local dialog = window(5, 'Meeting', 'calendar')
dialog.modal = true
assert(not rules.isEligible(dialog))
dialog.modal, dialog.resizable = false, false
assert(not rules.isEligible(dialog))
dialog.resizable, dialog.sub = true, 'AXDialog'
assert(not rules.isEligible(dialog))
dialog.sub, dialog.standard = 'AXStandardWindow', false
assert(not rules.isEligible(dialog))
-- Unsupported accessibility attributes must not exclude a normal main window.
main.ax.isAttributeSettable = function() error('unsupported') end
assert(rules.isEligible(main))
main.isFullScreen = function() return true end
assert(not rules.isEligible(main) and rules.isEligible(main, true))
main.isFullScreen = function() return false end
for _, name in ipairs({'stacking_store','stacking_ui','virtual_screens','hotkeys'}) do
    package.loaded['modules.wm.' .. name] = {}
end
local stacking = require('modules.wm.stacking')
stacking.enabled, stacking.options = true, {}
stacking.screenOrder = {'center'}
local member = {bundleID='com.openai.codex', windowID=1}
local workspace = {members={member}, focusedMember=1}
stacking.screens = {center={workspaces={workspace}, activeWorkspace=1}}
-- Background raising must leave the focused popup alone.
focused = popup
stacking.raiseActiveWorkspaces()
stacking.layoutAllWorkspaces, stacking.raiseActiveWorkspaces = function() end, function() end
windows = {popup, main}
stacking.restoreWindows(true)
assert(member.window == main and member.windowID == 2)
assert(not stacking.windowIndex[1] and stacking.windowIndex[2])
stacking.attachCreatedWindow(popup)
stacking.windowVisible(popup)
stacking.windowFocused(popup)
assert(#stacking.screens.center.workspaces == 1)
assert(not stacking.addWindowToWorkspace('center', workspace, popup))
-- Main window absent: the popup must never fill its saved placeholder.
windows = {popup}
stacking.restoreWindows(true)
assert(member.window == nil and not stacking.windowIndex[1])
local layout = require('modules.wm.layout')
assert(layout.getWin() == nil)
layout.maximizeWindow()
print('PASS: popup rules, AX fallbacks, restoration, detection, focus, and manual layout')
