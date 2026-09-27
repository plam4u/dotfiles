local M = {
	handlers = {},
	orderedHandlers = {},
	keyNames = {},
	swallowedKeys = {},
}

local function hasActionModifiers(flags)
	return flags.cmd or flags.ctrl or flags.alt or flags.shift or flags.fn
end

local function rebuildIndex()
	M.orderedHandlers = {}
	M.keyNames = {}
	for _, handler in pairs(M.handlers) do
		table.insert(M.orderedHandlers, handler)
		for key in pairs(handler.keys) do
			local code = hs.keycodes.map[key]
			if code then
				M.keyNames[code] = key
			end
		end
	end
	table.sort(M.orderedHandlers, function(left, right)
		if left.priority == right.priority then
			return left.name < right.name
		end
		return left.priority > right.priority
	end)
end

local function invoke(handler, callback, key, event)
	if type(callback) ~= "function" then
		return false
	end
	local ok, handled = pcall(callback, key, event)
	if not ok then
		M.logger.e(string.format("Keyboard handler %s failed: %s", handler.name, tostring(handled)))
		return false
	end
	return handled == true
end

local function isActive(handler, key, event)
	if type(handler.active) ~= "function" then
		return true
	end
	local ok, active = pcall(handler.active, key, event)
	if not ok then
		M.logger.e(string.format("Keyboard predicate %s failed: %s", handler.name, tostring(active)))
		return false
	end
	return active == true
end

local function handleEvent(event)
	local eventTypes = hs.eventtap.event.types
	local code = event:getKeyCode()
	local ownerName = M.swallowedKeys[code]

	if event:getType() == eventTypes.keyUp then
		if not ownerName then
			return false
		end
		local owner = M.handlers[ownerName]
		if owner then
			invoke(owner, owner.released, M.keyNames[code], event)
		end
		M.swallowedKeys[code] = nil
		return true
	end

	local key = M.keyNames[code]
	if not key then
		return false
	end
	local isRepeat = event:getProperty(hs.eventtap.event.properties.keyboardEventAutorepeat) == 1
	if isRepeat and ownerName then
		local owner = M.handlers[ownerName]
		if owner then
			invoke(owner, owner.repeated or owner.pressed, key, event)
		end
		return true
	end

	local flags = event:getFlags()
	for _, handler in ipairs(M.orderedHandlers) do
		if
			handler.keys[key]
			and (handler.allowModifiers or not hasActionModifiers(flags))
			and isActive(handler, key, event)
			and invoke(handler, handler.pressed, key, event)
		then
			M.swallowedKeys[code] = handler.name
			return true
		end
	end
	return false
end

function M.register(name, options)
	options = options or {}
	local keys = {}
	for _, key in ipairs(options.keys or {}) do
		keys[key] = true
	end
	M.handlers[name] = {
		name = name,
		priority = options.priority or 0,
		keys = keys,
		allowModifiers = options.allowModifiers == true,
		active = options.active,
		pressed = options.pressed,
		repeated = options.repeated,
		released = options.released,
	}
	rebuildIndex()
	return M.handlers[name]
end

function M.unregister(name)
	M.handlers[name] = nil
	for code, ownerName in pairs(M.swallowedKeys) do
		if ownerName == name then
			M.swallowedKeys[code] = nil
		end
	end
	rebuildIndex()
end

function M.setup()
	M.logger = M.logger or hs.logger.new("keyboard", "info")
	if M.eventTap then
		M.eventTap:stop()
	end
	M.swallowedKeys = {}
	M.eventTap = hs.eventtap.new({
		hs.eventtap.event.types.keyDown,
		hs.eventtap.event.types.keyUp,
	}, handleEvent)
	M.eventTap:start()
	return M
end

return M
