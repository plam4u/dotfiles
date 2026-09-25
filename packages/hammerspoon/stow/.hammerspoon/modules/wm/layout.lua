local M = {}
local stacking = require("modules.wm.stacking")
local hotkeys = require("modules.wm.hotkeys")

function M.setup(config)
	M.config = config or {}
	M.logger = hs.logger.new("grid", "debug")

	hs.grid.setGrid(M.config.config.gridSize or "8x8")
	hs.grid.setMargins(M.config.config.margins or "0,0")
	hs.window.animationDuration = M.config.config.animationDuration or 0

	M.bindHotkeys(M.config.mapping or {})
end

function M.bindHotkeys(mapping)
	for action, hotkey in pairs(mapping) do
		local handler = M[action]

		if type(handler) ~= "function" then
			M.logger.e("Unknown layout action: " .. tostring(action))
		else
			hotkeys.bind(hotkey[1], hotkey[2], handler)
		end
	end
end

function M.getWin()
	local win = hs.window.focusedWindow()
	if win and win:isFullScreen() then
		return nil
	end

	if stacking.isManaged(win) then
		hs.alert.show("Remove this window from its stack before moving it freely")
		return nil
	end

	return win
end

local function targetFrame(win)
	return stacking.virtualScreenFrameForWindow(win) or win:screen():frame()
end

local function gridDimensions()
	local layoutConfig = M.config.config or {}
	local width, height = tostring(layoutConfig.gridSize or "8x8"):match("^(%d+)x(%d+)$")
	return tonumber(width) or 8, tonumber(height) or 8
end

local function moveByGrid(dx, dy)
	local win = M.getWin()
	if not win then return end

	local bounds = targetFrame(win)
	local columns, rows = gridDimensions()
	local current = win:frame()
	current.w = math.min(current.w, bounds.w)
	current.h = math.min(current.h, bounds.h)
	current.x = math.max(bounds.x, math.min(bounds.x + bounds.w - current.w, current.x + dx * bounds.w / columns))
	current.y = math.max(bounds.y, math.min(bounds.y + bounds.h - current.h, current.y + dy * bounds.h / rows))
	win:setFrame(current)
end

local function resizeByGrid(dx, dy)
	local win = M.getWin()
	if not win then return end

	local bounds = targetFrame(win)
	local columns, rows = gridDimensions()
	local current = win:frame()
	current.x = math.max(bounds.x, math.min(bounds.x + bounds.w, current.x))
	current.y = math.max(bounds.y, math.min(bounds.y + bounds.h, current.y))
	current.w = math.max(bounds.w / columns, math.min(bounds.x + bounds.w - current.x, current.w + dx * bounds.w / columns))
	current.h = math.max(bounds.h / rows, math.min(bounds.y + bounds.h - current.y, current.h + dy * bounds.h / rows))
	win:setFrame(current)
end

function M.centeredQHDWindow()
	local win = M.getWin()

	if not win then
		return
	end

	local f = win:frame()
	local max = targetFrame(win)
	local targetW = 2560
	local targetH = 1440

	f.w = math.min(targetW, max.w)
	f.h = math.min(targetH, max.h)
	f.x = max.x + (max.w - f.w) / 2
	f.y = max.y + (max.h - f.h) / 2

	win:setFrame(f)
end

function M.sideQHDWindow(side)
	local win = M.getWin()

	if not win then
		return
	end

	local f = win:frame()
	local max = targetFrame(win)
	local targetW = 1280
	local targetH = 1440

	if side == "left" then
		f.x = max.x
	elseif side == "right" then
		f.x = max.x + max.w - math.min(targetW, max.w)
	end

	f.w = math.min(targetW, max.w)
	f.h = math.min(targetH, max.h)
	f.y = max.y + (max.h - f.h) / 2

	win:setFrame(f)
end

function M.leftQHDWindow()
	M.sideQHDWindow("left")
end

function M.rightQHDWindow()
	M.sideQHDWindow("right")
end

function M.wideCenteredWindow(isFullHeight)
	local win = M.getWin()

	if not win then
		return
	end

	local f = win:frame()
	local max = targetFrame(win)

	f.x = max.x + max.w / 6
	f.w = max.w - max.w / 3

	if isFullHeight then
		f.y = max.y
		f.h = max.h
	else
		f.y = max.y + max.h / 30
		f.h = max.h - max.h / 15
	end

	win:setFrame(f)
end

function M.wideCenteredWindowPadded()
	M.wideCenteredWindow(false)
end

function M.wideCenteredWindowFullHeight()
	M.wideCenteredWindow(true)
end

function M.tileWindow(posRatio, sizeRatio)
	local win = M.getWin()

	if not win then
		return
	end

	local f = win:frame()
	local max = targetFrame(win)

	f.x = max.x + posRatio * max.w
	f.w = sizeRatio * max.w
	f.y = max.y
	f.h = max.h

	win:setFrame(f)
end

function M.tileCenterWindow()
	M.tileWindow(2 / 7, 3 / 7)
end

function M.pushWindowUp()
	moveByGrid(0, -1)
end

function M.pushWindowDown()
	moveByGrid(0, 1)
end

function M.pushWindowLeft()
	moveByGrid(-1, 0)
end

function M.pushWindowRight()
	moveByGrid(1, 0)
end

function M.resizeWindowThinner()
	resizeByGrid(-1, 0)
end

function M.resizeWindowWider()
	resizeByGrid(1, 0)
end

function M.resizeWindowShorter()
	resizeByGrid(0, -1)
end

function M.resizeWindowTaller()
	resizeByGrid(0, 1)
end

function M.setGrid(size)
	hs.grid.setGrid(size)
	hs.alert.show("Grid set to " .. size)
end

function M.moveWindowToNextScreen()
	local win = M.getWin()

	if not win then
		return
	end

	win:moveToScreen(win:screen():next())
end

function M.snapWindow()
	local win = M.getWin()

	if not win then
		return
	end

	local bounds = targetFrame(win)
	local columns, rows = gridDimensions()
	local columnWidth = bounds.w / columns
	local rowHeight = bounds.h / rows
	local frame = win:frame()
	local left = math.floor((frame.x - bounds.x) / columnWidth + 0.5)
	local top = math.floor((frame.y - bounds.y) / rowHeight + 0.5)
	local right = math.floor((frame.x + frame.w - bounds.x) / columnWidth + 0.5)
	local bottom = math.floor((frame.y + frame.h - bounds.y) / rowHeight + 0.5)
	left = math.max(0, math.min(columns - 1, left))
	top = math.max(0, math.min(rows - 1, top))
	right = math.max(left + 1, math.min(columns, right))
	bottom = math.max(top + 1, math.min(rows, bottom))
	win:setFrame({
		x = bounds.x + left * columnWidth,
		y = bounds.y + top * rowHeight,
		w = (right - left) * columnWidth,
		h = (bottom - top) * rowHeight,
	})
end

function M.centerWindow()
	local win = M.getWin()

	if not win then
		return
	end

	local target = stacking.virtualScreenFrameForWindow(win)
	if not target then
		win:centerOnScreen()
		return
	end

	local frame = win:frame()
	frame.x = target.x + (target.w - frame.w) / 2
	frame.y = target.y + (target.h - frame.h) / 2
	win:setFrame(frame)
end

function M.maximizeWindow()
	local win = M.getWin()
	if not win then return end
	win:setFrame(targetFrame(win))
end

function M.minimizeWindow()
	local win = M.getWin()

	if not win then
		return
	end

	local f = win:frame()

	-- Preserve position, only change size.
	f.w = 640
	f.h = 480

	win:setFrame(f)
end

return M
