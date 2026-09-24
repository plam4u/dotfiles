local hotkeys = require("modules.wm.hotkeys")
local stacking = require("modules.wm.stacking")
local borders = require("modules.wm.borders")

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
end

function M.toggle()
	local suspended = not stacking.isSuspended()
	stacking.setSuspended(suspended)
	hotkeys.setEnabled(not suspended)
	if not suspended then borders.ensureRunning() end
	hs.alert.show(suspended and "Window manager paused" or "Window manager resumed")
end

return M
