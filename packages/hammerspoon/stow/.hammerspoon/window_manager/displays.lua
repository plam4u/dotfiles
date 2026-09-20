local config = require("window_manager.config")
local log = require("window_manager.log")

local M = {}

local function modePixels(screen)
  local mode = screen and screen:currentMode() or nil
  if not mode then return 0, 0 end
  return tonumber(mode.w) or 0, tonumber(mode.h) or 0
end

function M.isUltrawide(screen)
  if not screen then return false end
  local w, h = modePixels(screen)
  if w == config.ultrawide.pixelWidth and h == config.ultrawide.pixelHeight then
    return true
  end
  local name = screen:name() or ""
  for _, pattern in ipairs(config.ultrawide.namePatterns) do
    if name:match(pattern) and w / math.max(h, 1) > 3 then return true end
  end
  return false
end

function M.active()
  local focused = hs.window.focusedWindow()
  return (focused and focused:screen()) or hs.screen.mainScreen()
end

function M.mode(screen)
  return M.isUltrawide(screen or M.active()) and "ultrawide" or "laptop"
end

function M.describe(screen)
  screen = screen or M.active()
  if not screen then return { mode = "laptop", name = "unknown" } end
  local w, h = modePixels(screen)
  local frame, fullFrame = screen:frame(), screen:fullFrame()
  return {
    mode = M.mode(screen), name = screen:name() or "unknown",
    uuid = screen:getUUID(), pixelWidth = w, pixelHeight = h,
    frame = { x = frame.x, y = frame.y, w = frame.w, h = frame.h },
    fullFrame = { x = fullFrame.x, y = fullFrame.y, w = fullFrame.w, h = fullFrame.h },
  }
end

function M.writeState()
  local state = M.describe()
  local path = os.getenv("HOME") .. "/.cache/adaptive-window-manager/display.json"
  hs.fs.mkdir(os.getenv("HOME") .. "/.cache")
  hs.fs.mkdir(os.getenv("HOME") .. "/.cache/adaptive-window-manager")
  local file = io.open(path, "w")
  if file then file:write(hs.json.encode(state, true)); file:close() end
  log.debug("display: %s %s %dx%d", state.mode, state.name, state.pixelWidth or 0, state.pixelHeight or 0)
  return state
end

return M
