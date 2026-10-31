-- Shared by automatic stacking, restoration, and manual layout commands.
local M = { config = {} }

local function call(object, method, ...)
	if not object then return nil end
	local ok, value = pcall(function(...) return object[method](object, ...) end, ...)
	if ok then return value end
end

function M.setup(config)
	M.config = config or {}
end

function M.describe(window)
	local app = call(window, "application")
	local element
	if hs.axuielement and hs.axuielement.windowElement then
		local ok, value = pcall(hs.axuielement.windowElement, window)
		if ok then element = value end
	end
	return {
		bundleID = call(app, "bundleID"),
		appName = call(app, "name"),
		title = call(window, "title"),
		role = call(window, "role"),
		subrole = call(window, "subrole"),
		modal = call(element, "attributeValue", "AXModal"),
		resizable = call(element, "isAttributeSettable", "AXSize"),
	}
end

local function matches(info, rule)
	for _, key in ipairs({ "bundleID", "appName", "title", "role", "subrole", "modal", "resizable" }) do
		if rule[key] ~= nil and rule[key] ~= info[key] then return false end
	end
	if rule.titlePattern and not (info.title or ""):match(rule.titlePattern) then return false end
	return true
end

function M.isEligible(window, allowFullscreen)
	if not window then return false, "no window" end
	local fullscreen = call(window, "isFullScreen") == true
	if not allowFullscreen and fullscreen then return false, "fullscreen" end
	if call(window, "isStandard") == false then return false, "nonstandard window" end
	local info = M.describe(window)
	for _, rule in ipairs(M.config.exclude or {}) do
		if matches(info, rule) then return false, rule.reason or "configured exception" end
	end
	-- Some apps label transient panels as standard windows. Accessibility
	-- modality and resize support catch these without guessing by window size.
	if info.role and info.role ~= "AXWindow" then return false, "non-window role" end
	if info.subrole and info.subrole ~= "AXStandardWindow" then return false, "nonstandard subrole" end
	if info.modal == true then return false, "modal window" end
	-- Native fullscreen can temporarily make AXSize read-only. Keep its stack
	-- membership during reconciliation, while every layout entry point skips it.
	if info.resizable == false and not (allowFullscreen and fullscreen) then return false, "fixed-size window" end
	-- Unsupported AX attributes return nil; preserve normal app behavior.
	return true
end

return M
