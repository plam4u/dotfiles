local M = {}

function M.setup(config)
	M.config = config or {}
	M.logger = hs.logger.new("grid", "debug")

	hs.grid.setGrid("8x8")
	hs.grid.setMargins("0,0")
	hs.window.animationDuration = 0

	M.bindHotkeys(M.config.mapping or {})
end

function M.bindHotkeys(mapping)
	for _, binding in ipairs(mapping) do
		local action = binding[1]
		local mods = binding[2]
		local key = binding[3]
		local fn = M[action]

		if type(fn) ~= "function" then
			M.logger.e("Unknown grid action: " .. tostring(action))
		else
			hs.hotkey.bind(mods, key, fn)
		end
	end
end

function M.getWin()
	return hs.window.focusedWindow()
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

function M.focusWest()
	hs.window.filter.focusWest()
end

function M.focusSouth()
	hs.window.filter.focusSouth()
end

function M.focusNorth()
	hs.window.filter.focusNorth()
end

function M.focusEast()
	hs.window.filter.focusEast()
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

function M.setGrid2()
	M.setGrid("2x2")
end

function M.setGrid3()
	M.setGrid("3x3")
end

function M.setGrid4()
	M.setGrid("4x4")
end

function M.setGrid6()
	M.setGrid("6x6")
end

function M.setGrid7()
	M.setGrid("7x7")
end

function M.setGrid8()
	M.setGrid("8x8")
end

function M.setGrid9()
	M.setGrid("9x9")
end

function M.setGrid10()
	M.setGrid("10x10")
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

	win:centerOnScreen()
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
