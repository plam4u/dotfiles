hs.grid.setGrid'7x7'
hs.grid.setMargins("0,0")
hs.window.animationDuration = 0

function toggleMenuBar()
    cmd = [[
    tell application "System Preferences"
        reveal pane id "com.apple.preference.dock"
        delay 1
        tell application "System Events"
            activate
            click checkbox "Automatically hide and show the menu bar on desktop" of window "Dock & Menu Bar" of process "System Preferences"
        end tell
    end tell
    ]]
    hs.osascript.applescript(cmd)
end

function getWin()
  return hs.window.focusedWindow()
end

function wideCenteredWindow(isFullHeight)
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

function tileWindow(posRatio, sizeRatio)
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

--- arrows: move window
hs.hotkey.bind(mash, "k", function() hs.grid.pushWindowUp() end)
hs.hotkey.bind(mash, "j", function() hs.grid.pushWindowDown() end)
hs.hotkey.bind(mash, "h", function() hs.grid.pushWindowLeft() end)
hs.hotkey.bind(mash, "l", function() hs.grid.pushWindowRight() end)

--- ikjl: resize window
hs.hotkey.bind(mash2, "h", function() hs.grid.resizeWindowThinner() end)
hs.hotkey.bind(mash2, "l", function() hs.grid.resizeWindowWider() end)
hs.hotkey.bind(mash2, "k", function() hs.grid.resizeWindowShorter() end)
hs.hotkey.bind(mash2, "j", function() hs.grid.resizeWindowTaller() end)

--- left - center - right
--- |--|---|--|
hs.hotkey.bind(mash, "u", function() tileWindow(0, 2/7) end)    -- left
hs.hotkey.bind(mash, "i", function() tileWindow(2/7, 3/7) end)  -- center
hs.hotkey.bind(mash, "o", function() tileWindow(5/7, 2/7) end)  -- right

--- 234: resize grid
hs.hotkey.bind(mash, "2", function() hs.grid.setGrid('2x2'); hs.alert.show('Grid set to 2x2'); end)
hs.hotkey.bind(mash, "3", function() hs.grid.setGrid('3x3'); hs.alert.show('Grid set to 3x3'); end)
hs.hotkey.bind(mash, "4", function() hs.grid.setGrid('4x4'); hs.alert.show('Grid set to 4x4'); end)
hs.hotkey.bind(mash, "6", function() hs.grid.setGrid('6x6'); hs.alert.show('Grid set to 6x6'); end)
hs.hotkey.bind(mash, "7", function() hs.grid.setGrid('7x7'); hs.alert.show('Grid set to 7x7'); end)
hs.hotkey.bind(mash, "8", function() hs.grid.setGrid('8x8'); hs.alert.show('Grid set to 8x8'); end)
hs.hotkey.bind(mash, "9", function() hs.grid.setGrid('9x9'); hs.alert.show('Grid set to 9x9'); end)
hs.hotkey.bind(mash, "0", function() hs.grid.setGrid('10x10'); hs.alert.show('Grid set to 10x10'); end)
hs.hotkey.bind(mash, "5", function() wideCenteredWindow(false); end)
hs.hotkey.bind(mash2, "5", function() wideCenteredWindow(true); end)

--- /: move window to next screen
hs.hotkey.bind(mash, "/", function() local win = getWin(); win:moveToScreen(win:screen():next()) end)

--- ,: snap window to grid
hs.hotkey.bind(mash, ",", function() hs.grid.snap(getWin()) end)
hs.hotkey.bind(mash, "t", function() local win = getWin(); win:centerOnScreen(); end)
-- hs.hotkey.bind(mash, "m", toggleMenuBar)

--- space: maximize window
hs.hotkey.bind(mash, "space", function() hs.grid.maximizeWindow() end)
hs.hotkey.bind(mash, "n", function() hs.grid.maximizeWindow() end)

--- .: minimize window
hs.hotkey.bind(mash, ".", function() hs.grid.set(getWin(), '0,0 1x1'); end)
