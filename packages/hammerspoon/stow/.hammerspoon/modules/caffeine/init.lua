local M = { subscribers = {} }

function M.getState()
	return { enabled = M.state == true, mode = M.mode or "idle", keepDisplayOn = M.keepDisplayOn == true, showLabel = M.showLabel ~= false }
end

function M.statusLabel()
	if not M.state then return "Off" end
	return (M.mode == "system" and "System (AC)" or "Idle")
		.. (M.keepDisplayOn and " · Display on" or " · Display sleep allowed")
end

function M.refresh()
	if M.caffeine then
		M.caffeine:setIcon(M.state and M.icons.awake or M.icons.sleepy)
		M.caffeine:setTitle(M.shouldDisplayTitle and M.statusLabel() or "")
		M.caffeine:setTooltip("Caffeine: " .. M.statusLabel())
	end
	for _, callback in ipairs(M.subscribers) do
		local ok, err = pcall(callback, M.getState())
		if not ok then M.logger.e("Caffeine subscriber failed: " .. tostring(err)) end
	end
end

function M.subscribe(callback)
	if type(callback) ~= "function" then return false end
	table.insert(M.subscribers, callback)
	callback(M.getState())
	return true
end

function M.apply()
	-- Acquire the selected assertion before releasing the previous mode.
	local selected = M.mode == "system" and "system" or "systemIdle"
	local previous = M.mode == "system" and "systemIdle" or "system"
	hs.caffeinate.set(selected, M.state, false)
	hs.caffeinate.set("displayIdle", M.state and M.keepDisplayOn)
	hs.caffeinate.set(previous, false)
	hs.settings.set("caffeine.state", M.state)
	hs.settings.set("caffeine.mode", M.mode)
	hs.settings.set("caffeine.keepDisplayOn", M.keepDisplayOn)
	M.refresh()
end

function M.setMode(mode)
	assert(mode == "idle" or mode == "system", "Invalid caffeine mode")
	M.mode = mode
	M.apply()
end

function M.toggleMode()
	M.setMode(M.mode == "idle" and "system" or "idle")
end

function M.toggleLabel()
	M.showLabel = not M.showLabel
	hs.settings.set("caffeine.showLabel", M.showLabel)
	M.refresh()
end

function M.toggleDisplay()
	M.keepDisplayOn = not M.keepDisplayOn
	M.apply()
end

function M.menuItems()
	return {
		{ title = "Caffeine: " .. M.statusLabel(), disabled = true },
		{ title = "Enabled", checked = M.state, fn = M.toggle },
		{ title = "-" },
		{ title = "Prevent idle sleep (-i)", checked = M.mode == "idle", fn = function() M.setMode("idle") end },
		{ title = "Prevent system sleep (-s, AC only)", checked = M.mode == "system", fn = function() M.setMode("system") end },
		{ title = "Keep display on (-d)", checked = M.keepDisplayOn, fn = M.toggleDisplay },
	}
end

function M.showMenu()
	if M.menu then
		M.menu:setMenu(M.menuItems())
		M.menu:popupMenu(hs.mouse.absolutePosition())
	end
end

function M.caffeineClicked(mods)
	mods = mods or {}
	if mods.ctrl then
		M.showMenu()
	elseif mods.alt then
		M.shouldDisplayTitle = not M.shouldDisplayTitle
		hs.settings.set("caffeine.shouldDisplayTitle", M.shouldDisplayTitle)
		M.refresh()
	else
		M.state = not M.state
		M.apply()
	end
end

function M.toggle()
	M.caffeineClicked({})
	hs.alert.show("Caffeine: " .. M.statusLabel())
end

function M.bindHotkeys(mapping)
	for action, hotkey in pairs(mapping) do
		if type(M[action]) == "function" then
			hs.hotkey.bind(hotkey[1], hotkey[2], M[action])
		else
			M.logger.e("Unknown caffeine action: " .. tostring(action))
		end
	end
end

function M.setup(config)
	M.config = config or {}
	M.logger = hs.logger.new("caffeine", "debug")
	local assets = hs.configdir .. "/modules/caffeine/assets"
	M.icons = {
		sleepy = hs.image.imageFromPath(assets .. "/coffee.empty.16.png"),
		awake = hs.image.imageFromPath(assets .. "/coffee.fill.16.png"),
	}
	M.showLabel = hs.settings.get("caffeine.showLabel")
	if M.showLabel == nil then M.showLabel = M.config.showLabel ~= false end
	M.shouldDisplayTitle = hs.settings.get("caffeine.shouldDisplayTitle") or false
	M.mode = hs.settings.get("caffeine.mode") or M.config.mode or "idle"
	if M.mode ~= "idle" and M.mode ~= "system" then M.mode = "idle" end
	M.keepDisplayOn = hs.settings.get("caffeine.keepDisplayOn")
	if M.keepDisplayOn == nil then M.keepDisplayOn = M.config.keepDisplayOn == true end
	M.state = hs.settings.get("caffeine.state")
	if M.state == nil then M.state = M.config.enabled == true end
	M.caffeine = hs.menubar.new()
	M.menu = hs.menubar.new(false)
	if M.caffeine then
		M.caffeine:setClickCallback(function(mods)
			if hs.eventtap.checkMouseButtons().right then M.showMenu()
			else M.caffeineClicked(mods) end
		end)
	end
	M.apply()
	M.bindHotkeys(M.config.mapping or {})
end

return M
