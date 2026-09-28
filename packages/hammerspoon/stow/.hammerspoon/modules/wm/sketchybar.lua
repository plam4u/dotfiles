local keyboard = require("modules.keyboard")
local hotkeys = require("modules.wm.hotkeys")
local stacking = require("modules.wm.stacking")
local keyLights = require("modules.wm.sketchybar.key_lights")
local items = require("modules.wm.sketchybar.items")
local plex = require("modules.wm.sketchybar.plex")

local M = {
	active = false,
	selectedIndex = 1,
	navigableItems = {},
	menuItems = {},
	menuIndex = nil,
	menuParent = nil,
	codexFiveHourTimeFormat = "remaining",
	codexWeeklyTimeFormat = "remaining",
}

local staticItems = items.all()

local validWorkspaceFocusStyles = {
	background = true,
	border = true,
	underline = true,
	left_bar = true,
	text = true,
}
local validWorkspaceDisplayModes = {
	icon = true,
	icon_label = true,
	label = true,
}

local function findExecutable(configured)
	local paths = { "/opt/homebrew/bin/sketchybar", "/usr/local/bin/sketchybar" }
	if configured then
		table.insert(paths, 1, configured)
	end

	for _, path in ipairs(paths) do
		if path and hs.fs.attributes(path, "mode") == "file" then
			return path
		end
	end
	return nil
end

local function copyTable(value)
	if type(value) ~= "table" then
		return value
	end
	local result = {}
	for key, child in pairs(value) do
		result[key] = copyTable(child)
	end
	return result
end

local function shellQuote(value)
	return "'" .. tostring(value):gsub("'", "'\\''") .. "'"
end

function M.run(args)
	if not M.executable then
		return false
	end
	local command = shellQuote(M.executable)
	for _, argument in ipairs(args) do
		command = command .. " " .. shellQuote(argument)
	end

	local _, success = hs.execute(command)
	if not success then
		M.logger.w("SketchyBar command failed")
	end
	return success
end

function M.itemDefinition(itemID)
	return items.find(itemID)
end

local function availableRightItems()
	return items.defaultRightOrder()
end

local function rightItemOrder(configuredOrder)
	local order = {}
	local seen = {}

	for _, itemID in ipairs(configuredOrder or {}) do
		if itemID ~= "front_app" and M.itemDefinition(itemID) and not seen[itemID] then
			table.insert(order, itemID)
			seen[itemID] = true
		elseif itemID ~= "front_app" and not M.itemDefinition(itemID) then
			M.logger.w("Ignoring unknown SketchyBar item: " .. tostring(itemID))
		end
	end

	return order
end

function M.itemEnabled(itemID)
	return itemID == "front_app" or (M.enabledRightItems and M.enabledRightItems[itemID] == true)
end

function M.applyEnabledItems()
	local args = {}
	for _, itemID in ipairs(availableRightItems()) do
		local enabled = M.itemEnabled(itemID)
		table.insert(args, "--set")
		table.insert(args, itemID)
		table.insert(args, "drawing=" .. (enabled and "on" or "off"))
		table.insert(args, "updates=" .. (enabled and "on" or "off"))
		if not enabled then
			table.insert(args, "popup.drawing=off")
		end
	end
	M.run(args)
	M.run({ "--update" })
end

function M.applyRightItemOrder()
	if #M.rightItemOrder == 0 then
		return true
	end
	local args = { "--reorder" }

	-- SketchyBar lays out right-positioned items in reverse internal order.
	-- Configuration and keyboard navigation stay intuitive: left to right.
	for index = #M.rightItemOrder, 1, -1 do
		table.insert(args, M.rightItemOrder[index])
	end

	return M.run(args)
end

function M.updateCaffeine(state)
	local icon = hs.configdir
		.. "/modules/caffeine/assets/coffee."
		.. (state and "fill" or "empty")
		.. ".16.png"
	M.run({
		"--set",
		"caffeine",
		"icon.background.image=" .. icon,
		"icon.background.image.drawing=on",
		"label=" .. (state and "On" or "Off"),
	})
end

function M.updateInputSource(state)
	if type(state) ~= "table" then return end
	M.run({
		"--set",
		"input_source",
		"label=" .. tostring(state.label or state.name or "?"),
	})
end

function M.ensureCaffeineItem()
	if not M.itemEnabled("caffeine") or not M.executable then
		return
	end

	local _, exists = hs.execute(shellQuote(M.executable) .. " --query caffeine >/dev/null 2>&1")
	if not exists then
		M.run({ "--add", "item", "caffeine", "right" })
	end
	M.run({
		"--set",
		"caffeine",
		"position=right",
		"icon= ",
		"icon.drawing=on",
		"icon.width=21",
		"icon.align=center",
		"icon.background.drawing=on",
		"icon.background.image.scale=1.0",
		"label.drawing=on",
		"click_script=" .. M.pluginDir .. "/action_click.sh caffeine",
	})
	M.updateCaffeine(hs.caffeinate.get("displayIdle"))
end

function M.rebuildNavigation()
	local previousID = M.navigableItems[M.selectedIndex] and M.navigableItems[M.selectedIndex].id
	local items = {}
	if not (M.snapshot and M.snapshot.collapsed) then
		table.insert(items, { id = "front_app", type = "static" })
	end

	if not (M.snapshot and M.snapshot.suspended) then
		for _, group in ipairs((M.snapshot and M.snapshot.groups) or {}) do
			for _, workspace in ipairs(group.workspaces or {}) do
				table.insert(items, {
					id = string.format("wm.%s.%d", group.id, workspace.index),
					type = "workspace",
					group = group.id,
					workspaceIndex = workspace.index,
				})
			end
		end
	end

	-- Static controls remain right-positioned. Workspace items are traversed
	-- above in natural group/workspace order and render together in the center.
	for _, itemID in ipairs(M.rightItemOrder) do
		table.insert(items, { id = itemID, type = "static" })
	end

	M.navigableItems = items
	M.selectedIndex = math.min(M.selectedIndex, math.max(1, #items))
	if previousID then
		for index, item in ipairs(items) do
			if item.id == previousID then
				M.selectedIndex = index
				break
			end
		end
	end
end

function M.selectInitialItem()
	local wanted
	if not M.hasOpenedNavigation then
		wanted = M.config.initialSelectedItem or "clock"
	end
	M.hasOpenedNavigation = true

	if wanted then
		for index, item in ipairs(M.navigableItems) do
			if item.id == wanted then
				M.selectedIndex = index
				return
			end
		end
	end

	wanted = M.lastSelectedID
	if not wanted and M.snapshot then
		for _, group in ipairs(M.snapshot.groups or {}) do
			if group.active then
				for _, workspace in ipairs(group.workspaces or {}) do
					if workspace.active then
						wanted = string.format("wm.%s.%d", group.id, workspace.index)
						break
					end
				end
			end
			if wanted then
				break
			end
		end
	end

	if wanted then
		for index, item in ipairs(M.navigableItems) do
			if item.id == wanted then
				M.selectedIndex = index
				return
			end
		end
	end
end

function M.publish(shouldTrigger)
	if not M.snapshot then
		return
	end
	local document = copyTable(M.snapshot)
	document.navigation = {
		active = M.active,
		selected = M.active and M.navigableItems[M.selectedIndex] and M.navigableItems[M.selectedIndex].id or nil,
		focusStyle = M.workspaceFocusStyle,
	}
	document.workspaceDisplayMode = M.workspaceDisplayMode
	document.workspaceActiveLabel = M.workspaceActiveLabel
	document.workspaceGroupSeparator = M.workspaceGroupSeparator
	document.workspaceGroupSeparatorGap = M.workspaceGroupSeparatorGap
	document.workspaceIconWidth = M.workspaceIconWidth
	document.workspaceIconOffset = M.workspaceIconOffset
	document.workspaceFocusInset = M.workspaceFocusInset
	document.workspaceLabelGap = M.workspaceLabelGap
	document.workspaceLabelCharacterWidth = M.workspaceLabelCharacterWidth
	document.workspaceLabelExtraWidth = M.workspaceLabelExtraWidth
	document.rightItemOrder = copyTable(M.rightItemOrder)
	hs.fs.mkdir(hs.configdir .. "/state")
	hs.json.write(document, M.stateFile, true, true)
	if shouldTrigger ~= false then
		M.run({ "--trigger", "wm_workspace_change" })
	end
end

local function appendWorkspaceFocusStyle(args, style)
	if style == "background" then
		table.insert(args, "background.color=0xff3b82f6")
		table.insert(args, "background.drawing=on")
	elseif style == "border" then
		table.insert(args, "background.color=0x00000000")
		table.insert(args, "background.border_color=0xff3b82f6")
		table.insert(args, "background.border_width=2")
		table.insert(args, "background.drawing=on")
	elseif style == "left_bar" then
		table.insert(args, "icon=▎")
		table.insert(args, "icon.drawing=on")
		table.insert(args, "icon.color=0xff3b82f6")
	elseif style == "text" then
		table.insert(args, "label.color=0xff60a5fa")
	else
		local prefix = M.workspaceDisplayMode == "label" and "label.background" or "icon.background"
		table.insert(args, prefix .. ".color=0xff3b82f6")
		table.insert(args, prefix .. ".height=3")
		table.insert(args, prefix .. ".corner_radius=0")
		table.insert(args, prefix .. ".y_offset=-12")
		table.insert(args, prefix .. ".drawing=on")
	end
end

function M.applySelection()
	if not M.snapshot then
		return
	end

	local args = {}
	local selected = M.active and M.navigableItems[M.selectedIndex]
	local selectedID = selected and selected.id
	for _, group in ipairs(M.snapshot.groups or {}) do
		for _, workspace in ipairs(group.workspaces or {}) do
			local item = string.format("wm.%s.%d", group.id, workspace.index)
			local focused = selectedID == item or (not M.active and group.active and workspace.active)
			local labelItem = string.format("wm.label.%s.%d", group.id, workspace.index)
			local labelFocused = focused and group.active and workspace.active
			table.insert(args, "--set")
			table.insert(args, item)
			table.insert(args, "label.color=" .. (M.snapshot.suspended and "0x66ffffff" or "0xffffffff"))
			table.insert(args, "background.color=0x00000000")
			table.insert(args, "background.border_width=0")
			table.insert(args, "background.height=28")
			table.insert(args, "background.corner_radius=7")
			table.insert(args, "background.y_offset=0")
			table.insert(args, "background.drawing=on")
			table.insert(args, "icon.background.drawing=off")
			table.insert(args, "label.background.drawing=off")
			if focused then
				appendWorkspaceFocusStyle(args, M.workspaceFocusStyle)
			end
			table.insert(args, "--set")
			table.insert(args, labelItem)
			table.insert(args, "background.drawing=off")
			table.insert(args, "label.background.color=0xff3b82f6")
			table.insert(args, "label.background.height=3")
			table.insert(args, "label.background.corner_radius=0")
			table.insert(args, "label.background.y_offset=-12")
			table.insert(args, "label.background.drawing=" .. (labelFocused and "on" or "off"))
		end
	end

	for _, item in ipairs(staticItems) do
		if M.itemEnabled(item.id) then
			table.insert(args, "--set")
			table.insert(args, item.id)
			table.insert(args, "background.border_width=0")
			table.insert(args, "background.drawing=off")
		end
	end

	if selected then
		if selected.type == "static" then
			table.insert(args, "--set")
			table.insert(args, selected.id)
			table.insert(args, "background.drawing=on")
			table.insert(args, "background.color=0xff3b82f6")
			table.insert(args, "background.border_color=0xff93c5fd")
			table.insert(args, "background.border_width=2")
			table.insert(args, "background.corner_radius=7")
			table.insert(args, "background.height=28")
		end
	end

	if #args > 0 then
		M.run(args)
	end
end

function M.applyBarMode()
	if not M.snapshot then
		return
	end
	local laptop = M.snapshot.collapsed == true
	local args = {
		"--bar",
		"topmost=" .. (laptop and "off" or "window"),
		"height=" .. tostring(M.config.barHeight or 32),
		"hidden=" .. ((laptop or M.active or M.codexUsageDetailsVisible) and "off" or "on"),
		"notch_display_height=" .. (laptop and tostring(M.config.notchDisplayHeight or M.config.barHeight or 32) or "0"),
		"notch_width=" .. tostring(M.config.notchWidth or 200),
	}
	table.insert(args, "--set")
	table.insert(args, "front_app")
	table.insert(args, "position=left")
	table.insert(args, "drawing=" .. (laptop and "off" or "on"))
	for _, itemID in ipairs(M.rightItemOrder) do
		table.insert(args, "--set")
		table.insert(args, itemID)
		table.insert(args, "position=right")
		table.insert(args, "drawing=on")
	end
	M.run(args)
	M.applyRightItemOrder()
end

function M.closeMenu()
	if M.menuParent then
		M.run({ "--set", M.menuParent, "popup.drawing=off", "--remove", "/^wm.menu\\./" })
	end
	M.menuItems = {}
	M.menuIndex = nil
	M.menuParent = nil
end

local function clearCodexUsagePopup()
	M.run({ "--set", "codex", "popup.drawing=off", "--remove", "/^wm.codex.usage\\./" })
end

function M.closeCodexUsageDetails()
	if not M.codexUsageDetailsVisible then
		return
	end
	clearCodexUsagePopup()
	M.codexUsageDetailsVisible = false
end

local function timeUntilReset(timestamp)
	if type(timestamp) ~= "number" then
		return "—"
	end
	local minutes = math.max(0, math.ceil((timestamp - os.time()) / 60))
	local hours = math.floor(minutes / 60)
	minutes = minutes % 60
	return string.format("%02d:%02d", hours, minutes)
end

local function resetTime(window, format)
	if type(window) ~= "table" or type(window.resetsAt) ~= "number" then
		return "—"
	end
	if format == "remaining" then
		return timeUntilReset(window.resetsAt)
	end

	local reset = os.date(format == "date" and "%b %d" or "%H:%M", window.resetsAt)
	reset = reset:gsub(" 0(%d)$", " %1")
	return reset
end

local function daysUntilReset(window)
	if type(window) ~= "table" or type(window.resetsAt) ~= "number" then
		return "—"
	end
	local today = os.date("*t")
	local reset = os.date("*t", window.resetsAt)
	-- Comparing local noons keeps this a calendar-day count across DST changes.
	local todayNoon = os.time({ year = today.year, month = today.month, day = today.day, hour = 12 })
	local resetNoon = os.time({ year = reset.year, month = reset.month, day = reset.day, hour = 12 })
	local days = math.max(0, math.min(7, math.floor((resetNoon - todayNoon) / 86400 + 0.5)))
	if days == 0 then
		return "today"
	end
	if days == 1 then
		return "1 day"
	end
	return string.format("%d days", days)
end

local function codexUsageRows(details)
	if type(details) ~= "table" then
		return { { heading = "Codex", value = "Usage unavailable" } }
	end

	local resets = tonumber(details.manualResets)
	local fiveReset = resetTime(details.fiveHour, M.codexFiveHourTimeFormat or "remaining")
	local weeklyRemaining = M.codexWeeklyTimeFormat == "remaining"
	local weeklyReset = weeklyRemaining and daysUntilReset(details.weekly) or resetTime(details.weekly, "date")
	-- Keep this field exactly three characters wide so toggling between the
	-- relative and absolute reset times does not move the values horizontally.
	local fivePrefix = M.codexFiveHourTimeFormat == "remaining" and "in " or "at "
	local weeklyPrefix = weeklyRemaining and "in " or "on "
	return {
		{ heading = "5h", value = string.format("%s   %6s", fivePrefix, fiveReset) },
		{ heading = "Weekly", value = string.format("%s   %6s", weeklyPrefix, weeklyReset) },
		{ heading = "Resets", value = resets and string.format("%d available", resets) or "Unavailable" },
	}
end

function M.renderCodexUsageDetails()
	if not M.codexUsageDetailsVisible then
		return
	end
	local rows = codexUsageRows(M.codexUsageDetails)
	local args = { "--set", "/^wm.codex.usage\\./", "background.drawing=off" }
	for index, row in ipairs(rows) do
		local name = "wm.codex.usage." .. tostring(index)
		table.insert(args, "--set")
		table.insert(args, name)
		table.insert(args, "icon=" .. row.heading)
		table.insert(args, "label=" .. row.value)
	end
	M.run(args)
end

function M.openCodexUsageDetails()
	keyLights.closeDetails()
	plex.closeDetails()
	M.closeMenu()
	clearCodexUsagePopup()
	local details = hs.json.read(M.codexUsageStateFile)
	M.codexUsageDetails = details
	local rows = codexUsageRows(details)

	local args = {}
	for index, row in ipairs(rows) do
		local name = "wm.codex.usage." .. tostring(index)
		table.insert(args, "--add")
		table.insert(args, "item")
		table.insert(args, name)
		table.insert(args, "popup.codex")
		table.insert(args, "--set")
		table.insert(args, name)
		table.insert(args, "icon=" .. row.heading)
		table.insert(args, "icon.font=Hack Nerd Font:Bold:13.0")
		table.insert(args, "icon.width=58")
		table.insert(args, "icon.align=left")
		table.insert(args, "icon.padding_left=10")
		table.insert(args, "icon.padding_right=4")
		table.insert(args, "label=" .. row.value)
		table.insert(args, "label.font=Hack Nerd Font:Regular:13.0")
		table.insert(args, "label.width=150")
		table.insert(args, "label.align=right")
		table.insert(args, "label.padding_left=4")
		table.insert(args, "label.padding_right=10")
		table.insert(args, "background.color=0xff3b82f6")
		table.insert(args, "background.corner_radius=6")
		table.insert(args, "background.height=26")
		table.insert(args, "background.drawing=off")
	end
	M.run(args)
	-- SketchyBar must finish registering popup children before the parent is
	-- shown, otherwise it can render an empty popup background intermittently.
	M.run({ "--set", "codex", "popup.drawing=on" })
	M.codexUsageDetailsVisible = true
end

function M.invokeCodexUsageSelected(selected)
	if not selected or selected.id ~= "codex" or not M.codexUsageDetailsVisible then
		return false
	end
	local showingRemaining = M.codexFiveHourTimeFormat == "remaining"
		and M.codexWeeklyTimeFormat == "remaining"
	M.codexFiveHourTimeFormat = showingRemaining and "time" or "remaining"
	M.codexWeeklyTimeFormat = showingRemaining and "date" or "remaining"
	M.renderCodexUsageDetails()
	return true
end

function M.syncCodexUsageDetails()
	local selected = M.active and M.navigableItems[M.selectedIndex]
	local shouldShow = selected and selected.id == "codex" and not M.menuIndex
	if shouldShow and not M.codexUsageDetailsVisible then
		M.openCodexUsageDetails()
	elseif not shouldShow and M.codexUsageDetailsVisible then
		M.closeCodexUsageDetails()
	end
end

function M.openMenu(itemID)
	local definition = M.itemDefinition(itemID)
	if not definition or #(definition.actions or {}) == 0 then
		return false
	end
	if M.menuParent == itemID then
		M.closeMenu()
		return true
	end
	M.closeCodexUsageDetails()
	keyLights.closeDetails()
	plex.closeDetails()
	M.closeMenu()
	M.menuParent = itemID
	M.menuItems = definition.actions
	M.menuIndex = 1

	local args = {}
	for index, action in ipairs(M.menuItems) do
		local name = "wm.menu." .. tostring(index)
		table.insert(args, "--add")
		table.insert(args, "item")
		table.insert(args, name)
		table.insert(args, "popup." .. itemID)
		table.insert(args, "--set")
		table.insert(args, name)
		table.insert(args, "icon.drawing=off")
		table.insert(args, "label=" .. action.label)
		table.insert(args, "background.color=0xff3b82f6")
		table.insert(args, "background.corner_radius=6")
		table.insert(args, "background.height=26")
		table.insert(args, "background.drawing=" .. (index == 1 and "on" or "off"))
		table.insert(args, "click_script=" .. M.pluginDir .. "/action_click.sh " .. itemID .. " " .. action.id)
	end
	table.insert(args, "--set")
	table.insert(args, itemID)
	table.insert(args, "popup.drawing=on")
	M.run(args)
	-- Apply selection in a second transaction. SketchyBar can briefly inherit
	-- the popup background while rows are being added in the first transaction.
	M.updateMenuSelection()
	return true
end

function M.updateMenuSelection()
	if not M.menuIndex then
		return
	end
	local args = {
		"--set",
		"/^wm.menu\\./",
		"background.drawing=off",
		"--set",
		"wm.menu." .. M.menuIndex,
		"background.drawing=on",
	}
	M.run(args)
end

function M.moveSelection(delta)
	if M.menuIndex then
		M.menuIndex = ((M.menuIndex - 1 + delta) % #M.menuItems) + 1
		M.updateMenuSelection()
		return
	end

	if #M.navigableItems == 0 then
		return
	end
	M.selectedIndex = ((M.selectedIndex - 1 + delta) % #M.navigableItems) + 1
	M.publish(false)
	M.applySelection()
	M.syncCodexUsageDetails()
	keyLights.syncDetails(M.active, M.navigableItems[M.selectedIndex], M.menuIndex)
	plex.syncDetails(M.active, M.navigableItems[M.selectedIndex], M.menuIndex)
end

function M.runAction(itemID, actionID)
	local definition = M.itemDefinition(itemID)
	if not definition then
		return false
	end

	for _, action in ipairs(definition.actions or {}) do
		if action.id == actionID then
			action.handler()
			return true
		end
	end
	return false
end

function M.invokeAction(itemID, actionID)
	local definition = M.itemDefinition(itemID)
	if not definition then
		return false
	end
	M.closeMenu()
	return M.runAction(itemID, actionID)
end

function M.handleVerticalNavigation(delta)
	M.volumeRepeatDirection = nil
	if M.menuIndex then
		M.moveSelection(delta)
		return
	end

	local item = M.navigableItems[M.selectedIndex]
	if keyLights.handleVertical(item, delta) then
		return
	end
	if plex.handleVertical(item, delta) then
		return
	end
	if item and items.handleVertical(item.id, delta) then
		return
	end
	if item and item.id == "volume" then
		M.volumeRepeatDirection = delta
		M.runAction("volume", delta < 0 and "up" or "down")
		return
	end

	M.moveSelection(delta)
end

function M.handleHorizontalNavigation(delta)
	local item = M.navigableItems[M.selectedIndex]
	if keyLights.handleHorizontal(item, delta) then
		return
	end
	keyLights.stopRepeat()
	M.moveSelection(delta)
end

function M.repeatVolume(delta)
	if M.volumeRepeatDirection == delta then
		M.runAction("volume", delta < 0 and "up" or "down")
	end
end

function M.stopVolumeRepeat()
	M.volumeRepeatDirection = nil
end

function M.handleSpace()
	local item = M.navigableItems[M.selectedIndex]
	if M.invokeCodexUsageSelected(item) then
		return
	end
	if keyLights.invokeSelected(item) then
		return
	end
	local plexHandled, closeAfterPlexAction = plex.invokeSelected(item)
	if plexHandled then
		if closeAfterPlexAction then
			M.modal:exit()
		end
		return
	end
	if item and items.handleSpace(item.id) then
		return
	end
	if item and item.id == "volume" then
		if M.menuIndex then
			M.closeMenu()
		end
		M.runAction("volume", "mute")
		return
	end
	if item and item.id == "caffeine" then
		M.runAction("caffeine", "toggle")
		return
	end
	if item and item.type == "static" then
		M.openMenu(item.id)
	end
end

function M.invokeSelected()
	if M.menuIndex then
		local action = M.menuItems[M.menuIndex]
		if action then
			M.invokeAction(M.menuParent, action.id)
		end
		M.modal:exit()
		return
	end

	local item = M.navigableItems[M.selectedIndex]
	if not item then
		return
	end
	if keyLights.invokeSelected(item) then
		return
	end
	local plexHandled, closeAfterPlexAction = plex.invokeSelected(item)
	if plexHandled then
		if closeAfterPlexAction then
			M.modal:exit()
		end
		return
	end

	if item.type == "workspace" then
		if stacking.activateWorkspaceExplicitly(item.group, item.workspaceIndex) then
			stacking.flashWorkspaceIndicator(item.group, item.workspaceIndex, "workspaceChange")
		end
	else
		local definition = M.itemDefinition(item.id)
		local action = definition and definition.actions and definition.actions[1]
		if action then
			action.handler()
		end
	end
	M.modal:exit()
end

function M.toggleNavigation()
	if M.active then
		M.modal:exit()
	else
		M.modal:enter()
	end
end

function M.handleURL(_, params)
	local command = params.command
	if command == "refresh" then
		M.applyEnabledItems()
		items.refreshEnabled(M.rightItemOrder, M.config, M)
		M.ensureCaffeineItem()
		M.applyRightItemOrder()
		M.publish()
		M.applyBarMode()
		return
	end
	if command == "navigation" then
		M.toggleNavigation()
		return
	end

	if command == "workspace" or command == "action" or command == "click" then
		-- These URL commands originate in SketchyBar mouse handlers. Suppress the
		-- WM's mouse-follows-focus behavior, including delayed window creation.
		stacking.noteMouseInteraction()
	end

	if command == "workspace" and tostring(params.group or ""):match("^[%w_-]+$") then
		local index = tonumber(params.index)
		if index and not stacking.isSuspended() then
			-- A mouse click may move focus, but must never move the pointer. Keyboard
			-- workspace activation keeps the configured mouse-follows-focus behavior.
			if stacking.activateWorkspaceExplicitly(params.group, index, true, false) then
				stacking.flashWorkspaceIndicator(params.group, index, "workspaceChange")
			end
		end
		if M.active then
			M.modal:exit()
		end
		return
	end

	if command == "action" and tostring(params.item or ""):match("^[%w_.-]+$") then
		M.invokeAction(params.item, params.action)
		if M.active then
			M.modal:exit()
		end
		return
	end

	if command == "click" and tostring(params.item or ""):match("^[%w_.-]+$") then
		if not M.itemEnabled(params.item) then
			return
		end
		local definition = M.itemDefinition(params.item)
		if not definition then
			return
		end
		if params.item ~= "codex" then
			M.closeCodexUsageDetails()
		end
		if params.item ~= "key_lights" then
			keyLights.closeDetails()
		end
		if params.item ~= "plex" then
			plex.closeDetails()
		end
		if params.button == "right" then
			M.openMenu(params.item)
		else
			local actionIndex = (params.button == "middle" or params.button == "other") and 2 or 1
			local action = definition.actions and definition.actions[actionIndex]
			if action then
				action.handler()
			end
			if M.active and params.item ~= "codex" then
				M.modal:exit()
			end
		end
	end
end

function M.setup(config)
	M.config = config or {}
	M.logger = hs.logger.new("sketchybar", "info")
	local configuredOrder = M.config.rightItemOrder
	if configuredOrder == nil then
		configuredOrder = availableRightItems()
	end
	M.rightItemOrder = rightItemOrder(configuredOrder)
	M.enabledRightItems = {}
	for _, itemID in ipairs(M.rightItemOrder) do
		M.enabledRightItems[itemID] = true
	end
	M.workspaceFocusStyle = M.config.workspaceFocusStyle or "underline"
	if not validWorkspaceFocusStyles[M.workspaceFocusStyle] then
		M.workspaceFocusStyle = "underline"
	end
	M.workspaceDisplayMode = M.config.workspaceDisplayMode or "icon"
	if M.workspaceDisplayMode == "icon+label" then
		M.workspaceDisplayMode = "icon_label"
	end
	if not validWorkspaceDisplayModes[M.workspaceDisplayMode] then
		M.workspaceDisplayMode = "icon"
	end
	M.workspaceActiveLabel = M.config.workspaceActiveLabel ~= false
	M.workspaceGroupSeparator = tostring(M.config.workspaceGroupSeparator or ">")
	M.workspaceGroupSeparatorGap = tonumber(M.config.workspaceGroupSeparatorGap) or 4
	M.workspaceIconWidth = tonumber(M.config.workspaceIconWidth) or 23
	M.workspaceIconOffset = tonumber(M.config.workspaceIconOffset) or 0
	M.workspaceFocusInset = tonumber(M.config.workspaceFocusInset) or 0
	M.workspaceLabelGap = tonumber(M.config.workspaceLabelGap) or 0
	M.workspaceLabelCharacterWidth = tonumber(M.config.workspaceLabelCharacterWidth) or 9
	M.workspaceLabelExtraWidth = tonumber(M.config.workspaceLabelExtraWidth) or 0
	M.executable = findExecutable(M.config.executable)
	M.stateFile = hs.configdir .. "/state/sketchybar.json"
	M.pluginDir = hs.configdir:gsub("%.hammerspoon$", ".config/sketchybar/plugins")
	M.codexUsageStateFile = os.getenv("HOME") .. "/Library/Caches/SketchyBar/codex_usage.json"
	clearCodexUsagePopup()
	items.setupEnabled(M.rightItemOrder, M.config, M)

	M.modal = hs.hotkey.modal.new()
	M.modal.entered = function()
		M.active = true
		M.rebuildNavigation()
		M.selectInitialItem()
		if not (M.snapshot and M.snapshot.collapsed) then
			M.applyBarMode()
		end
		M.publish(false)
		M.applySelection()
		M.syncCodexUsageDetails()
		keyLights.syncDetails(M.active, M.navigableItems[M.selectedIndex], M.menuIndex)
		plex.syncDetails(M.active, M.navigableItems[M.selectedIndex], M.menuIndex)
	end
	M.modal.exited = function()
		M.lastSelectedID = M.navigableItems[M.selectedIndex] and M.navigableItems[M.selectedIndex].id
		M.active = false
		M.closeMenu()
		M.closeCodexUsageDetails()
		keyLights.closeDetails()
		plex.closeDetails()
		M.publish(false)
		M.applySelection()
		if not (M.snapshot and M.snapshot.collapsed) then
			M.applyBarMode()
		end
	end

	M.modal:bind({}, "left", function()
		M.moveSelection(-1)
	end)
	M.modal:bind({}, "right", function()
		M.moveSelection(1)
	end)
	M.modal:bind({}, "up", function()
		M.moveSelection(-1)
	end)
	M.modal:bind({}, "down", function()
		M.moveSelection(1)
	end)
	keyboard.register("sketchybar-navigation", {
		priority = 100,
		keys = { "h", "j", "k", "l" },
		active = function()
			return M.active
		end,
		pressed = function(key)
			if key == "h" or key == "l" then
				M.handleHorizontalNavigation(key == "h" and -1 or 1)
			else
				M.handleVerticalNavigation(key == "k" and -1 or 1)
			end
			return true
		end,
		repeated = function(key)
			if key == "h" or key == "l" then
				keyLights.repeatAdjustment(key == "h" and -1 or 1)
			else
				M.repeatVolume(key == "k" and -1 or 1)
			end
			return true
		end,
		released = function(key)
			if key == "h" or key == "l" then
				keyLights.stopRepeat()
			else
				M.stopVolumeRepeat()
			end
			return true
		end,
	})
	M.modal:bind({}, "return", M.invokeSelected)
	M.modal:bind({}, "space", M.handleSpace)
	M.modal:bind({}, "escape", function()
		if M.menuIndex then
			M.closeMenu()
		else
			M.modal:exit()
		end
	end)
	hotkeys.addBeforeHandler(function()
		if M.active then
			M.modal:exit()
		else
			if M.menuIndex then
				M.closeMenu()
			end
			M.closeCodexUsageDetails()
			keyLights.closeDetails()
			plex.closeDetails()
		end
	end)
	for action, hotkey in pairs(M.config.mapping or {}) do
		if type(M[action]) == "function" then
			hotkeys.bind(hotkey[1], hotkey[2], M[action], {
				persistent = true,
				dismissOverlays = false,
			})
		end
	end

	hs.urlevent.bind("wm-bar", M.handleURL)
	M.applyEnabledItems()
	M.ensureCaffeineItem()
	M.applyRightItemOrder()
	stacking.subscribe(function(snapshot)
		local fingerprint = hs.json.encode(snapshot)
		local modeFingerprint = tostring(snapshot.collapsed) .. ":" .. tostring(snapshot.suspended)
		local changed = fingerprint ~= M.snapshotFingerprint
		local modeChanged = modeFingerprint ~= M.modeFingerprint
		M.snapshot = snapshot
		M.rebuildNavigation()
		if changed then
			M.publish()
		end
		if modeChanged then
			M.applyBarMode()
		end
		M.snapshotFingerprint = fingerprint
		M.modeFingerprint = modeFingerprint
	end)
end

return M
