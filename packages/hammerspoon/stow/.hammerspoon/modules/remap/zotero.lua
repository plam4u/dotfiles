local M = {
	bundleID = "org.zotero.zotero",
	swallowedKeys = {},
}

local editableRoles = {
	AXComboBox = true,
	AXSearchField = true,
	AXSecureTextField = true,
	AXTextArea = true,
	AXTextField = true,
}

local defaultMappings = {
	pdf = {
		h = { { "alt" }, "up" },
		j = { {}, "space" },
		k = { { "shift" }, "space" },
		l = { { "alt" }, "down" },
	},
	epub = {
		h = { {}, "left" },
		j = { {}, "space" },
		k = { { "shift" }, "space" },
		l = { {}, "right" },
	},
}

local function attribute(element, name)
	if not element then
		return nil
	end
	local ok, value = pcall(element.attributeValue, element, name)
	if not ok then
		return nil
	end
	return value
end

local function hasActionModifiers(flags)
	return flags.cmd or flags.ctrl or flags.alt or flags.shift or flags.fn
end

local function readerContext()
	local app = hs.application.frontmostApplication()
	if not app or app:bundleID() ~= M.bundleID then
		return nil
	end

	local applicationElement = hs.axuielement.applicationElement(app)
	local element = attribute(applicationElement, "AXFocusedUIElement")
	local seen = {}
	for _ = 1, M.maxAncestorDepth do
		if not element then
			break
		end
		local identity = tostring(element)
		if seen[identity] then
			break
		end
		seen[identity] = true

		local role = attribute(element, "AXRole")
		if editableRoles[role] then
			return nil
		end
		if role == "AXWebArea" then
			local description = attribute(element, "AXDescription")
			if description == "PDF.js viewer" then
				return "pdf"
			end
			if description == "about:srcdoc" then
				return "epub"
			end
		end
		element = attribute(element, "AXParent")
	end
	return nil
end

local function keyName(event)
	local code = event:getKeyCode()
	for _, name in ipairs({ "h", "j", "k", "l" }) do
		if hs.keycodes.map[name] == code then
			return name, code
		end
	end
	return nil, code
end

local function handleKeyEvent(event)
	local eventTypes = hs.eventtap.event.types
	local name, code = keyName(event)
	if not name then
		return false
	end

	if event:getType() == eventTypes.keyUp then
		if M.swallowedKeys[code] then
			M.swallowedKeys[code] = nil
			return true
		end
		return false
	end

	if hasActionModifiers(event:getFlags()) then
		return false
	end
	local context = readerContext()
	local mapping = context and M.mappings[context] and M.mappings[context][name]
	if not mapping then
		return false
	end

	M.swallowedKeys[code] = true
	hs.eventtap.keyStroke(mapping[1], mapping[2], 0)
	return true
end

function M.setup(config)
	config = config or {}
	M.bundleID = config.bundleID or M.bundleID
	M.maxAncestorDepth = config.maxAncestorDepth or 20
	M.mappings = config.mapping or defaultMappings

	if M.eventTap then
		M.eventTap:stop()
	end
	M.swallowedKeys = {}
	M.eventTap = hs.eventtap.new({
		hs.eventtap.event.types.keyDown,
		hs.eventtap.event.types.keyUp,
	}, handleKeyEvent)
	M.eventTap:start()
	return M
end

return M
