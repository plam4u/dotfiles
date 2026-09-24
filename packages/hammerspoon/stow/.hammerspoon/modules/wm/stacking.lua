local store = require("modules.wm.stack_store")
local ui = require("modules.wm.stack_ui")

local M = {
	regionOrder = { "left", "center", "right" },
	regions = {},
	windowIndex = {},
	enabled = false,
}

local function copyFrame(frame)
	return { x = frame.x, y = frame.y, w = frame.w, h = frame.h }
end

local function round(number)
	return math.floor(number + 0.5)
end

local function clamp(number, minimum, maximum)
	return math.max(minimum, math.min(maximum, number))
end

local function getBundleID(window)
	local app = window and window:application()

	return app and app:bundleID() or nil
end

local function liveMemberCount(group)
	local count = 0

	for _, member in ipairs(group.members) do
		if member.window then
			count = count + 1
		end
	end

	return count
end

local function defaultState()
	return {
		version = 1,
		regions = {
			left = { activeGroup = 1, groups = {} },
			center = { activeGroup = 1, groups = {} },
			right = { activeGroup = 1, groups = {} },
		},
	}
end

-- Setup ----------------------------------------------------------------------

function M.setup(config)
	M.config = config or {}
	M.options = M.config.config or {}
	M.logger = hs.logger.new("stacking", M.options.logLevel or "info")
	M.stateFile = hs.configdir .. "/state/stacks.json"
	M.savedStateExists = store.exists(M.stateFile)
	M.loadedFromDisk = false

	local screen = hs.screen.primaryScreen()
	local screenFrame = screen and screen:fullFrame()
	local expectedWidth = M.options.screenWidth or 5120
	local expectedHeight = M.options.screenHeight or 1440

	if not screenFrame or screenFrame.w ~= expectedWidth or screenFrame.h ~= expectedHeight then
		M.logger.e(
			string.format("Expected a %dx%d primary screen; stacking was not started", expectedWidth, expectedHeight)
		)
		return
	end

	M.regions = {
		left = { frame = { x = screenFrame.x, y = screenFrame.y, w = 1280, h = 1440 } },
		center = { frame = { x = screenFrame.x + 1280, y = screenFrame.y, w = 2560, h = 1440 } },
		right = { frame = { x = screenFrame.x + 3840, y = screenFrame.y, w = 1280, h = 1440 } },
	}

	M.applyState(defaultState())
	M.enabled = true
	M.startWindowWatcher()
	M.bindHotkeys(M.config.mapping or {})
	M.render()

	if M.savedStateExists then
		-- Let Hammerspoon finish loading the configuration before restoring
		-- and moving the managed windows.
		hs.timer.doAfter(M.options.restoreDelay or 0.1, function()
			M.loadStacks(false)
		end)
	end
end

function M.bindHotkeys(mapping)
	for action, hotkey in pairs(mapping) do
		local handler = M[action]

		if type(handler) ~= "function" then
			M.logger.e("Unknown stacking action: " .. tostring(action))
		else
			hs.hotkey.bind(hotkey[1], hotkey[2], handler)
		end
	end
end

-- Persisted model ------------------------------------------------------------

function M.applyState(state)
	state.regions = type(state.regions) == "table" and state.regions or {}

	for _, regionName in ipairs(M.regionOrder) do
		local savedRegion = state.regions[regionName]

		if type(savedRegion) ~= "table" then
			savedRegion = { activeGroup = 1, groups = {} }
		end

		savedRegion.groups = type(savedRegion.groups) == "table" and savedRegion.groups or {}
		M.regions[regionName].groups = {}
		M.regions[regionName].activeGroup = tonumber(savedRegion.activeGroup) or 1

		for _, savedGroup in ipairs(savedRegion.groups) do
			local group = {
				members = {},
				leftWidth = tonumber(savedGroup.leftWidth),
				focusedMember = tonumber(savedGroup.focusedMember) or 1,
			}

			for _, savedMember in ipairs(savedGroup.members or {}) do
				if #group.members < 2 and type(savedMember.bundleID) == "string" then
					table.insert(group.members, {
						bundleID = savedMember.bundleID,
						minWidth = tonumber(savedMember.minWidth),
						window = nil,
					})
				end
			end

			if #group.members > 0 then
				table.insert(M.regions[regionName].groups, group)
			end
		end
	end
end

function M.serializableState()
	local state = defaultState()

	for _, regionName in ipairs(M.regionOrder) do
		local region = M.regions[regionName]
		local savedRegion = state.regions[regionName]
		savedRegion.activeGroup = region.activeGroup

		for _, group in ipairs(region.groups) do
			local savedGroup = { members = {}, focusedMember = group.focusedMember }

			if #group.members == 2 then
				savedGroup.leftWidth = group.leftWidth
			end

			for _, member in ipairs(group.members) do
				table.insert(savedGroup.members, {
					bundleID = member.bundleID,
					minWidth = member.minWidth,
				})
			end

			table.insert(savedRegion.groups, savedGroup)
		end
	end

	return state
end

function M.saveState()
	if not store.save(M.stateFile, M.serializableState()) then
		M.logger.e("Unable to save stack state to " .. M.stateFile)
		return false
	end

	return true
end

function M.hasGroups()
	for _, regionName in ipairs(M.regionOrder) do
		if #M.regions[regionName].groups > 0 then
			return true
		end
	end

	return false
end

function M.saveStacks()
	if M.savedStateExists and not M.loadedFromDisk and not M.hasGroups() then
		hs.alert.show("No window stacks to save; load the saved stacks first")
		return
	end

	if M.saveState() then
		M.savedStateExists = true
		M.loadedFromDisk = true
		hs.alert.show("Window stacks saved")
	else
		hs.alert.show("Unable to save window stacks")
	end
end

function M.loadStacks(showAlert)
	local state = store.load(M.stateFile)

	if type(state) ~= "table" then
		if showAlert ~= false then
			hs.alert.show("No saved window stacks found")
		end
		return
	end

	M.applyState(state)
	M.loadedFromDisk = true
	M.restoreWindows()
	M.render()

	if showAlert ~= false then
		hs.alert.show("Window stacks loaded")
	end
end

function M.rebuildWindowIndex()
	M.windowIndex = {}

	for _, regionName in ipairs(M.regionOrder) do
		local region = M.regions[regionName]

		for groupIndex, group in ipairs(region.groups) do
			for memberIndex, member in ipairs(group.members) do
				if member.window and member.window:id() then
					M.windowIndex[member.window:id()] = {
						regionName = regionName,
						groupIndex = groupIndex,
						memberIndex = memberIndex,
					}
				end
			end
		end
	end
end

function M.isManaged(window)
	return M.enabled and window and window:id() and M.windowIndex[window:id()] ~= nil
end

function M.getWindowLocation(window)
	if not M.isManaged(window) then
		return nil
	end

	return M.windowIndex[window:id()]
end

function M.render()
	if M.enabled then
		ui.render(M.regions, M.regionOrder, M.options.ui or {})
	end
end

function M.findGroup(regionName, wantedGroup)
	for index, group in ipairs(M.regions[regionName].groups) do
		if group == wantedGroup then
			return index
		end
	end

	return nil
end

function M.knownRegionForBundle(bundleID)
	for _, regionName in ipairs(M.regionOrder) do
		for _, group in ipairs(M.regions[regionName].groups) do
			for _, member in ipairs(group.members) do
				if member.bundleID == bundleID then
					return regionName
				end
			end
		end
	end

	return nil
end

function M.firstPendingMember(bundleID)
	for _, regionName in ipairs(M.regionOrder) do
		for groupIndex, group in ipairs(M.regions[regionName].groups) do
			for memberIndex, member in ipairs(group.members) do
				if member.bundleID == bundleID and not member.window then
					return regionName, groupIndex, memberIndex
				end
			end
		end
	end

	return nil
end

-- Layout ---------------------------------------------------------------------

function M.layoutGroup(regionName, group, shouldVerify)
	local region = M.regions[regionName]
	local liveMembers = {}

	for memberIndex, member in ipairs(group.members) do
		if member.window then
			table.insert(liveMembers, { member = member, index = memberIndex })
		end
	end

	if #liveMembers == 0 then
		return
	end

	if #liveMembers == 1 then
		liveMembers[1].member.window:setFrame(copyFrame(region.frame), 0)
		return
	end

	local defaultMinWidth = M.options.defaultMinWidth or 200
	local leftMin = group.members[1].minWidth or defaultMinWidth
	local rightMin = group.members[2].minWidth or defaultMinWidth

	if leftMin + rightMin > region.frame.w then
		M.splitImpossibleGroup(regionName, group)
		return
	end

	local requestedLeftWidth = round(group.leftWidth or region.frame.w / 2)
	requestedLeftWidth = clamp(requestedLeftWidth, leftMin, region.frame.w - rightMin)
	group.leftWidth = requestedLeftWidth

	local leftFrame = copyFrame(region.frame)
	leftFrame.w = requestedLeftWidth
	local rightFrame = copyFrame(region.frame)
	rightFrame.x = region.frame.x + requestedLeftWidth
	rightFrame.w = region.frame.w - requestedLeftWidth

	group.members[1].window:setFrame(leftFrame, 0)
	group.members[2].window:setFrame(rightFrame, 0)

	if shouldVerify ~= false then
		if shouldVerify ~= "continue" then
			group.verifyPass = 0
		end

		group.resizeVersion = (group.resizeVersion or 0) + 1
		local version = group.resizeVersion

		hs.timer.doAfter(M.options.verifyDelay or 0.08, function()
			M.verifyGroupLayout(regionName, group, requestedLeftWidth, version)
		end)
	end
end

function M.verifyGroupLayout(regionName, group, requestedLeftWidth, version)
	if group.resizeVersion ~= version or not M.findGroup(regionName, group) then
		return
	end

	local left = group.members[1]
	local right = group.members[2]

	if not left or not right or not left.window or not right.window then
		return
	end

	local region = M.regions[regionName]
	local tolerance = M.options.frameTolerance or 2
	local leftFrame = left.window:frame()
	local rightFrame = right.window:frame()
	local requestedRightWidth = region.frame.w - requestedLeftWidth
	local learnedMinimum = false

	if leftFrame.w > requestedLeftWidth + tolerance then
		left.minWidth = math.max(left.minWidth or 0, round(leftFrame.w))
		learnedMinimum = true
	end

	if rightFrame.w > requestedRightWidth + tolerance then
		right.minWidth = math.max(right.minWidth or 0, round(rightFrame.w))
		learnedMinimum = true
	end

	local defaultMinWidth = M.options.defaultMinWidth or 200
	local leftMin = left.minWidth or defaultMinWidth
	local rightMin = right.minWidth or defaultMinWidth

	if leftMin + rightMin > region.frame.w then
		M.splitImpossibleGroup(regionName, group)
		return
	end

	local correctedWidth = clamp(requestedLeftWidth, leftMin, region.frame.w - rightMin)

	if learnedMinimum or correctedWidth ~= group.leftWidth then
		group.leftWidth = correctedWidth
		group.verifyPass = (group.verifyPass or 0) + 1
		M.layoutGroup(regionName, group, group.verifyPass < 2 and "continue" or false)
	end

	M.render()
end

function M.layoutAllGroups()
	for _, regionName in ipairs(M.regionOrder) do
		for _, group in ipairs(M.regions[regionName].groups) do
			M.layoutGroup(regionName, group)
		end
	end
end

function M.raiseGroup(group, shouldFocus)
	local focusIndex = clamp(group.focusedMember or 1, 1, #group.members)

	for _, member in ipairs(group.members) do
		if member.window then
			member.window:raise()
		end
	end

	if shouldFocus then
		local focusedMember = group.members[focusIndex]

		if not focusedMember or not focusedMember.window then
			for index, member in ipairs(group.members) do
				if member.window then
					focusedMember = member
					group.focusedMember = index
					break
				end
			end
		end

		if focusedMember and focusedMember.window then
			focusedMember.window:focus()
		end
	end
end

function M.activateGroup(regionName, groupIndex, shouldFocus)
	local region = M.regions[regionName]
	local group = region.groups[groupIndex]

	if not group or liveMemberCount(group) == 0 then
		return false
	end

	region.activeGroup = groupIndex
	M.layoutGroup(regionName, group)
	M.raiseGroup(group, shouldFocus ~= false)
	M.render()

	return true
end

function M.raiseActiveGroups()
	for _, regionName in ipairs(M.regionOrder) do
		local region = M.regions[regionName]
		local active = region.groups[region.activeGroup]

		if not active or liveMemberCount(active) == 0 then
			for groupIndex, group in ipairs(region.groups) do
				if liveMemberCount(group) > 0 then
					region.activeGroup = groupIndex
					active = group
					break
				end
			end
		end

		if active and liveMemberCount(active) > 0 then
			M.raiseGroup(active, false)
		end
	end
end

function M.splitImpossibleGroup(regionName, group)
	local region = M.regions[regionName]
	local groupIndex = M.findGroup(regionName, group)

	if not groupIndex or #group.members ~= 2 then
		return
	end

	local first = { members = { group.members[1] }, focusedMember = 1 }
	local second = { members = { group.members[2] }, focusedMember = 1 }
	local secondWasFocused = group.focusedMember == 2

	region.groups[groupIndex] = first
	table.insert(region.groups, groupIndex + 1, second)

	if region.activeGroup == groupIndex and secondWasFocused then
		region.activeGroup = groupIndex + 1
	elseif region.activeGroup > groupIndex then
		region.activeGroup = region.activeGroup + 1
	end

	M.rebuildWindowIndex()
	M.layoutGroup(regionName, first)
	M.layoutGroup(regionName, second)
	M.raiseActiveGroups()
	M.render()
	hs.alert.show("Windows do not fit in one group; split into two groups")
end

-- Live window restoration ----------------------------------------------------

function M.restoreWindows()
	local filter = hs.window.filter.new()
	filter:setOverrideFilter({ visible = true, fullscreen = false, allowRoles = "AXStandardWindow" })
	filter:setSortOrder(hs.window.filter.sortByCreated)

	local windows = filter:getWindows()
	local used = {}

	for _, regionName in ipairs(M.regionOrder) do
		for _, group in ipairs(M.regions[regionName].groups) do
			for _, member in ipairs(group.members) do
				member.window = nil

				for _, window in ipairs(windows) do
					local windowID = window:id()

					if windowID and not used[windowID] and getBundleID(window) == member.bundleID then
						member.window = window
						used[windowID] = true
						break
					end
				end
			end
		end
	end

	for _, window in ipairs(windows) do
		local windowID = window:id()
		local bundleID = getBundleID(window)

		if windowID and not used[windowID] and bundleID then
			local regionName = M.knownRegionForBundle(bundleID)

			if regionName then
				local region = M.regions[regionName]
				table.insert(region.groups, {
					members = { { bundleID = bundleID, window = window } },
					focusedMember = 1,
				})
				used[windowID] = true
			end
		end
	end

	M.rebuildWindowIndex()
	M.layoutAllGroups()
	M.raiseActiveGroups()
end

function M.attachCreatedWindow(window)
	if not M.enabled or not window or not window:id() or M.windowIndex[window:id()] then
		return
	end

	local bundleID = getBundleID(window)

	if not bundleID then
		return
	end

	local regionName, groupIndex, memberIndex = M.firstPendingMember(bundleID)

	if regionName then
		local group = M.regions[regionName].groups[groupIndex]
		group.members[memberIndex].window = window
		M.rebuildWindowIndex()
		M.layoutGroup(regionName, group)
		M.raiseActiveGroups()
		M.render()
		return
	end

	regionName = M.knownRegionForBundle(bundleID)

	if regionName then
		local region = M.regions[regionName]
		local group = { members = { { bundleID = bundleID, window = window } }, focusedMember = 1 }

		table.insert(region.groups, group)
		region.activeGroup = #region.groups
		M.rebuildWindowIndex()
		M.layoutGroup(regionName, group)
		M.render()
	end
end

function M.windowDestroyed(window)
	local location = window and window:id() and M.windowIndex[window:id()]

	if not location then
		return
	end

	local region = M.regions[location.regionName]
	local group = region.groups[location.groupIndex]
	group.members[location.memberIndex].window = nil
	M.rebuildWindowIndex()
	M.raiseActiveGroups()
	M.render()
end

function M.windowFocused(window)
	local location = M.getWindowLocation(window)

	if not location then
		return
	end

	local region = M.regions[location.regionName]
	local group = region.groups[location.groupIndex]
	region.activeGroup = location.groupIndex
	group.focusedMember = location.memberIndex
	M.layoutGroup(location.regionName, group)
	M.raiseGroup(group, false)
	M.render()
end

function M.startWindowWatcher()
	M.windowFilter = hs.window.filter.new()
	M.windowFilter:setOverrideFilter({ visible = true, fullscreen = false, allowRoles = "AXStandardWindow" })
	M.windowFilter:subscribe(hs.window.filter.windowCreated, function(window)
		hs.timer.doAfter(0.5, function()
			M.attachCreatedWindow(window)
		end)
	end)
	M.windowFilter:subscribe(hs.window.filter.windowDestroyed, function(window)
		M.windowDestroyed(window)
	end)
	M.windowFilter:subscribe(hs.window.filter.windowFocused, function(window)
		M.windowFocused(window)
	end)
end

-- Group membership -----------------------------------------------------------

function M.detachWindow(window)
	local location = M.getWindowLocation(window)

	if not location then
		return { bundleID = getBundleID(window), window = window }
	end

	local region = M.regions[location.regionName]
	local group = region.groups[location.groupIndex]
	local member = table.remove(group.members, location.memberIndex)

	if #group.members == 0 then
		table.remove(region.groups, location.groupIndex)
		region.activeGroup = clamp(region.activeGroup, 1, math.max(1, #region.groups))
	else
		group.leftWidth = nil
		group.focusedMember = 1
		M.layoutGroup(location.regionName, group)
	end

	M.rebuildWindowIndex()
	return member
end

function M.moveWindowToRegion(regionName)
	if not M.enabled or not M.regions[regionName] then
		return
	end

	local window = hs.window.focusedWindow()
	local bundleID = getBundleID(window)

	if not window or not bundleID then
		return
	end

	local member = M.detachWindow(window)
	local region = M.regions[regionName]
	local group = { members = { member }, focusedMember = 1 }

	table.insert(region.groups, group)
	region.activeGroup = #region.groups
	M.rebuildWindowIndex()
	M.activateGroup(regionName, region.activeGroup)
end

function M.moveWindowToLeft()
	M.moveWindowToRegion("left")
end

function M.moveWindowToCenter()
	M.moveWindowToRegion("center")
end

function M.moveWindowToRight()
	M.moveWindowToRegion("right")
end

function M.addWindowToActiveGroup(regionName)
	if not M.enabled or not M.regions[regionName] then
		return
	end

	local window = hs.window.focusedWindow()
	local bundleID = getBundleID(window)
	local region = M.regions[regionName]
	local target = region.groups[region.activeGroup]

	if not window or not bundleID then
		return
	end

	if not target then
		M.moveWindowToRegion(regionName)
		return
	end

	local location = M.getWindowLocation(window)

	if location and location.regionName == regionName and location.groupIndex == region.activeGroup then
		return
	end

	if #target.members >= 2 then
		hs.alert.show("This group already has two windows")
		return
	end

	local originalWidth = round(window:frame().w)
	local member = M.detachWindow(window)
	table.insert(target.members, member)

	local defaultMinWidth = M.options.defaultMinWidth or 200
	local leftMin = target.members[1].minWidth or defaultMinWidth
	local rightMin = target.members[2].minWidth or defaultMinWidth
	local rightWidth = clamp(originalWidth, rightMin, region.frame.w - leftMin)
	target.leftWidth = region.frame.w - rightWidth
	target.focusedMember = 2
	M.rebuildWindowIndex()
	M.activateGroup(regionName, M.findGroup(regionName, target))
end

function M.addWindowToLeftGroup()
	M.addWindowToActiveGroup("left")
end

function M.addWindowToCenterGroup()
	M.addWindowToActiveGroup("center")
end

function M.addWindowToRightGroup()
	M.addWindowToActiveGroup("right")
end

function M.extractWindowFromGroup()
	local window = hs.window.focusedWindow()
	local location = M.getWindowLocation(window)

	if not location then
		return
	end

	local region = M.regions[location.regionName]
	local group = region.groups[location.groupIndex]

	if #group.members == 1 then
		M.detachWindow(window)
		M.render()
		return
	end

	local member = table.remove(group.members, location.memberIndex)
	group.leftWidth = nil
	group.focusedMember = 1
	local newGroup = { members = { member }, focusedMember = 1 }

	table.insert(region.groups, location.groupIndex + 1, newGroup)
	region.activeGroup = location.groupIndex + 1
	M.rebuildWindowIndex()
	M.layoutGroup(location.regionName, group)
	M.activateGroup(location.regionName, region.activeGroup)
end

function M.forgetFocusedWindow()
	local window = hs.window.focusedWindow()

	if M.isManaged(window) then
		M.detachWindow(window)
		M.render()
	end
end

function M.forgetActiveGroup()
	local location = M.getWindowLocation(hs.window.focusedWindow())

	if not location then
		return
	end

	local region = M.regions[location.regionName]
	table.remove(region.groups, location.groupIndex)
	region.activeGroup = clamp(region.activeGroup, 1, math.max(1, #region.groups))
	M.rebuildWindowIndex()
	M.render()
end

-- Navigation -----------------------------------------------------------------

function M.cycleGroup(delta)
	local location = M.getWindowLocation(hs.window.focusedWindow())

	if not location then
		return false
	end

	local region = M.regions[location.regionName]
	local index = location.groupIndex

	for _ = 1, #region.groups do
		index = ((index - 1 + delta) % #region.groups) + 1

		if liveMemberCount(region.groups[index]) > 0 then
			if index == location.groupIndex then
				return false
			end

			M.activateGroup(location.regionName, index)
			return true
		end
	end

	return false
end

function M.focusPreviousGroup()
	M.cycleGroup(-1)
end

function M.focusNextGroup()
	M.cycleGroup(1)
end

function M.focusNorth()
	if not M.cycleGroup(-1) then
		hs.window.filter.focusNorth()
	end
end

function M.focusSouth()
	if not M.cycleGroup(1) then
		hs.window.filter.focusSouth()
	end
end

function M.focusMember(memberIndex)
	local location = M.getWindowLocation(hs.window.focusedWindow())

	if not location then
		return false
	end

	local group = M.regions[location.regionName].groups[location.groupIndex]
	local member = group.members[memberIndex]

	if not member or not member.window then
		return false
	end

	group.focusedMember = memberIndex
	member.window:focus()
	M.render()
	return true
end

function M.focusPreviousMember()
	M.focusMember(1)
end

function M.focusNextMember()
	M.focusMember(2)
end

function M.focusRegionInDirection(regionName, delta)
	local current = nil

	for index, name in ipairs(M.regionOrder) do
		if name == regionName then
			current = index
			break
		end
	end

	if not current then
		return false
	end

	local index = current + delta

	while M.regionOrder[index] do
		local targetName = M.regionOrder[index]
		local target = M.regions[targetName]
		local active = target.groups[target.activeGroup]

		if active and liveMemberCount(active) > 0 then
			return M.activateGroup(targetName, target.activeGroup)
		end

		for groupIndex, group in ipairs(target.groups) do
			if liveMemberCount(group) > 0 then
				return M.activateGroup(targetName, groupIndex)
			end
		end

		index = index + delta
	end

	return false
end

function M.focusWest()
	local window = hs.window.focusedWindow()
	local location = M.getWindowLocation(window)

	if not location then
		hs.window.filter.focusWest()
		return
	end

	if location.memberIndex == 2 and M.focusMember(1) then
		return
	end

	if not M.focusRegionInDirection(location.regionName, -1) then
		hs.window.filter.focusWest()
	end
end

function M.focusEast()
	local window = hs.window.focusedWindow()
	local location = M.getWindowLocation(window)

	if not location then
		hs.window.filter.focusEast()
		return
	end

	if location.memberIndex == 1 and M.focusMember(2) then
		return
	end

	if not M.focusRegionInDirection(location.regionName, 1) then
		hs.window.filter.focusEast()
	end
end

-- Member resizing ------------------------------------------------------------

function M.resizeFocusedMember(direction)
	local location = M.getWindowLocation(hs.window.focusedWindow())

	if not location then
		return
	end

	local region = M.regions[location.regionName]
	local group = region.groups[location.groupIndex]

	if #group.members ~= 2 or not group.members[1].window or not group.members[2].window then
		return
	end

	local amount = M.options.resizeStep or 80
	local change = location.memberIndex == 1 and direction * amount or -direction * amount
	group.leftWidth = round(group.leftWidth or region.frame.w / 2) + change
	M.layoutGroup(location.regionName, group)
	M.render()
end

function M.growFocusedMember()
	M.resizeFocusedMember(1)
end

function M.shrinkFocusedMember()
	M.resizeFocusedMember(-1)
end

function M.resetGroupSplit()
	local location = M.getWindowLocation(hs.window.focusedWindow())

	if not location then
		return
	end

	local region = M.regions[location.regionName]
	local group = region.groups[location.groupIndex]

	if #group.members == 2 then
		group.leftWidth = round(region.frame.w / 2)
		M.layoutGroup(location.regionName, group)
	end
end

return M
