local config = require("window_manager.config")

local M = {}

-- Coordinates are grid cells. Custom regions preserve empty space and are
-- Hammerspoon-managed. "tiled" deliberately hands the window back to AeroSpace.
M.presets = {
  left =         { x = 0, y = 0, w = 1, h = 2, management = "hammerspoon" },
  center =       { x = 1, y = 0, w = 2, h = 2, management = "hammerspoon" },
  right =        { x = 3, y = 0, w = 1, h = 2, management = "hammerspoon" },
  left_half =    { x = 0, y = 0, w = 2, h = 2, management = "hammerspoon" },
  right_half =   { x = 2, y = 0, w = 2, h = 2, management = "hammerspoon" },
  center_left =  { x = 1, y = 0, w = 1, h = 2, management = "hammerspoon" },
  center_right = { x = 2, y = 0, w = 1, h = 2, management = "hammerspoon" },
  left_75 =      { x = 0, y = 0, w = 3, h = 2, management = "hammerspoon" },
  right_75 =     { x = 1, y = 0, w = 3, h = 2, management = "hammerspoon" },
  full =         { x = 0, y = 0, w = 4, h = 2, management = "hammerspoon" },
  tiled =        { x = 0, y = 0, w = 4, h = 2, management = "aerospace" },
}

function M.copy(region)
  return { x = region.x, y = region.y, w = region.w, h = region.h, management = region.management }
end

function M.frame(region, screen)
  local usable = screen:frame()
  local cols, rows = config.grid.columns, config.grid.rows
  return hs.geometry.rect(
    usable.x + usable.w * region.x / cols,
    usable.y + usable.h * region.y / rows,
    usable.w * region.w / cols,
    usable.h * region.h / rows
  )
end

function M.clamp(region)
  local cols, rows = config.grid.columns, config.grid.rows
  region.w = math.max(1, math.min(region.w, cols))
  region.h = math.max(1, math.min(region.h, rows))
  region.x = math.max(0, math.min(region.x, cols - region.w))
  region.y = math.max(0, math.min(region.y, rows - region.h))
  region.management = "hammerspoon"
  return region
end

return M
