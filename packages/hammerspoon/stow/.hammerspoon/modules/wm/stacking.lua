local store = require("modules.wm.stacking_store")
local ui = require("modules.wm.stacking_ui")
local virtualScreens = require("modules.wm.virtual_screens")

local M = {
	screenOrder = {},
	screens = {},
	windowIndex = {},
	enabled = false,
}

---@type table<string, fun()>
local workspaceHotkeyHandlers = {}

local function copyFrame(frame)
	return { x = frame.x, y = frame.y, w = frame.w, h = frame.h }
end

local function round(number)
	return math.floor(number + 0.5)
end

local function clamp(number, minimum, maximum)
	return math.max(minimum, math.min(maximum, number))
end

local function setFrameIfChanged(window, target)
	local current = window:frame()
	local tolerance = 1
	local unchanged = math.abs(current.x - target.x) <= tolerance
		and math.abs(current.y - target.y) <= tolerance
		and math.abs(current.w - target.w) <= tolerance
		and math.abs(current.h - target.h) <= tolerance

	if unchanged then
		return false
	end

	window:setFrame(target, 0)
	return true
end

local function framesMatch(first, second)
	local tolerance = 2

	return math.abs(first.x - second.x) <= tolerance
		and math.abs(first.y - second.y) <= tolerance
		and math.abs(first.w - second.w) <= tolerance
		and math.abs(first.h - second.h) <= tolerance
end

local function getBundleID(window)
	local app = window and window:application()

	return app and app:bundleID() or nil
end

local function liveMemberCount(workspace)
	local count = 0

	for _, member in ipairs(workspace.members) do
		if member.window then
			count = count + 1
		end
	end

	return count
end

local function emptyProfileState()
	local state = { screens = {} }

	for _, screenName in ipairs(M.screenOrder) do
		state.screens[screenName] = { activeWorkspace = 1, workspaces = {} }
	end

	return state
end

local function normalizeDocument(state)
	if type(state.profiles) == "table" then
		state.version = 2
		return state
	end

	-- Version 1 stored the ultrawide regions directly. Keep that snapshot
	-- intact and migrate it into the ultrawide virtual-screen profile.
	if type(state.regions) == "table" then
		return {
			version = 2,
			profiles = {
				ultrawide = { screens = state.regions },
			},
		}
	end

	return { version = 2, profiles = {} }
end

-- Setup ----------------------------------------------------------------------

function M.setup(config)
	M.config = config or {}
	M.options = M.config.config or {}
	M.logger = hs.logger.new("stacking", M.options.logLevel or "info")
	M.stateFile = hs.configdir .. "/state/stacks.json"
	M.savedStateExists = store.exists(M.stateFile)
	M.loadedFromDisk = false

	local physicalScreen = hs.screen.primaryScreen()
	local physicalFrame = physicalScreen and physicalScreen:fullFrame()

	if not physicalFrame then
		M.logger.e("Unable to resolve the primary screen")
		return
	end

	local resolved = virtualScreens.resolve(physicalFrame, M.options)
	M.physicalFrame = copyFrame(physicalFrame)
	M.profileName = resolved.profileName
	M.screenOrder = resolved.order
	M.screens = resolved.screens

	M.applyState(emptyProfileState())
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
		local handler = M[action] or workspaceHotkeyHandlers[action]

		if type(handler) ~= "function" then
			M.logger.e("Unknown stacking action: " .. tostring(action))
		else
			hs.hotkey.bind(hotkey[1], hotkey[2], handler)
		end
	end
end

-- Persisted model ------------------------------------------------------------

function M.applyState(state)
	state.screens = type(state.screens) == "table" and state.screens or {}

	for _, screenName in ipairs(M.screenOrder) do
		local savedScreen = state.screens[screenName]

		if type(savedScreen) ~= "table" then
			savedScreen = { activeWorkspace = 1, workspaces = {} }
		end

		-- Version 1 called these regions and groups. Read both names so an
		-- existing stacks.json can be migrated without changing its meaning.
		local savedWorkspaces = savedScreen.workspaces or savedScreen.groups or {}
		M.screens[screenName].workspaces = {}
		M.screens[screenName].activeWorkspace = tonumber(savedScreen.activeWorkspace or savedScreen.activeGroup) or 1

		for _, savedWorkspace in ipairs(savedWorkspaces) do
			local workspace = {
				members = {},
				leftWidth = tonumber(savedWorkspace.leftWidth),
				focusedMember = tonumber(savedWorkspace.focusedMember) or 1,
				keepEmpty = savedWorkspace.keepEmpty == true or #(savedWorkspace.members or {}) == 0,
			}

			for _, savedMember in ipairs(savedWorkspace.members or {}) do
				if #workspace.members < 2 and type(savedMember.bundleID) == "string" then
					table.insert(workspace.members, {
						bundleID = savedMember.bundleID,
						minWidth = tonumber(savedMember.minWidth),
						window = nil,
					})
				end
			end

			-- Empty workspaces are intentional placeholders created by direct
			-- workspace selection, so keep them across save/load.
			table.insert(M.screens[screenName].workspaces, workspace)
		end

		local workspaceCount = #M.screens[screenName].workspaces
		M.screens[screenName].activeWorkspace =
			clamp(M.screens[screenName].activeWorkspace, 1, math.max(1, workspaceCount))
	end
end

function M.serializableState()
	local state = emptyProfileState()

	for _, screenName in ipairs(M.screenOrder) do
		local virtualScreen = M.screens[screenName]
		local savedScreen = state.screens[screenName]
		savedScreen.activeWorkspace = virtualScreen.activeWorkspace

		for _, workspace in ipairs(virtualScreen.workspaces) do
			local savedWorkspace = {
				members = {},
				focusedMember = workspace.focusedMember,
				keepEmpty = workspace.keepEmpty or nil,
			}

			if #workspace.members == 2 then
				savedWorkspace.leftWidth = workspace.leftWidth
			end

			for _, member in ipairs(workspace.members) do
				table.insert(savedWorkspace.members, {
					bundleID = member.bundleID,
					minWidth = member.minWidth,
				})
			end

			table.insert(savedScreen.workspaces, savedWorkspace)
		end
	end

	return state
end

function M.saveState()
	local document = M.savedDocument or { version = 2, profiles = {} }
	document.version = 2
	document.profiles = document.profiles or {}
	document.profiles[M.profileName] = M.serializableState()

	if not store.save(M.stateFile, document) then
		M.logger.e("Unable to save stack state to " .. M.stateFile)
		return false
	end

	M.savedDocument = document
	return true
end

function M.hasWorkspaces()
	for _, screenName in ipairs(M.screenOrder) do
		if #M.screens[screenName].workspaces > 0 then
			return true
		end
	end

	return false
end

function M.saveStacks()
	if M.savedStateExists and not M.loadedFromDisk and not M.hasWorkspaces() then
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

	local document = normalizeDocument(state)
	M.savedDocument = document
	M.applyState(document.profiles[M.profileName] or emptyProfileState())
	M.loadedFromDisk = true
	M.restoreWindows()
	M.render()

	if showAlert ~= false then
		hs.alert.show("Window stacks loaded")
	end
end

function M.rebuildWindowIndex()
	M.windowIndex = {}

	for _, screenName in ipairs(M.screenOrder) do
		local virtualScreen = M.screens[screenName]

		for workspaceIndex, workspace in ipairs(virtualScreen.workspaces) do
			for memberIndex, member in ipairs(workspace.members) do
				if member.window and member.window:id() then
					M.windowIndex[member.window:id()] = {
						screenName = screenName,
						workspaceIndex = workspaceIndex,
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

function M.resolveScreenName(screenName)
	if M.screens[screenName] then
		return screenName
	end

	-- The existing left/center/right hotkeys remain useful on a laptop:
	-- all three names simply refer to its only virtual screen.
	if #M.screenOrder == 1 then
		return M.screenOrder[1]
	end

	return nil
end

function M.screenNameForWindow(window)
	local location = M.getWindowLocation(window)

	if location then
		return location.screenName
	end

	local windowFrame = window and window:frame()

	if windowFrame then
		local centerX = windowFrame.x + windowFrame.w / 2
		local centerY = windowFrame.y + windowFrame.h / 2

		for _, screenName in ipairs(M.screenOrder) do
			local frame = M.screens[screenName].frame

			if
				centerX >= frame.x
				and centerX < frame.x + frame.w
				and centerY >= frame.y
				and centerY < frame.y + frame.h
			then
				return screenName
			end
		end
	end

	return M.currentScreenName or M.screenOrder[1]
end

function M.selectedScreenName()
	local current = M.currentScreenName and M.screens[M.currentScreenName]
	local active = current and current.workspaces[current.activeWorkspace]

	-- Minimizing the last window in a virtual screen can make macOS focus a
	-- window elsewhere. Keep keyboard workspace actions on the empty screen
	-- until the user deliberately focuses another managed window.
	if active and liveMemberCount(active) == 0 then
		return M.currentScreenName
	end

	return M.screenNameForWindow(hs.window.focusedWindow())
end

function M.render()
	if M.enabled then
		ui.render(M.screens, M.screenOrder, M.options.ui or {}, M.expandedIndicator)
	end
end

function M.flashWorkspaceIndicator(screenName, workspaceIndex)
	M.indicatorVersion = (M.indicatorVersion or 0) + 1
	M.expandedIndicator = { screenName = screenName, workspaceIndex = workspaceIndex }
	local version = M.indicatorVersion
	M.render()

	hs.timer.doAfter(M.options.indicatorDuration or 1.5, function()
		if M.indicatorVersion == version then
			M.expandedIndicator = nil
			M.render()
		end
	end)
end

function M.findWorkspace(screenName, wantedWorkspace)
	for index, workspace in ipairs(M.screens[screenName].workspaces) do
		if workspace == wantedWorkspace then
			return index
		end
	end

	return nil
end

function M.knownScreenForBundle(bundleID)
	for _, screenName in ipairs(M.screenOrder) do
		for _, workspace in ipairs(M.screens[screenName].workspaces) do
			for _, member in ipairs(workspace.members) do
				if member.bundleID == bundleID then
					return screenName
				end
			end
		end
	end

	return nil
end

function M.firstPendingMember(bundleID)
	for _, screenName in ipairs(M.screenOrder) do
		for workspaceIndex, workspace in ipairs(M.screens[screenName].workspaces) do
			for memberIndex, member in ipairs(workspace.members) do
				if member.bundleID == bundleID and not member.window then
					return screenName, workspaceIndex, memberIndex
				end
			end
		end
	end

	return nil
end

function M.findFinderTabReplacement(window)
	if getBundleID(window) ~= "com.apple.finder" then
		return nil
	end

	local newFrame = window:frame()

	for _, screenName in ipairs(M.screenOrder) do
		for workspaceIndex, workspace in ipairs(M.screens[screenName].workspaces) do
			for memberIndex, member in ipairs(workspace.members) do
				local existing = member.window

				if
					member.bundleID == "com.apple.finder"
					and existing
					and existing:id() ~= window:id()
					and not existing:isVisible()
					and framesMatch(existing:frame(), newFrame)
				then
					return screenName, workspaceIndex, memberIndex
				end
			end
		end
	end

	return nil
end

-- Layout ---------------------------------------------------------------------

function M.layoutWorkspace(screenName, workspace, shouldVerify)
	local virtualScreen = M.screens[screenName]
	local liveMembers = {}

	for memberIndex, member in ipairs(workspace.members) do
		if member.window then
			table.insert(liveMembers, { member = member, index = memberIndex })
		end
	end

	if #liveMembers == 0 then
		return
	end

	if #liveMembers == 1 then
		setFrameIfChanged(liveMembers[1].member.window, copyFrame(virtualScreen.frame))
		liveMembers[1].member.parked = false
		return
	end

	local defaultMinWidth = M.options.defaultMinWidth or 200
	local leftMin = workspace.members[1].minWidth or defaultMinWidth
	local rightMin = workspace.members[2].minWidth or defaultMinWidth

	if leftMin + rightMin > virtualScreen.frame.w then
		M.splitImpossibleWorkspace(screenName, workspace)
		return
	end

	local requestedLeftWidth = round(workspace.leftWidth or virtualScreen.frame.w / 2)
	requestedLeftWidth = clamp(requestedLeftWidth, leftMin, virtualScreen.frame.w - rightMin)
	workspace.leftWidth = requestedLeftWidth

	local leftFrame = copyFrame(virtualScreen.frame)
	leftFrame.w = requestedLeftWidth
	local rightFrame = copyFrame(virtualScreen.frame)
	rightFrame.x = virtualScreen.frame.x + requestedLeftWidth
	rightFrame.w = virtualScreen.frame.w - requestedLeftWidth

	local leftChanged = setFrameIfChanged(workspace.members[1].window, leftFrame)
	local rightChanged = setFrameIfChanged(workspace.members[2].window, rightFrame)
	workspace.members[1].parked = false
	workspace.members[2].parked = false

	if shouldVerify ~= false and (leftChanged or rightChanged) then
		if shouldVerify ~= "continue" then
			workspace.verifyPass = 0
		end

		workspace.resizeVersion = (workspace.resizeVersion or 0) + 1
		local version = workspace.resizeVersion

		hs.timer.doAfter(M.options.verifyDelay or 0.08, function()
			M.verifyWorkspaceLayout(screenName, workspace, requestedLeftWidth, version)
		end)
	end
end

function M.verifyWorkspaceLayout(screenName, workspace, requestedLeftWidth, version)
	if workspace.resizeVersion ~= version or not M.findWorkspace(screenName, workspace) then
		return
	end

	local left = workspace.members[1]
	local right = workspace.members[2]

	if not left or not right or not left.window or not right.window then
		return
	end

	local virtualScreen = M.screens[screenName]
	local tolerance = M.options.frameTolerance or 2
	local leftFrame = left.window:frame()
	local rightFrame = right.window:frame()
	local requestedRightWidth = virtualScreen.frame.w - requestedLeftWidth
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

	if leftMin + rightMin > virtualScreen.frame.w then
		M.splitImpossibleWorkspace(screenName, workspace)
		return
	end

	local correctedWidth = clamp(requestedLeftWidth, leftMin, virtualScreen.frame.w - rightMin)

	if learnedMinimum or correctedWidth ~= workspace.leftWidth then
		workspace.leftWidth = correctedWidth
		workspace.verifyPass = (workspace.verifyPass or 0) + 1
		M.layoutWorkspace(screenName, workspace, workspace.verifyPass < 2 and "continue" or false)
	end

	M.render()
end

function M.layoutAllWorkspaces()
	for _, screenName in ipairs(M.screenOrder) do
		for _, workspace in ipairs(M.screens[screenName].workspaces) do
			M.layoutWorkspace(screenName, workspace)
		end
	end
end

function M.raiseWorkspace(workspace, shouldFocus)
	local focusIndex = clamp(workspace.focusedMember or 1, 1, #workspace.members)

	for _, member in ipairs(workspace.members) do
		if member.window then
			member.window:raise()
		end
	end

	if shouldFocus then
		local focusedMember = workspace.members[focusIndex]

		if not focusedMember or not focusedMember.window then
			for index, member in ipairs(workspace.members) do
				if member.window then
					focusedMember = member
					workspace.focusedMember = index
					break
				end
			end
		end

		if focusedMember and focusedMember.window then
			focusedMember.window:focus()
		end
	end
end

function M.parkWorkspace(workspace)
	local offset = M.options.parkingOffset or 1

	for _, member in ipairs(workspace.members) do
		local window = member.window

		if window and not member.parked then
			local frame = window:frame()
			frame.x = M.physicalFrame.x + M.physicalFrame.w + offset
			frame.y = M.physicalFrame.y + M.physicalFrame.h + offset
			setFrameIfChanged(window, frame)
			member.parked = true
		end
	end
end

function M.parkAllWorkspaces(screenName)
	for _, workspace in ipairs(M.screens[screenName].workspaces) do
		if liveMemberCount(workspace) > 0 then
			M.parkWorkspace(workspace)
		end
	end
end

function M.activateWorkspace(screenName, workspaceIndex, shouldFocus)
	local virtualScreen = M.screens[screenName]
	local workspace = virtualScreen.workspaces[workspaceIndex]

	if not workspace then
		return false
	end

	M.currentScreenName = screenName
	virtualScreen.activeWorkspace = workspaceIndex

	if liveMemberCount(workspace) > 0 then
		M.layoutWorkspace(screenName, workspace)
		M.raiseWorkspace(workspace, shouldFocus ~= false)
	else
		-- Non-empty workspaces cover one another, so ordinary navigation only
		-- raises the target. Parking is needed solely to expose an empty one.
		M.parkAllWorkspaces(screenName)
	end

	M.render()

	return true
end

function M.raiseActiveWorkspaces()
	for _, screenName in ipairs(M.screenOrder) do
		local virtualScreen = M.screens[screenName]
		local active = virtualScreen.workspaces[virtualScreen.activeWorkspace]

		if not active then
			for workspaceIndex, workspace in ipairs(virtualScreen.workspaces) do
				if liveMemberCount(workspace) > 0 then
					virtualScreen.activeWorkspace = workspaceIndex
					break
				end
			end

			active = virtualScreen.workspaces[virtualScreen.activeWorkspace]
		end

		if active and liveMemberCount(active) > 0 then
			M.raiseWorkspace(active, false)
		elseif active then
			M.parkAllWorkspaces(screenName)
		end
	end
end

function M.splitImpossibleWorkspace(screenName, workspace)
	local virtualScreen = M.screens[screenName]
	local workspaceIndex = M.findWorkspace(screenName, workspace)

	if not workspaceIndex or #workspace.members ~= 2 then
		return
	end

	local first = { members = { workspace.members[1] }, focusedMember = 1, keepEmpty = workspace.keepEmpty }
	local second = { members = { workspace.members[2] }, focusedMember = 1 }
	local secondWasFocused = workspace.focusedMember == 2

	virtualScreen.workspaces[workspaceIndex] = first
	table.insert(virtualScreen.workspaces, workspaceIndex + 1, second)

	if virtualScreen.activeWorkspace == workspaceIndex and secondWasFocused then
		virtualScreen.activeWorkspace = workspaceIndex + 1
	elseif virtualScreen.activeWorkspace > workspaceIndex then
		virtualScreen.activeWorkspace = virtualScreen.activeWorkspace + 1
	end

	M.rebuildWindowIndex()
	M.layoutWorkspace(screenName, first)
	M.layoutWorkspace(screenName, second)
	M.raiseActiveWorkspaces()
	M.render()
	hs.alert.show("Windows do not fit in one workspace; split into two workspaces")
end

-- Live window restoration ----------------------------------------------------

function M.restoreWindows()
	local filter = hs.window.filter.new()
	filter:setOverrideFilter({ visible = true, fullscreen = false, allowRoles = "AXStandardWindow" })
	filter:setSortOrder(hs.window.filter.sortByCreated)

	local windows = filter:getWindows()
	local used = {}

	for _, screenName in ipairs(M.screenOrder) do
		for _, workspace in ipairs(M.screens[screenName].workspaces) do
			for _, member in ipairs(workspace.members) do
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
			local screenName = M.knownScreenForBundle(bundleID)

			if screenName then
				local virtualScreen = M.screens[screenName]
				table.insert(virtualScreen.workspaces, {
					members = {
						{
							bundleID = bundleID,
							window = window,
						},
					},
					focusedMember = 1,
				})
				used[windowID] = true
			end
		end
	end

	M.rebuildWindowIndex()
	M.layoutAllWorkspaces()
	M.raiseActiveWorkspaces()
end

function M.attachCreatedWindow(window)
	if
		not M.enabled
		or not window
		or not window:id()
		or not window:isVisible()
		or not window:isStandard()
		or M.windowIndex[window:id()]
	then
		return
	end

	local bundleID = getBundleID(window)

	if not bundleID then
		return
	end

	local screenName, workspaceIndex, memberIndex = M.firstPendingMember(bundleID)

	if not screenName then
		screenName, workspaceIndex, memberIndex = M.findFinderTabReplacement(window)
	end

	if screenName then
		local workspace = M.screens[screenName].workspaces[workspaceIndex]
		workspace.members[memberIndex].window = window
		M.rebuildWindowIndex()
		M.layoutWorkspace(screenName, workspace)
		M.raiseActiveWorkspaces()
		M.render()
		return
	end

	screenName = M.knownScreenForBundle(bundleID)

	if screenName then
		local virtualScreen = M.screens[screenName]
		local workspace = {
			members = {
				{
					bundleID = bundleID,
					window = window,
				},
			},
			focusedMember = 1,
		}

		table.insert(virtualScreen.workspaces, workspace)
		M.rebuildWindowIndex()
		M.activateWorkspace(screenName, #virtualScreen.workspaces)
	end
end

function M.windowDestroyed(window)
	local location = window and window:id() and M.windowIndex[window:id()]

	if not location then
		return
	end

	local virtualScreen = M.screens[location.screenName]
	local workspace = virtualScreen.workspaces[location.workspaceIndex]
	workspace.members[location.memberIndex].window = nil
	M.rebuildWindowIndex()
	M.raiseActiveWorkspaces()
	M.render()
end

function M.windowFocused(window)
	local location = M.getWindowLocation(window)

	if not location then
		return
	end

	local virtualScreen = M.screens[location.screenName]
	local workspace = virtualScreen.workspaces[location.workspaceIndex]
	workspace.focusedMember = location.memberIndex
	M.activateWorkspace(location.screenName, location.workspaceIndex, false)
	M.flashWorkspaceIndicator(location.screenName, location.workspaceIndex)
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

-- Workspace membership -------------------------------------------------------

function M.detachWindow(window)
	local location = M.getWindowLocation(window)

	if not location then
		return { bundleID = getBundleID(window), window = window }
	end

	local virtualScreen = M.screens[location.screenName]
	local workspace = virtualScreen.workspaces[location.workspaceIndex]
	local member = table.remove(workspace.members, location.memberIndex)

	if #workspace.members == 0 then
		if workspace.keepEmpty then
			workspace.leftWidth = nil
			workspace.focusedMember = 1
		else
			table.remove(virtualScreen.workspaces, location.workspaceIndex)
			virtualScreen.activeWorkspace =
				clamp(virtualScreen.activeWorkspace, 1, math.max(1, #virtualScreen.workspaces))
		end
	else
		workspace.leftWidth = nil
		workspace.focusedMember = 1
		M.layoutWorkspace(location.screenName, workspace)
	end

	M.rebuildWindowIndex()
	return member
end

function M.addWindowToWorkspace(screenName, workspace, window)
	local bundleID = getBundleID(window)

	if not window or not bundleID then
		return false
	end

	local location = M.getWindowLocation(window)
	local workspaceIndex = M.findWorkspace(screenName, workspace)

	if not workspaceIndex then
		return false
	end

	if location and location.screenName == screenName and location.workspaceIndex == workspaceIndex then
		return true
	end

	if #workspace.members >= 2 then
		hs.alert.show("This workspace already has two windows")
		return false
	end

	local virtualScreen = M.screens[screenName]
	local originalWidth = round(window:frame().w)
	local member = M.detachWindow(window)
	table.insert(workspace.members, member)

	if #workspace.members == 2 then
		local defaultMinWidth = M.options.defaultMinWidth or 200
		local leftMin = workspace.members[1].minWidth or defaultMinWidth
		local rightMin = workspace.members[2].minWidth or defaultMinWidth
		local rightWidth = clamp(originalWidth, rightMin, virtualScreen.frame.w - leftMin)
		workspace.leftWidth = virtualScreen.frame.w - rightWidth
		workspace.focusedMember = 2
	else
		workspace.focusedMember = 1
	end

	M.rebuildWindowIndex()
	M.activateWorkspace(screenName, M.findWorkspace(screenName, workspace))
	return true
end

function M.moveWindowToScreen(screenName)
	screenName = M.resolveScreenName(screenName)

	if not M.enabled or not screenName then
		return
	end

	local window = hs.window.focusedWindow()
	local bundleID = getBundleID(window)

	if not window or not bundleID then
		return
	end

	local virtualScreen = M.screens[screenName]
	local active = virtualScreen.workspaces[virtualScreen.activeWorkspace]

	if active and #active.members == 0 then
		M.addWindowToWorkspace(screenName, active, window)
		return
	end

	local member = M.detachWindow(window)
	local workspace = { members = { member }, focusedMember = 1 }

	table.insert(virtualScreen.workspaces, workspace)
	virtualScreen.activeWorkspace = #virtualScreen.workspaces
	M.rebuildWindowIndex()
	M.activateWorkspace(screenName, virtualScreen.activeWorkspace)
end

function M.moveWindowToLeft()
	M.moveWindowToScreen("left")
end

function M.moveWindowToCenter()
	M.moveWindowToScreen("center")
end

function M.moveWindowToRight()
	M.moveWindowToScreen("right")
end

function M.addWindowToActiveWorkspace(screenName)
	screenName = M.resolveScreenName(screenName)

	if not M.enabled or not screenName then
		return
	end

	local window = hs.window.focusedWindow()
	local virtualScreen = M.screens[screenName]
	local target = virtualScreen.workspaces[virtualScreen.activeWorkspace]

	if not window or not getBundleID(window) then
		return
	end

	if not target then
		M.moveWindowToScreen(screenName)
		return
	end

	M.addWindowToWorkspace(screenName, target, window)
end

function M.addWindowToLeftWorkspace()
	M.addWindowToActiveWorkspace("left")
end

function M.addWindowToCenterWorkspace()
	M.addWindowToActiveWorkspace("center")
end

function M.addWindowToRightWorkspace()
	M.addWindowToActiveWorkspace("right")
end

function M.extractWindowFromWorkspace()
	local window = hs.window.focusedWindow()
	local location = M.getWindowLocation(window)

	if not location then
		return
	end

	local virtualScreen = M.screens[location.screenName]
	local workspace = virtualScreen.workspaces[location.workspaceIndex]

	if #workspace.members == 1 then
		M.detachWindow(window)
		M.render()
		return
	end

	local member = table.remove(workspace.members, location.memberIndex)
	workspace.leftWidth = nil
	workspace.focusedMember = 1
	local newWorkspace = { members = { member }, focusedMember = 1 }

	table.insert(virtualScreen.workspaces, location.workspaceIndex + 1, newWorkspace)
	virtualScreen.activeWorkspace = location.workspaceIndex + 1
	M.rebuildWindowIndex()
	M.layoutWorkspace(location.screenName, workspace)
	M.activateWorkspace(location.screenName, virtualScreen.activeWorkspace)
end

function M.forgetFocusedWindow()
	local window = hs.window.focusedWindow()

	if M.isManaged(window) then
		M.detachWindow(window)
		M.render()
	end
end

function M.forgetActiveWorkspace()
	return M.deleteActiveWorkspace()
end

-- Navigation -----------------------------------------------------------------

function M.ensureWorkspace(screenName, workspaceIndex)
	local virtualScreen = M.screens[screenName]

	while #virtualScreen.workspaces < workspaceIndex do
		table.insert(virtualScreen.workspaces, { members = {}, focusedMember = 1, keepEmpty = true })
	end

	return virtualScreen.workspaces[workspaceIndex]
end

function M.moveFocusedWindowToWorkspace(workspaceIndex)
	if not M.enabled or workspaceIndex < 1 then
		return false
	end

	local window = hs.window.focusedWindow()
	local screenName = M.screenNameForWindow(window)

	if not window or not screenName then
		return false
	end

	local workspace = M.ensureWorkspace(screenName, workspaceIndex)
	workspace.keepEmpty = true
	return M.addWindowToWorkspace(screenName, workspace, window)
end

function M.deleteActiveWorkspace()
	if not M.enabled then
		return false
	end

	local screenName = M.selectedScreenName()
	local virtualScreen = screenName and M.screens[screenName]

	if not virtualScreen then
		return false
	end

	local workspaceIndex = virtualScreen.activeWorkspace
	local workspace = virtualScreen.workspaces[workspaceIndex]

	if not workspace then
		return false
	end

	-- Removing a non-empty workspace makes its windows floating again.
	if liveMemberCount(workspace) > 0 then
		M.layoutWorkspace(screenName, workspace)
	end
	table.remove(virtualScreen.workspaces, workspaceIndex)
	virtualScreen.activeWorkspace = clamp(workspaceIndex, 1, math.max(1, #virtualScreen.workspaces))
	M.rebuildWindowIndex()

	local nextWorkspace = virtualScreen.workspaces[virtualScreen.activeWorkspace]

	if nextWorkspace then
		M.activateWorkspace(screenName, virtualScreen.activeWorkspace)
	else
		M.currentScreenName = screenName
		M.render()
	end

	return true
end

function M.moveActiveWorkspace(delta)
	local screenName = M.selectedScreenName()
	local virtualScreen = screenName and M.screens[screenName]

	if not virtualScreen then
		return false
	end

	local fromIndex = virtualScreen.activeWorkspace
	local toIndex = fromIndex + delta

	if not virtualScreen.workspaces[toIndex] then
		return false
	end

	virtualScreen.workspaces[fromIndex], virtualScreen.workspaces[toIndex] =
		virtualScreen.workspaces[toIndex], virtualScreen.workspaces[fromIndex]
	virtualScreen.activeWorkspace = toIndex
	M.rebuildWindowIndex()
	M.flashWorkspaceIndicator(screenName, toIndex)
	return true
end

function M.moveWorkspaceEarlier()
	return M.moveActiveWorkspace(-1)
end

function M.moveWorkspaceLater()
	return M.moveActiveWorkspace(1)
end

function M.focusWorkspace(workspaceIndex)
	if not M.enabled or workspaceIndex < 1 then
		return false
	end

	local screenName = M.selectedScreenName()

	if not screenName then
		return false
	end

	local workspace = M.ensureWorkspace(screenName, workspaceIndex)
	workspace.keepEmpty = true
	M.rebuildWindowIndex()
	M.activateWorkspace(screenName, workspaceIndex)
	M.flashWorkspaceIndicator(screenName, workspaceIndex)
	return true
end

function M.cycleWorkspace(delta)
	local screenName = M.selectedScreenName()
	local virtualScreen = screenName and M.screens[screenName]

	if not virtualScreen or #virtualScreen.workspaces < 2 then
		return false
	end

	local index = ((virtualScreen.activeWorkspace - 1 + delta) % #virtualScreen.workspaces) + 1
	M.activateWorkspace(screenName, index)
	M.flashWorkspaceIndicator(screenName, index)
	return true
end

function M.focusPreviousWorkspace()
	M.cycleWorkspace(-1)
end

function M.focusNextWorkspace()
	M.cycleWorkspace(1)
end

function M.focusNorth()
	if not M.cycleWorkspace(-1) then
		hs.window.filter.focusNorth()
	end
end

function M.focusSouth()
	if not M.cycleWorkspace(1) then
		hs.window.filter.focusSouth()
	end
end

function M.focusMember(memberIndex)
	local location = M.getWindowLocation(hs.window.focusedWindow())

	if not location then
		return false
	end

	local workspace = M.screens[location.screenName].workspaces[location.workspaceIndex]
	local member = workspace.members[memberIndex]

	if not member or not member.window then
		return false
	end

	workspace.focusedMember = memberIndex
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

function M.focusScreenInDirection(screenName, delta)
	local current = nil

	for index, name in ipairs(M.screenOrder) do
		if name == screenName then
			current = index
			break
		end
	end

	if not current then
		return false
	end

	local index = current + delta

	while M.screenOrder[index] do
		local targetName = M.screenOrder[index]
		local target = M.screens[targetName]
		local active = target.workspaces[target.activeWorkspace]

		if active and liveMemberCount(active) > 0 then
			return M.activateWorkspace(targetName, target.activeWorkspace)
		end

		for workspaceIndex, workspace in ipairs(target.workspaces) do
			if liveMemberCount(workspace) > 0 then
				return M.activateWorkspace(targetName, workspaceIndex)
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

	if not M.focusScreenInDirection(location.screenName, -1) then
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

	if not M.focusScreenInDirection(location.screenName, 1) then
		hs.window.filter.focusEast()
	end
end

-- Member resizing ------------------------------------------------------------

function M.resizeFocusedMember(direction)
	local location = M.getWindowLocation(hs.window.focusedWindow())

	if not location then
		return
	end

	local virtualScreen = M.screens[location.screenName]
	local workspace = virtualScreen.workspaces[location.workspaceIndex]

	if #workspace.members ~= 2 or not workspace.members[1].window or not workspace.members[2].window then
		return
	end

	local amount = M.options.resizeStep or 80
	local change = location.memberIndex == 1 and direction * amount or -direction * amount
	workspace.leftWidth = round(workspace.leftWidth or virtualScreen.frame.w / 2) + change
	M.layoutWorkspace(location.screenName, workspace)
	M.render()
end

function M.growFocusedMember()
	M.resizeFocusedMember(1)
end

function M.shrinkFocusedMember()
	M.resizeFocusedMember(-1)
end

function M.resetWorkspaceSplit()
	local location = M.getWindowLocation(hs.window.focusedWindow())

	if not location then
		return
	end

	local virtualScreen = M.screens[location.screenName]
	local workspace = virtualScreen.workspaces[location.workspaceIndex]

	if #workspace.members == 2 then
		workspace.leftWidth = round(virtualScreen.frame.w / 2)
		M.layoutWorkspace(location.screenName, workspace)
	end
end

-- Named handlers keep declarative hotkey configuration simple.
for index = 1, 9 do
	local workspaceIndex = index
	workspaceHotkeyHandlers["focusWorkspace" .. workspaceIndex] = function()
		M.focusWorkspace(workspaceIndex)
	end
	workspaceHotkeyHandlers["moveFocusedWindowToWorkspace" .. workspaceIndex] = function()
		M.moveFocusedWindowToWorkspace(workspaceIndex)
	end
end

-- Preserve direct access such as stacking.focusWorkspace3 without widening
-- the inferred type of the module table itself.
setmetatable(M, { __index = workspaceHotkeyHandlers })

return M
