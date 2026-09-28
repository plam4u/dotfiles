local M = {
	hotkeys = {},
}

local function appendUnique(target, seen, values)
	for _, value in ipairs(values or {}) do
		if type(value) == "string" and value ~= "" and not seen[value] then
			table.insert(target, value)
			seen[value] = true
		end
	end
end

function M.enabledSources()
	if type(M.config.sources) == "table" then
		return M.config.sources
	end

	local sources = {}
	local seen = {}
	appendUnique(sources, seen, hs.keycodes.layouts(true))
	if M.config.includeInputMethods then
		appendUnique(sources, seen, hs.keycodes.methods(true))
	end
	return sources
end

function M.cycle()
	local sources = M.enabledSources()
	if #sources < 2 then
		local message = #sources == 0
			and "No input languages are enabled"
			or "Only one input language is enabled"
		M.logger.w(message)
		hs.alert.show(message)
		return false
	end

	local current = hs.keycodes.currentSourceID()
	local nextIndex = 1
	for index, sourceID in ipairs(sources) do
		if sourceID == current then
			nextIndex = index % #sources + 1
			break
		end
	end

	local target = sources[nextIndex]
	if not hs.keycodes.currentSourceID(target) then
		M.logger.w("Unable to select input source: " .. target)
		return false
	end
	hs.alert.show(hs.keycodes.currentLayout() or target)
	return true
end

function M.setup(config)
	M.config = config or {}
	M.logger = hs.logger.new("input-source", M.config.logLevel or "info")

	for action, hotkey in pairs(M.config.mapping or {}) do
		local handler = M[action]
		if type(handler) ~= "function" then
			M.logger.e("Unknown input-source action: " .. tostring(action))
		elseif type(hotkey) == "table" then
			table.insert(M.hotkeys, hs.hotkey.bind(hotkey[1], hotkey[2], handler))
		end
	end
	return M
end

return M
