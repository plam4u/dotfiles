local aerospace = require("window_manager.aerospace")
local displays = require("window_manager.displays")
local log = require("window_manager.log")
local overlay = require("window_manager.overlay")
local regions = require("window_manager.regions")

local M = {
  assignments = hs.settings.get("adaptive-wm.assignments") or {}, pending = {}, applying = {},
  queue = {}, overlayBusy = false,
}

local function key(id) return tostring(id) end
local function save() hs.settings.set("adaptive-wm.assignments", M.assignments) end

local function windowInfo(win, workspace, region)
  local app = win:application()
  return {
    windowId = win:id(), bundleId = app and app:bundleID() or "", title = win:title() or "",
    workspace = workspace, region = region, displayMode = "ultrawide",
  }
end

function M.apply(win, workspace, region)
  if not win then return end
  local id = win:id()
  if region.management == "aerospace" then
    -- A tiled window can still be obscured by custom floating windows. An
    -- explicit tiled selection means the whole workspace should form one
    -- coherent AeroSpace tree.
    local assignedIds = {}
    for assignedId, assignment in pairs(M.assignments) do
      if assignment.workspace == workspace then table.insert(assignedIds, assignedId) end
    end
    for _, assignedId in ipairs(assignedIds) do
      aerospace.setFloating(tonumber(assignedId), false)
      M.assignments[assignedId] = nil
    end
    aerospace.setFloating(id, false)
    M.assignments[key(id)] = nil; save()
    log.info("placement committed: window=%d workspace=%s region=tiled management=aerospace", id, workspace or "?")
    return
  end
  aerospace.setFloating(id, true)
  local screen = displays.active()
  if not displays.isUltrawide(screen) then return end
  local frame = regions.frame(region, screen)
  M.applying[key(id)] = true
  win:setFrameInScreenBounds(frame, 0)
  hs.timer.doAfter(0.4, function() M.applying[key(id)] = nil end)
  M.assignments[key(id)] = windowInfo(win, workspace, region); save()
  log.info("placement committed: window=%d workspace=%s management=hammerspoon frame=%s", id, workspace or "?", hs.inspect(frame))
end

local function findWithRetry(id, attempt)
  local win = hs.window.get(id)
  if win then return win end
  if attempt >= 8 then return nil end
  return nil
end

local function showNext()
  if M.overlayBusy or #M.queue == 0 then return end
  local item = table.remove(M.queue, 1)
  if not hs.window.get(item.id) or not displays.isUltrawide(displays.active()) then showNext(); return end
  M.overlayBusy = true
  -- Remove the pending window from AeroSpace's tiling tree before selection.
  -- Raising does not take keyboard focus, but prevents an existing custom
  -- floating window from visually covering the new window.
  aerospace.setFloating(item.id, true)
  item.win:raise()
  overlay.show(displays.active(), regions.presets.center, function(region)
    M.overlayBusy = false
    local currentWorkspace = aerospace.workspaceForWindow(item.id)
    if hs.window.get(item.id) and currentWorkspace == item.workspace and displays.isUltrawide(displays.active()) then
      M.apply(item.win, item.workspace, region)
    else
      log.warning("placement cancelled: window or workspace changed")
    end
    showNext()
  end, function()
    M.overlayBusy = false
    if item.originalLayout ~= "floating" then aerospace.setFloating(item.id, false) end
    log.info("placement cancelled: window=%d", item.id)
    showNext()
  end)
  log.info("placement UI opened: window=%d", item.id)
end

function M.handleNewWindow(id)
  id = tonumber(id); if not id or M.pending[key(id)] then return end
  M.pending[key(id)] = true
  local attempt = 0
  local function resolve()
    attempt = attempt + 1
    local win = findWithRetry(id, attempt)
    local workspace = aerospace.workspaceForWindow(id)
    if (not win or not workspace) and attempt < 8 then hs.timer.doAfter(0.15, resolve); return end
    M.pending[key(id)] = nil
    if not win or not workspace or not displays.isUltrawide(displays.active()) then return end
    local role, subrole = win:role(), win:subrole()
    if role ~= "AXWindow" or (subrole ~= "AXStandardWindow" and subrole ~= "AXUnknown") then return end
    local app = win:application()
    log.info("new window: app=%s id=%d workspace=%s display=%s", app and app:name() or "?", id, workspace, displays.describe().name)
    if aerospace.windowCount(workspace) <= 1 then
      M.apply(win, workspace, regions.presets.center)
    else
      table.insert(M.queue, {
        id = id, win = win, workspace = workspace,
        originalLayout = aerospace.layoutForWindow(id),
      })
      showNext()
    end
  end
  resolve()
end

function M.restore(workspace)
  if not displays.isUltrawide(displays.active()) then return end
  for id, assignment in pairs(M.assignments) do
    local win = hs.window.get(tonumber(id))
    if win then
      assignment.workspace = aerospace.workspaceForWindow(tonumber(id)) or assignment.workspace
      if not workspace or assignment.workspace == workspace then M.apply(win, assignment.workspace, assignment.region) end
    else
      M.assignments[id] = nil
    end
  end
  save()
end

function M.reconcile(workspace)
  if not displays.isUltrawide(displays.active()) then return end
  workspace = workspace or aerospace.focusedWorkspace()
  if not workspace then return end
  local windows = aerospace.windowsForWorkspace(workspace)
  if #windows == 1 then
    local win = hs.window.get(windows[1].id)
    if win then
      log.info("single-window workspace: centering window=%d workspace=%s", windows[1].id, workspace)
      M.apply(win, workspace, regions.presets.center)
      return
    end
  end
  M.restore(workspace)
end

function M.windowDestroyed(win)
  if win then M.assignments[key(win:id())] = nil; save() end
end

function M.windowMoved(win)
  if not win then return end
  local id, assignment = key(win:id()), M.assignments[key(win:id())]
  if not assignment or M.applying[id] then return end
  local expected = regions.frame(assignment.region, displays.active())
  local actual = win:frame()
  if math.abs(actual.x - expected.x) + math.abs(actual.y - expected.y) + math.abs(actual.w - expected.w) + math.abs(actual.h - expected.h) > 24 then
    M.assignments[id] = nil; save()
    log.info("manual move detected; released window=%s from Hammerspoon management", id)
  end
end

function M.screenChanged()
  local state = displays.writeState()
  overlay.hide(); M.overlayBusy = false; M.queue = {}
  if state.mode == "ultrawide" then
    M.reconcile()
  else
    for id in pairs(M.assignments) do aerospace.setFloating(tonumber(id), false) end
  end
  hs.execute(os.getenv("HOME") .. "/.config/sketchybar/plugins/display_layout.sh", true)
end

return M
