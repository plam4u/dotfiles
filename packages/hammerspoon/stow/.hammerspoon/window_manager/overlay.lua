local config = require("window_manager.config")
local regions = require("window_manager.regions")

local M = { cells = {}, selected = nil, modal = nil, current = nil }

local function render(screen)
  local usable = screen:frame()
  local cols, rows, gap = config.grid.columns, config.grid.rows, config.overlay.gap
  for _, canvas in ipairs(M.cells) do canvas:delete() end
  M.cells = {}
  for y = 0, rows - 1 do
    for x = 0, cols - 1 do
      local f = regions.frame({ x = x, y = y, w = 1, h = 1 }, screen)
      f.x, f.y, f.w, f.h = f.x + gap, f.y + gap, f.w - gap * 2, f.h - gap * 2
      local canvas = hs.canvas.new(f):level(hs.canvas.windowLevels.overlay):behavior({ "canJoinAllSpaces", "stationary" })
      canvas[1] = { type = "rectangle", action = "fill", fillColor = config.overlay.fill, roundedRectRadii = { xRadius = 10, yRadius = 10 } }
      canvas:clickActivating(false):mouseCallback(function(_, message)
        if message == "mouseUp" and M.current then
          M.current.x, M.current.y, M.current.w, M.current.h = x, y, 1, 1
          M.current.management = "hammerspoon"
          M.refresh(screen)
        end
      end):canvasMouseEvents(true, true, false, false):show()
      table.insert(M.cells, canvas)
    end
  end
end

function M.refresh(screen)
  if M.selected then M.selected:delete() end
  local f = regions.frame(M.current, screen)
  local gap = config.overlay.gap
  f.x, f.y, f.w, f.h = f.x + gap, f.y + gap, f.w - gap * 2, f.h - gap * 2
  M.selected = hs.canvas.new(f):level(hs.canvas.windowLevels.overlay + 1):behavior({ "canJoinAllSpaces", "stationary" })
  M.selected[1] = { type = "rectangle", action = "fill", fillColor = config.overlay.selectedFill, roundedRectRadii = { xRadius = 12, yRadius = 12 } }
  M.selected[2] = { type = "rectangle", action = "stroke", strokeColor = config.overlay.stroke, strokeWidth = 4, roundedRectRadii = { xRadius = 12, yRadius = 12 } }
  M.selected:clickActivating(false):show()
end

function M.hide()
  if M.modal then M.modal:exit(); M.modal = nil end
  for _, canvas in ipairs(M.cells) do canvas:delete() end
  M.cells = {}
  if M.selected then M.selected:delete(); M.selected = nil end
  M.current = nil
end

function M.show(screen, initial, onCommit, onCancel)
  M.hide()
  M.current = regions.copy(initial or regions.presets.center)
  render(screen); M.refresh(screen)
  local modal = hs.hotkey.modal.new(); M.modal = modal
  local function update(dx, dy)
    M.current.x = M.current.x + dx; M.current.y = M.current.y + dy
    regions.clamp(M.current); M.refresh(screen)
  end
  local function resize(dw, dh)
    M.current.w = M.current.w + dw; M.current.h = M.current.h + dh
    regions.clamp(M.current); M.refresh(screen)
  end
  modal:bind({}, "left", function() update(-1, 0) end, nil, function() update(-1, 0) end)
  modal:bind({}, "right", function() update(1, 0) end, nil, function() update(1, 0) end)
  modal:bind({}, "up", function() update(0, -1) end, nil, function() update(0, -1) end)
  modal:bind({}, "down", function() update(0, 1) end, nil, function() update(0, 1) end)
  modal:bind({ "shift" }, "left", function() resize(-1, 0) end)
  modal:bind({ "shift" }, "right", function() resize(1, 0) end)
  modal:bind({ "shift" }, "up", function() resize(0, -1) end)
  modal:bind({ "shift" }, "down", function() resize(0, 1) end)
  local shortcuts = { ["1"]="left", ["2"]="center", ["3"]="right", ["4"]="left_half", ["5"]="right_half", ["6"]="left_75", ["7"]="right_75", ["8"]="full", ["9"]="tiled" }
  for key, name in pairs(shortcuts) do modal:bind({}, key, function() M.current = regions.copy(regions.presets[name]); M.refresh(screen) end) end
  modal:bind({}, "return", function() local chosen = regions.copy(M.current); M.hide(); onCommit(chosen) end)
  modal:bind({}, "escape", function() M.hide(); if onCancel then onCancel() end end)
  modal:enter()
end

return M
