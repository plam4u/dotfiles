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

function M.centeredQHDWindow()
	local win = M.getWin()

	if not win then
		return
	end

	local f = win:frame()
	local screen = win:screen()
	local max = screen:frame()
	local targetW = 2560
	local targetH = 1440

	f.x = (max.w - targetW) / 2
	f.y = (max.h - targetH) / 2
	f.w = targetW
	f.h = targetH

	win:setFrame(f)
end

function M.sideQHDWindow(side)
	local win = M.getWin()

	if not win then
		return
	end

	local f = win:frame()
	local screen = win:screen()
	local max = screen:frame()
	local targetW = 1280
	local targetH = 1440

	if side == "left" then
		f.x = 0
	elseif side == "right" then
		f.x = max.w - targetW
	end

	f.y = (max.h - targetH) / 2
	f.w = targetW
	f.h = targetH

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
	local screen = win:screen()
	local max = screen:frame()

	f.x = max.w / 6
	f.w = max.w - max.w / 3

	if isFullHeight then
		f.y = 0
		f.h = max.h
	else
		f.y = max.h / 30
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
	local screen = win:screen()
	local max = screen:frame()

	f.x = posRatio * max.w
	f.w = sizeRatio * max.w
	f.y = 0
	f.h = max.h

	win:setFrame(f)
end

function M.tileCenterWindow()
	M.tileWindow(2 / 7, 3 / 7)
end

function M.pushWindowUp()
	hs.grid.pushWindowUp()
end

function M.pushWindowDown()
	hs.grid.pushWindowDown()
end

function M.pushWindowLeft()
	hs.grid.pushWindowLeft()
end

function M.pushWindowRight()
	hs.grid.pushWindowRight()
end

function M.resizeWindowThinner()
	hs.grid.resizeWindowThinner()
end

function M.resizeWindowWider()
	hs.grid.resizeWindowWider()
end

function M.resizeWindowShorter()
	hs.grid.resizeWindowShorter()
end

function M.resizeWindowTaller()
	hs.grid.resizeWindowTaller()
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

	hs.grid.snap(win)
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
	hs.grid.maximizeWindow()
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
