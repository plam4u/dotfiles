-- Run from packages/hammerspoon: luajit tests/caffeine.lua
package.path = 'stow/.hammerspoon/?.lua;stow/.hammerspoon/?/init.lua;' .. package.path
local saved, assertions = {}, {}
local function noop() end
local function menu()
    return { setIcon = noop, setTitle = noop, setTooltip = noop,
        setClickCallback = noop, setMenu = noop, popupMenu = noop }
end
hs = {
    configdir = '.', logger = { new = function() return { e = error } end },
    settings = { get = function(k) return saved[k] end, set = function(k, v) saved[k] = v end },
    caffeinate = { set = function(k, v, battery)
        assert(type(v) == 'boolean')
        if k == 'system' then assert(not battery) end
        assertions[k] = v
    end },
    image = { imageFromPath = function(p) return p end },
    menubar = { new = menu }, hotkey = { bind = noop }, alert = { show = noop },
}
local c = require('modules.caffeine')
c.setup({ enabled = true, keepDisplayOn = false })
local observed
c.subscribe(function(state) observed = state end)
for _, mode in ipairs({ 'idle', 'system' }) do
    c.setMode(mode)
    for _, display in ipairs({ true, false }) do
        c.toggleDisplay()
        assert(c.keepDisplayOn == display)
        assert(assertions.systemIdle == (mode == 'idle'))
        assert(assertions.system == (mode == 'system'))
        assert(assertions.displayIdle == display)
        assert(observed.enabled and observed.mode == mode and observed.keepDisplayOn == display)
        c.toggle()
        assert(not assertions.system and not assertions.systemIdle and not assertions.displayIdle)
        c.toggle()
    end
end
c.toggleDisplay()
c.toggleMode()
assert(c.mode == 'idle' and assertions.systemIdle and not assertions.system)
c.toggleMode()
assert(c.mode == 'system' and assertions.system and not assertions.systemIdle)
c.toggleLabel()
assert(not c.getState().showLabel and not observed.showLabel)
local restored = dofile('stow/.hammerspoon/modules/caffeine/init.lua')
restored.setup({ mode = 'idle', keepDisplayOn = false })
assert(not restored.getState().showLabel)
assert(restored.state and restored.mode == 'system' and restored.keepDisplayOn)
restored.toggle()
restored.setMode('idle')
assert(not assertions.systemIdle and not assertions.displayIdle and not assertions.system)
-- Existing enabled state survives migration; old display behavior does not force the new preference.
saved = { ['caffeine.state'] = false }
restored.setup({ enabled = true })
assert(not restored.state and restored.mode == 'idle' and not restored.keepDisplayOn)
print('caffeine tests passed')
