local M = {}
local hotkeys = require("modules.wm.hotkeys")

function M.setup(config)
	M.config = config or {}
	M.logger = hs.logger.new("apps", "debug")
	M.bindHotkeys(M.config.mapping or {})

	hs.urlevent.bind("toggle-app-by-id", function(_, params)
		M.toggleAppByID(params.id)
	end)

	-- use Spotlight metadata when resolving applications by name
	hs.application.enableSpotlightForNameSearches(true)
	hs.urlevent.bind("toggle-app-by-name", function(_, params)
		M.toggleAppByName(params.name)
	end)
end

function M.bindHotkeys(mapping)
	for action, hotkey in pairs(mapping) do
		local handler = M[action]

		if type(handler) ~= "function" then
			M.logger.e("Unknown caffeine action: " .. tostring(action))
		else
			hotkeys.bind(hotkey[1], hotkey[2], handler)
		end
	end
end

function M.hideApp()
	local app = hs.application.frontmostApplication()
	if app then
		app:hide()
	end
end

function M.toggleAppByID(bundleID)
	local bundle = hs.application.applicationsForBundleID(bundleID)
	local app = bundle[1]
	if not app or app:isHidden() then
		hs.application.launchOrFocusByBundleID(bundleID)
	elseif hs.application.frontmostApplication() ~= app then
		app:activate()
	else
		if bundleID == "company.thebrowser.Browser" then
			hs.eventtap.keyStroke({ "cmd" }, "h", 0, app)
		else
			app:hide()
		end
	end
end

-- Deprecated: use toggleAppByID instead
function M.toggleAppByName(name)
	M.logger.e("toggleAppByName() is deprecated; use toggleAppByID() instead")
	local app = hs.application.find(name)
	if not app or app:isHidden() then
		hs.application.launchOrFocus(name)
	elseif hs.application.frontmostApplication() ~= app then
		app:activate()
	else
		app:hide()
	end
end

return M
