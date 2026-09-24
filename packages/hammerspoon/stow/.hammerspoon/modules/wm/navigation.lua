local M = {}
local stacking = require("modules.wm.stacking")
local hotkeys = require("modules.wm.hotkeys")

function M.setup(config)
	M.config = config or {}
	M.logger = hs.logger.new("navigation", "debug")
	M.bindHotkeys(M.config.mapping or {})
end

function M.bindHotkeys(mapping)
	for action, hotkey in pairs(mapping) do
		local handler = M[action]

		if type(handler) ~= "function" then
			M.logger.e("Unknown navigation action: " .. tostring(action))
		else
			hotkeys.bind(hotkey[1], hotkey[2], handler)
		end
	end
end

function M.focusWest()
	stacking.focusWest()
end

function M.focusSouth()
	stacking.focusSouth()
end

function M.focusNorth()
	stacking.focusNorth()
end

function M.focusEast()
	stacking.focusEast()
end

function M.focusPreviousWorkspace()
	stacking.focusPreviousWorkspace()
end

function M.focusNextWorkspace()
	stacking.focusNextWorkspace()
end

function M.focusDirectionalNorth()
	stacking.focusDirectionalNorth()
end

function M.focusDirectionalSouth()
	stacking.focusDirectionalSouth()
end

return M
