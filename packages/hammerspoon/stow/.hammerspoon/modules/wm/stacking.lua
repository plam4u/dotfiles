local M = {}

function M.setup(config)
	M.config = config or {}
	M.logger = hs.logger.new("stacking", "debug")
	M.bindHotkeys(M.config.mapping or {})
end

function M.bindHotkeys(mapping)
	for action, hotkey in pairs(mapping) do
		local handler = M[action]

		if type(handler) ~= "function" then
			M.logger.e("Unknown stacking action: " .. tostring(action))
		else
			hs.hotkey.bind(hotkey[1], hotkey[2], handler)
		end
	end
end

return M
