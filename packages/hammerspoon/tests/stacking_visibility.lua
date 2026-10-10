-- Run from packages/hammerspoon: luajit tests/stacking_visibility.lua
for _, name in ipairs({ 'stacking_store', 'stacking_ui', 'virtual_screens', 'hotkeys' }) do
    package.loaded['modules.wm.' .. name] = {}
end
local timers, subscriptions = {}, {}
hs = {
    timer = { doAfter = function(_, callback)
        local timer = { callback = callback, stop = function(self) self.stopped = true end }
        timers[#timers + 1] = timer
        return timer
    end },
    window = { focusedWindow = function() return nil end, filter = {
        windowCreated = 'created', windowDestroyed = 'destroyed', windowNotVisible = 'invisible',
        windowVisible = 'visible', windowRejected = 'rejected', windowFocused = 'focused',
        new = function() return {
            setDefaultFilter = function() end,
            setOverrideFilter = function(_, filter) assert(filter.visible == nil) end,
            subscribe = function(_, event, callback) subscriptions[event] = callback end,
        } end,
    } },
}
local function window(id, pid)
    local app = { running = true, isRunning = function(self) return self.running end,
        pid = function() return pid end, name = function() return 'Test' end,
        bundleID = function() return 'test.' .. pid end }
    return { visible = true, standard = true, rect = {x=0,y=0,w=1000,h=800}, app = app,
        id = function() return id end, application = function(self) return self.app end,
        isVisible = function(self) return self.visible end,
        isStandard = function(self) return self.standard end,
        isFullScreen = function() return false end,
        frame = function(self) return self.rect end,
        setFrame = function(self, frame) self.rect = frame; self.resizes = (self.resizes or 0) + 1 end,
        raise = function(self) self.raises = (self.raises or 0) + 1 end }
end
local s = dofile('stow/.hammerspoon/modules/wm/stacking.lua')
s.enabled, s.options = true, {}
s.screenOrder, s.currentScreenName = {'center'}, 'center'
local first, second = window(100, 42), window(200, 43)
local workspace = { members = {
    {window=first,windowID=100,pid=42,name='iTerm',bundleID='test.42'},
    {window=second,windowID=200,pid=43,name='Other',bundleID='test.43'},
}, splitRatio=0.4,focusedMember=1 }
s.screens = {center={frame={x=0,y=0,w=1000,h=800},activeWorkspace=1,workspaces={workspace}}}
s.render, s.raiseActiveWorkspaces = function() end, function() end
s.rebuildWindowIndex()
s.startWindowWatcher()
assert(subscriptions.visible and subscriptions.destroyed)
s.layoutWorkspace('center', workspace, false)
assert(first.rect.w == 400 and second.rect.x == 400 and second.rect.w == 600)
first.visible = false
local resizes = first.resizes
subscriptions.invisible(first)
s.applicationDeactivated(42)
assert(not s.reconcileWindows() and workspace.members[1].window == first)
assert(#s.snapshot().groups[1].workspaces == 1)
s.layoutWorkspace('center', workspace, false)
assert(first.resizes == resizes and second.rect.w == 600 and workspace.splitRatio == 0.4)
-- Animation frames must not be learned as minimum widths or split the workspace.
first.rect.w = 900
s.verifyWorkspaceLayout('center', workspace, 400, workspace.resizeVersion)
assert(not workspace.members[1].minWidth and #s.screens.center.workspaces == 1)
-- Rapid show/hide cancels pending restoration without losing membership.
first.visible = true
subscriptions.visible(first)
local pending = timers[#timers]
assert(s.visibilityTimers[100] == pending)
first.visible = false
pending.callback()
assert(first.resizes == resizes)
first.visible = true
subscriptions.visible(first)
timers[#timers].callback()
assert(first.rect.w == 400 and second.rect.w == 600 and workspace.splitRatio == 0.4)
-- Parking must not be undone by a visibility event.
workspace.members[1].parked = true
subscriptions.visible(first)
timers[#timers].callback()
assert(workspace.members[1].parked)
workspace.members[1].parked = nil
-- Hidden sole members stay in stackline; genuine destruction clears them.
workspace.members[2].window = nil
first.visible = false
subscriptions.invisible(first)
assert(#s.snapshot().groups[1].workspaces == 1)
subscriptions.destroyed(first)
assert(workspace.members[1].window == nil and #s.snapshot().groups[1].workspaces == 0)
-- AX invalidation and app exit still reconcile, including missing destroy events.
workspace.members[1].window, workspace.members[1].windowID = first, 100
first.standard = false
assert(s.reconcileWindows() and workspace.members[1].window == nil)
first.standard = true
workspace.members[1].window, workspace.members[1].pid = first, 42
first.app.running = false
assert(s.reconcileWindows() and workspace.members[1].window == nil)
first.app.running = true
workspace.members[1].window, workspace.members[1].pid = first, 42
s.applicationTerminated(42)
assert(workspace.members[1].window == nil)
print('PASS: hide/show, split restoration, rapid toggles, parking, destruction, AX invalidation, app exit')
