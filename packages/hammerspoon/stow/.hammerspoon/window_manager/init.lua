local displays = require("window_manager.displays")
local placement = require("window_manager.placement")

local M = {}

function M.start()
  require("hs.ipc")
  displays.writeState()

  hs.urlevent.bind("aerospace-window-detected", function(_, params)
    placement.handleNewWindow(params.window_id)
  end)
  hs.urlevent.bind("aerospace-workspace-changed", function(_, params)
    -- Give AeroSpace a moment to finish exposing the newly visible workspace.
    hs.timer.doAfter(0.1, function() placement.reconcile(params.workspace) end)
  end)

  M.filter = hs.window.filter.new()
  M.filter:subscribe(hs.window.filter.windowDestroyed, placement.windowDestroyed)
  M.filter:subscribe(hs.window.filter.windowMoved, placement.windowMoved)
  M.screenWatcher = hs.screen.watcher.new(placement.screenChanged):start()
  hs.timer.doAfter(0.5, function() placement.reconcile() end)

  hs.hotkey.bind({ "ctrl", "alt", "cmd" }, "p", function()
    local win = hs.window.focusedWindow()
    if win and displays.isUltrawide(win:screen()) then
      local workspace = require("window_manager.aerospace").workspaceForWindow(win:id())
      require("window_manager.overlay").show(win:screen(), require("window_manager.regions").presets.center,
        function(region) placement.apply(win, workspace, region) end)
    end
  end)
end

return M
