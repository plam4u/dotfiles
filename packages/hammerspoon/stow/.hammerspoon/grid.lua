local M = {}

function M.setup(config)
	M.config = config or {}
	M.bindHotkeys(M.config.mapping or {})
end

function M.bindHotkeys(mapping)
	if mapping.blah then
		hs.hotkey.bind(mapping.hide.mods, mapping.hide.key, function()
			hs.alert.show("blah")
		end)
	end
end

hs.grid.setGrid("8x8")
hs.grid.setMargins("0,0")
hs.window.animationDuration = 0

-- local function toggleMenuBar()
-- 	cmd = [[
--     tell application "System Preferences"
--         reveal pane id "com.apple.preference.dock"
--         delay 1
--         tell application "System Events"
--             activate
--             click checkbox "Automatically hide and show the menu bar on desktop" of window "Dock & Menu Bar" of process "System Preferences"
--         end tell
--     end tell
--     ]]
-- 	hs.osascript.applescript(cmd)
-- end
-- hs.hotkey.bind(mash, "m", toggleMenuBar)

local function getWin()
	return hs.window.focusedWindow()
end

local function centeredQHDWindow()
	local win = hs.window.focusedWindow()
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

local function sideQHDWindow(side)
	local win = hs.window.focusedWindow()
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
	-- f.x = (max.w - targetW) / 2
	f.y = (max.h - targetH) / 2
	f.w = targetW
	f.h = targetH
	win:setFrame(f)
end

local function wideCenteredWindow(isFullHeight)
	local win = hs.window.focusedWindow()
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

local function tileWindow(posRatio, sizeRatio)
	local win = hs.window.focusedWindow()
	local f = win:frame()
	local screen = win:screen()
	local max = screen:frame()
	local segment = max.w / 7
	f.x = posRatio * max.w
	f.w = sizeRatio * max.w
	f.y = 0
	f.h = max.h
	win:setFrame(f)
end

--- auto position windows
-- local wf = hs.window.filter
-- wf_left = wf.new {'Mail'}
-- wf_center = wf.new {'iTerm2', 'Chrome', 'Xcode', 'Slack'}
-- wf_right = wf.new {'Safari', 'Podcasts', 'Firefox', 'NetNewsWire', 'Preview'}
-- wf_left:subscribe(wf.windowOnScreen, function() tileWindow(0, 2/7) end)
-- wf_center:subscribe(wf.windowOnScreen, function() tileWindow(2/7, 3/7) end)
-- wf_right:subscribe(wf.windowOnScreen, function() tileWindow(5/7, 2/7) end)
--
-- --- special case positioning
-- wf.new { 'Calendar' }:subscribe(wf.windowOnScreen, function()
--     tileWindow(0, 4/21)
-- end)
-- wf.new { 'Reminders' }:subscribe(wf.windowOnScreen, function()
--     tileWindow(4/21, 2/21)
-- end)
-- wf.new { 'Telegram' }:subscribe(wf.windowOnScreen, function()
--     tileWindow(5/7, 1/7)
-- end)
-- wf.new { 'Messages' }:subscribe(wf.windowOnScreen, function()
--     tileWindow(6/7, 1/7)
-- end)
--
-- local function focusWindow(direction)
-- 	local win = hs.window.focusedWindow()
-- 	if not win then
-- 		return
-- 	end
--
-- 	local focus = {
-- 		h = win.focusWindowWest,
-- 		j = win.focusWindowSouth,
-- 		k = win.focusWindowNorth,
-- 		l = win.focusWindowEast,
-- 	}
--
-- 	focus[direction](win)
-- end
--
-- for _, key in ipairs({ "h", "j", "k", "l" }) do
-- 	hs.hotkey.bind({ "alt" }, key, function()
-- 		focusWindow(key)
-- 	end)
-- end

-- local wf = hs.window.filter.defaultCurrentSpace
--
-- local directions = {
-- 	h = "West",
-- 	j = "South",
-- 	k = "North",
-- 	l = "East",
-- }
--
-- for key, direction in pairs(directions) do
-- 	hs.hotkey.bind({ "alt" }, key, function()
-- 		wf["focusWindow" .. direction](wf, nil, false, true)
-- 	end)
-- end

hs.hotkey.bind({ "alt" }, "h", hs.window.filter.focusWest)
hs.hotkey.bind({ "alt" }, "j", hs.window.filter.focusSouth)
hs.hotkey.bind({ "alt" }, "k", hs.window.filter.focusNorth)
hs.hotkey.bind({ "alt" }, "l", hs.window.filter.focusEast)

--- arrows: move window
hs.hotkey.bind(meh, "k", function()
	hs.grid.pushWindowUp()
end)
hs.hotkey.bind(meh, "j", function()
	hs.grid.pushWindowDown()
end)
hs.hotkey.bind(meh, "h", function()
	hs.grid.pushWindowLeft()
end)
hs.hotkey.bind(meh, "l", function()
	hs.grid.pushWindowRight()
end)

--- ikjl: resize window
hs.hotkey.bind(hyper, "h", function()
	hs.grid.resizeWindowThinner()
end)
hs.hotkey.bind(hyper, "l", function()
	hs.grid.resizeWindowWider()
end)
hs.hotkey.bind(hyper, "k", function()
	hs.grid.resizeWindowShorter()
end)
hs.hotkey.bind(hyper, "j", function()
	hs.grid.resizeWindowTaller()
end)

--- left - center - right
--- |--|---|--|
hs.hotkey.bind(meh, "u", function()
	-- tileWindow(0, 2 / 7)
	sideQHDWindow("left")
end) -- left
hs.hotkey.bind(meh, "i", function()
	-- tileWindow(2 / 7, 3 / 7)
	centeredQHDWindow()
end) -- center
hs.hotkey.bind(meh, "o", function()
	-- tileWindow(5 / 7, 2 / 7)
	sideQHDWindow("right")
end) -- right

--- 234: resize grid
hs.hotkey.bind(meh, "2", function()
	hs.grid.setGrid("2x2")
	hs.alert.show("Grid set to 2x2")
end)
hs.hotkey.bind(meh, "3", function()
	hs.grid.setGrid("3x3")
	hs.alert.show("Grid set to 3x3")
end)
hs.hotkey.bind(meh, "4", function()
	hs.grid.setGrid("4x4")
	hs.alert.show("Grid set to 4x4")
end)
hs.hotkey.bind(meh, "6", function()
	hs.grid.setGrid("6x6")
	hs.alert.show("Grid set to 6x6")
end)
hs.hotkey.bind(meh, "7", function()
	hs.grid.setGrid("7x7")
	hs.alert.show("Grid set to 7x7")
end)
hs.hotkey.bind(meh, "8", function()
	hs.grid.setGrid("8x8")
	hs.alert.show("Grid set to 8x8")
end)
hs.hotkey.bind(meh, "9", function()
	hs.grid.setGrid("9x9")
	hs.alert.show("Grid set to 9x9")
end)
hs.hotkey.bind(meh, "0", function()
	hs.grid.setGrid("10x10")
	hs.alert.show("Grid set to 10x10")
end)
hs.hotkey.bind(meh, "5", function()
	wideCenteredWindow(false)
end)
hs.hotkey.bind(hyper, "5", function()
	wideCenteredWindow(true)
end)
hs.hotkey.bind(meh, "6", function()
	-- centeredQHDWindow()
	tileWindow(2 / 7, 3 / 7)
end)

--- /: move window to next screen
hs.hotkey.bind(meh, "/", function()
	local win = getWin()
	win:moveToScreen(win:screen():next())
end)

--- ,: snap window to grid
hs.hotkey.bind(meh, ",", function()
	hs.grid.snap(getWin())
end)
hs.hotkey.bind(meh, "t", function()
	local win = getWin()
	win:centerOnScreen()
end)

--- space: maximize window
hs.hotkey.bind(meh, "space", function()
	hs.grid.maximizeWindow()
end)
hs.hotkey.bind(meh, "n", function()
	hs.grid.maximizeWindow()
end)

--- .: minimize window
hs.hotkey.bind(meh, ".", function()
	local win = getWin()
	if not win then
		return
	end

	local f = win:frame()

	-- preserve position, only change size
	-- hs.alert.show(string.format("x=%d y=%d w=%d h=%d", f.x, f.y, f.w, f.h))
	f.w = 640
	f.h = 480

	win:setFrame(f)
end)
return M
