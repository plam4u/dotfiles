local M = {}
local stacking = require("modules.wm.stacking")

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
			hs.hotkey.bind(hotkey[1], hotkey[2], handler)
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

function M.focusPreviousGroup()
	stacking.focusPreviousGroup()
end

function M.focusNextGroup()
	stacking.focusNextGroup()
end

function M.focusDirectionalNorth()
	hs.window.filter.focusNorth()
end

function M.focusDirectionalSouth()
	hs.window.filter.focusSouth()
end

return M
