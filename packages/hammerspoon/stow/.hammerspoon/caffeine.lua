local M = {}

function M.setup(config)
	M.config = config or {}
	M.logger = hs.logger.new("caffeine", "debug")

	local resources = hs.configdir .. "/resources"
	M.icons = {
		sleepy = hs.image.imageFromPath(resources .. "/coffee.empty.16.png"),
		awake = hs.image.imageFromPath(resources .. "/coffee.fill.16.png"),
	}
	M.shouldDisplayTitle = hs.settings.get("caffeine.shouldDisplayTitle") or false

	M.caffeine = hs.menubar.new()
	if not M.caffeine then
		M.logger.e("Failed to create caffeine menubar item")
		return
	end

	local savedState = hs.settings.get("caffeine.state")
	if savedState ~= nil then
		hs.caffeinate.set("displayIdle", savedState)
	end

	M.caffeine:setClickCallback(function(mods)
		M.caffeineClicked(mods)
	end)
	M.setCaffeineDisplay(hs.caffeinate.get("displayIdle"))
	M.bindHotkeys(M.config.mapping or {})
end

function M.bindHotkeys(mapping)
	for action, hotkey in pairs(mapping) do
		local handler = M[action]

		if type(handler) ~= "function" then
			M.logger.e("Unknown caffeine action: " .. tostring(action))
		else
			hs.hotkey.bind(hotkey[1], hotkey[2], handler)
		end
	end
end

function M.setCaffeineDisplay(state)
	if state then
		M.caffeine:setIcon(M.icons.awake)
		M.caffeine:setTitle(M.shouldDisplayTitle and "Awake" or nil)
	else
		M.caffeine:setIcon(M.icons.sleepy)
		M.caffeine:setTitle(M.shouldDisplayTitle and "Sleepy" or nil)
	end
end

function M.caffeineClicked(mods)
	if mods.alt then
		M.shouldDisplayTitle = not M.shouldDisplayTitle

		hs.settings.set("caffeine.shouldDisplayTitle", M.shouldDisplayTitle)

		M.setCaffeineDisplay(hs.caffeinate.get("displayIdle"))
	else
		local state = hs.caffeinate.toggle("displayIdle")

		hs.settings.set("caffeine.state", state)

		M.setCaffeineDisplay(state)
	end
end

function M.toggle()
	M.caffeineClicked({})

	hs.alert.show("Caffeine: " .. (hs.caffeinate.get("displayIdle") and "Awake" or "Sleepy"))
end

return M
