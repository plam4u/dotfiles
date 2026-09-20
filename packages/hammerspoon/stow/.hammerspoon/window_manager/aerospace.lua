local log = require("window_manager.log")
local M = {}

local function shell(command)
  local output, ok = hs.execute("/opt/homebrew/bin/aerospace " .. command, true)
  if not ok then log.warning("AeroSpace command failed: %s", command) end
  return ok and (output or "") or nil
end

function M.workspaceForWindow(windowId)
  local output = shell("list-windows --all --format '%{window-id}|%{workspace}'")
  if not output then return nil end
  for line in output:gmatch("[^\r\n]+") do
    local id, workspace = line:match("^(%d+)|(.+)$")
    if tonumber(id) == tonumber(windowId) then return workspace end
  end
  return nil
end

function M.layoutForWindow(windowId)
  local output = shell("list-windows --all --format '%{window-id}|%{window-layout}'")
  if not output then return nil end
  for line in output:gmatch("[^\r\n]+") do
    local id, layout = line:match("^(%d+)|(.+)$")
    if tonumber(id) == tonumber(windowId) then return layout end
  end
  return nil
end

function M.windowsForWorkspace(workspace)
  if not workspace then return {} end
  local quoted = string.format("%q", workspace)
  local output = shell("list-windows --workspace " .. quoted .. " --format '%{window-id}|%{window-layout}'")
  local windows = {}
  if not output then return windows end
  for line in output:gmatch("[^\r\n]+") do
    local id, layout = line:match("^(%d+)|(.+)$")
    -- AeroSpace reports hidden app placeholders as windows. They are not
    -- visible application windows and must not affect ultrawide decisions.
    if id and layout and layout ~= "macos_native_window_of_hidden_app" then
      table.insert(windows, { id = tonumber(id), layout = layout })
    end
  end
  return windows
end

function M.windowCount(workspace)
  return #M.windowsForWorkspace(workspace)
end

function M.focusedWorkspace()
  local output = shell("list-workspaces --focused")
  return output and output:match("([^\r\n]+)") or nil
end

function M.setFloating(windowId, floating)
  return shell(string.format("layout --window-id %d %s", windowId, floating and "floating" or "tiling")) ~= nil
end

return M
