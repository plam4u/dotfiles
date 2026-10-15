local hotkeys = require("modules.wm.hotkeys")
local stacking = require("modules.wm.stacking")
local borders = require("modules.wm.borders")
local keyboard = require("modules.keyboard")
local sketchybar = require("modules.wm.sketchybar")

local M = {}

function M.setup(config)
	M.config = config or {}
	M.logger = hs.logger.new("wm-control", "info")

	for action, hotkey in pairs(M.config.mapping or {}) do
		local handler = M[action]

		if type(handler) ~= "function" then
			M.logger.e("Unknown WM control action: " .. tostring(action))
		else
			hotkeys.bind(hotkey[1], hotkey[2], handler, { persistent = true })
		end
	end
	M.startSessionWatcher()
end

function M.cancelRecovery()
	for _, timer in ipairs(M.recoveryTimers or {}) do timer:stop() end
	M.recoveryTimers = {}
end

function M.recoverSession()
	-- Re-enable taps/hotkeys after the login screen releases secure input.
	keyboard.setup()
	hotkeys.setEnabled(not stacking.isSuspended())
	stacking.recoverSession()
	if not stacking.isSuspended() then borders.ensureRunning() end
	sketchybar.recoverSession()
end

function M.startSessionWatcher()
	M.cancelRecovery()
	if M.sessionWatcher then M.sessionWatcher:stop() end
	local events = hs.caffeinate.watcher
	M.sessionWatcher = events.new(function(event)
		local leaving = event == events.systemWillSleep or event == events.screensDidSleep
			or event == events.screensDidLock or event == events.sessionDidResignActive
		local returning = event == events.systemDidWake or event == events.screensDidWake
			or event == events.screensDidUnlock or event == events.sessionDidBecomeActive
		if not leaving and not returning then return end
		M.cancelRecovery()
		-- A bar modal left open before sleep must not capture keys after login.
		hotkeys.runBeforeHandlers()
		if leaving then return end
		-- Wake, display reconnect, and unlock arrive separately. Debounce those
		-- events and retry while macOS restores displays and Accessibility windows.
		for _, delay in ipairs(M.config.recoveryDelays or { 1, 3, 8 }) do
			table.insert(M.recoveryTimers, hs.timer.doAfter(delay, function()
				local ok, err = pcall(M.recoverSession)
				if not ok then M.logger.e("Session recovery failed: " .. tostring(err)) end
			end))
		end
	end)
	M.sessionWatcher:start()
end

function M.toggle()
	local suspended = not stacking.isSuspended()
	stacking.setSuspended(suspended)
	hotkeys.setEnabled(not suspended)
	if not suspended then borders.ensureRunning() end
	hs.alert.show(suspended and "Window manager paused" or "Window manager resumed")
end

return M
