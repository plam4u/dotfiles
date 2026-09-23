local M = {}

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

return M
