local M = {
	hotkeys = {},
	subscribers = {},
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

function M.currentState()
	local sourceID = hs.keycodes.currentSourceID()
	local name = hs.keycodes.currentLayout() or hs.keycodes.currentMethod() or sourceID or "Unknown"
	local labels = M.config.labels or {}
	return {
		id = sourceID,
		name = name,
		label = labels[sourceID] or labels[name] or name,
	}
end

function M.publish()
	M.state = M.currentState()
	for _, subscriber in ipairs(M.subscribers) do
		local ok, err = pcall(subscriber, M.state)
		if not ok then
			M.logger.e("Input-source subscriber failed: " .. tostring(err))
		end
	end
end

function M.subscribe(callback)
	if type(callback) ~= "function" then return false end
	table.insert(M.subscribers, callback)
	callback(M.state or M.currentState())
	return true
end

function M.cycle(direction)
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
	local step = tonumber(direction) or 1
	for index, sourceID in ipairs(sources) do
		if sourceID == current then
			nextIndex = (index - 1 + step) % #sources + 1
			break
		end
	end

	local target = sources[nextIndex]
	if not hs.keycodes.currentSourceID(target) then
		M.logger.w("Unable to select input source: " .. target)
		return false
	end
	local state = M.currentState()
	hs.alert.show(state.name)
	return true
end

function M.setup(config)
	M.config = config or {}
	M.logger = hs.logger.new("input-source", M.config.logLevel or "info")
	hs.keycodes.inputSourceChanged(M.publish)
	M.publish()

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
