-- Run from packages/hammerspoon: luajit tests/session_recovery.lua
local timers, calls, paused = {}, {}, false
local function record(name) return function() calls[#calls + 1] = name end end
local events = {}
for i, name in ipairs({ 'systemWillSleep', 'screensDidSleep', 'screensDidLock',
    'sessionDidResignActive', 'systemDidWake', 'screensDidWake', 'screensDidUnlock',
    'sessionDidBecomeActive' }) do events[name] = i end
events.new = function(callback)
    return { callback = callback, start = function() end, stop = function() end }
end
hs = {
    caffeinate = { watcher = events },
    logger = { new = function() return { e = function(err) error(err) end } end },
    timer = { doAfter = function(delay, callback)
        local timer = { delay = delay, callback = callback,
            stop = function(self) self.stopped = true end }
        timers[#timers + 1] = timer
        return timer
    end },
}
local hotkeys = { runBeforeHandlers = record('dismiss'),
    setEnabled = function(enabled) assert(enabled == not paused); record('hotkeys')() end }
package.loaded['modules.wm.hotkeys'] = hotkeys
package.loaded['modules.keyboard'] = { setup = record('keyboard') }
package.loaded['modules.wm.stacking'] = { isSuspended = function() return paused end,
    recoverSession = record('stacks') }
package.loaded['modules.wm.borders'] = { ensureRunning = record('borders') }
package.loaded['modules.wm.sketchybar'] = { recoverSession = record('bar') }
local control = dofile('stow/.hammerspoon/modules/wm/control.lua')
control.setup({})
local emit = control.sessionWatcher.callback
emit(events.systemDidWake)
assert(#timers == 3 and timers[1].delay == 1 and timers[3].delay == 8)
emit(events.screensDidUnlock)
assert(#timers == 6 and timers[1].stopped and timers[3].stopped)
calls = {}
timers[4].callback()
assert(table.concat(calls, ',') == 'keyboard,hotkeys,stacks,borders,bar')
emit(events.screensDidLock)
assert(timers[4].stopped and timers[6].stopped)
paused, calls = true, {}
control.recoverSession()
assert(table.concat(calls, ',') == 'keyboard,hotkeys,stacks,bar')

-- Exercise real restoration with two windows of the same app returned in a
-- different order, plus a missing member that must not steal a surviving ID.
for _, name in ipairs({ 'stacking_store', 'stacking_ui', 'virtual_screens' }) do
    package.loaded['modules.wm.' .. name] = {}
end
local windows = {}
local function window(id)
    local app = { bundleID = function() return 'test.app' end,
        name = function() return 'Test' end, pid = function() return 123 end }
    return { id = function() return id end, application = function() return app end }
end
local a, b, c = window(1), window(2), window(3)
windows = { b, c, a }
hs.window = { filter = { new = function() return {
    setDefaultFilter = function() end, setOverrideFilter = function() end,
    setSortOrder = function() end, getWindows = function() return windows end,
} end } }
local stacking = dofile('stow/.hammerspoon/modules/wm/stacking.lua')
local missing = { bundleID = 'test.app' }
local first = { bundleID = 'test.app', windowID = 1 }
local second = { bundleID = 'test.app', windowID = 2 }
local workspaces = { {members={missing}}, {members={first}}, {members={second}} }
stacking.screenOrder = { 'center' }
stacking.screens = { center = { workspaces = workspaces } }
stacking.layoutAllWorkspaces, stacking.raiseActiveWorkspaces = function() end, function() end
stacking.restoreWindows(true)
assert(first.window == a and second.window == b and missing.window == c)
assert(#workspaces == 3)

local restores, renders = 0, 0
stacking.enabled = true
stacking.applyResolvedLayout = function() return true end
for _, name in ipairs({ 'startWindowWatcher', 'startMouseFocusWatcher',
    'startWorkspaceScrollWatcher', 'startWorkspaceHoverWatcher' }) do stacking[name] = function() end end
stacking.restoreWindows = function(preserve) assert(preserve); restores = restores + 1 end
stacking.render = function() renders = renders + 1 end
package.loaded['modules.wm.stacking_ui'].clear = function() end
stacking.recoverSession()
stacking.suspended = true
stacking.recoverSession()
assert(restores == 1 and renders == 2 and stacking.suspended)

-- The actual bar policy must be reapplied even when the snapshot is identical.
package.loaded['modules.wm.stacking'] = stacking
for _, name in ipairs({ 'key_lights', 'plex', 'transmission' }) do
    package.loaded['modules.wm.sketchybar.' .. name] = {}
end
package.loaded['modules.wm.sketchybar.items'] = { all = function() return {} end }
local bar = dofile('stow/.hammerspoon/modules/wm/sketchybar.lua')
bar.config, bar.rightItemOrder = {}, {}
bar.rebuildNavigation, bar.publish, bar.applySelection = function() end, function() end, function() end
local hidden
bar.run = function(args)
    for _, arg in ipairs(args) do if arg:match('^hidden=') then hidden = arg end end
end
stacking.snapshot = function() return { collapsed = false } end
bar.recoverSession()
assert(hidden == 'hidden=on')
hidden = nil
bar.recoverSession()
assert(hidden == 'hidden=on')
stacking.snapshot = function() return { collapsed = true } end
bar.recoverSession()
assert(hidden == 'hidden=off')
print('PASS: wake/unlock debounce, lock cancellation, paused WM, stable window IDs, redraw, bar visibility')
