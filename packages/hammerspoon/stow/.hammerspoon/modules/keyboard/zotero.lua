local M = {
	bundleID = "org.zotero.zotero",
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

function M.setup(keyboard, config)
	config = config or {}
	M.bundleID = config.bundleID or M.bundleID
	M.maxAncestorDepth = config.maxAncestorDepth or 20
	M.mappings = config.mapping or defaultMappings
	keyboard.register("zotero-reader", {
		priority = config.priority or 10,
		keys = { "h", "j", "k", "l" },
		pressed = function(key)
			local context = readerContext()
			local mapping = context and M.mappings[context] and M.mappings[context][key]
			if not mapping then
				return false
			end
			hs.eventtap.keyStroke(mapping[1], mapping[2], 0)
			return true
		end,
	})
	return M
end

return M
