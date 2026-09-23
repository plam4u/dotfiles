--- === wm ===
---
--- Saves and restores window positions across multiple displays.
---
--- Windows are identified by application bundle ID and window title.
--- Displays are identified primarily by their macOS UUID, with display
--- name and resolution used as fallbacks if the UUID changes.
---
--- Window positions are stored relative to their display. This means a
--- display can move to a different position in the macOS display layout
--- without invalidating the saved window positions.
---
--- A permanent window watcher listens for newly-created windows. If a new
--- window uniquely matches an entry in the saved state, it is automatically
--- moved to its saved display and position. This also means that closing a
--- saved window and reopening it later will restore its position.
---
--- Usage:
---
---     local wm = require("wm")
---
---     wm.setup({
---         mapping = {
---             saveLayout    = { { "cmd", "ctrl" }, "s" },
---             restoreLayout = { { "cmd", "ctrl" }, "r" },
---         },
---     })
---
--- Hotkey mappings use the same format as `hs.hotkey.bind`:
---
---     { modifiers, key }
---
--- For example:
---
---     { { "cmd", "alt" }, "s" }
---
--- Supported mappings:
---
---  * `saveLayout`    - Save the current desktop arrangement.
---  * `restoreLayout` - Restore currently-open windows.
---
--- All mappings are optional.
---
--- State is persisted to:
---
---     ~/.hammerspoon/state/wm.json
---
--- Matching:
---
---  * Screens:
---      1. UUID
---      2. Unique display name
---      3. Unique display resolution
---
---  * Windows:
---      bundle ID + exact window title
---
--- If multiple saved windows have the same bundle ID and title, the match
--- is considered ambiguous and the window is not automatically restored.

local M = {}

M.state = {
	version = 1,
	screens = {},
}

M.windowWatcher = nil

-- -------------------------------------------------------------------------
-- Setup
-- -------------------------------------------------------------------------

function M.setup(config)
	M.config = config or {}
	M.logger = hs.logger.new("wm", "info")

	M.logger.i("Setting up wm module...")

	M.initialize()
	M.bindHotkeys(M.config.mapping or {})
	M.startWindowWatcher()
end

function M.initialize()
	M.logger.i("Initializing wm module...")

	M.configDir = hs.configdir .. "/state"
	M.stateFile = M.configDir .. "/wm.json"

	hs.fs.mkdir(M.configDir)

	local attrs = hs.fs.attributes(M.stateFile)

	if attrs and attrs.mode == "file" then
		local state = hs.json.read(M.stateFile)

		if state and state.screens then
			M.state = state

			M.logger.i("Loaded desktop state from " .. M.stateFile)
		else
			M.logger.e("Unable to load valid desktop state from " .. M.stateFile)
		end
	else
		M.writeState(M.state)
	end
end

function M.bindHotkeys(mapping)
	M.logger.i("Binding hotkeys for wm module...")

	for action, hotkey in pairs(mapping) do
		local handler = M[action]

		if type(handler) ~= "function" then
			M.logger.e("Unknown action: " .. tostring(action))
		else
			hs.hotkey.bind(hotkey[1], hotkey[2], handler)
		end
	end
end

-- -------------------------------------------------------------------------
-- State
-- -------------------------------------------------------------------------

function M.writeState(state)
	local success = hs.json.write(
		state,
		M.stateFile,
		true, -- pretty
		true -- replace existing file
	)

	if not success then
		M.logger.e("Failed to write desktop state to " .. M.stateFile)

		return false
	end

	return true
end

function M.reloadState()
	local state = hs.json.read(M.stateFile)

	if not state then
		M.logger.e("Unable to read desktop state from " .. M.stateFile)

		return false
	end

	if not state.screens then
		M.logger.e("Invalid desktop state: missing screens")

		return false
	end

	M.state = state

	return true
end

-- -------------------------------------------------------------------------
-- Screen matching
-- -------------------------------------------------------------------------

--- Finds the currently-connected hs.screen corresponding to a saved screen.
---
--- Matching order:
---
---   1. UUID
---   2. Unique display name
---   3. Unique display resolution
---
--- The saved screen is a plain Lua table loaded from wm.json.
--- The returned value is a live hs.screen object.
function M.findCurrentScreen(savedScreen)
	if not savedScreen then
		return nil
	end

	local currentScreens = hs.screen.allScreens()

	--
	-- 1. UUID
	--
	for _, currentScreen in ipairs(currentScreens) do
		if currentScreen:getUUID() == savedScreen.uuid then
			return currentScreen
		end
	end

	--
	-- 2. Unique display name
	--
	local nameMatches = {}

	for _, currentScreen in ipairs(currentScreens) do
		if currentScreen:name() == savedScreen.name then
			table.insert(nameMatches, currentScreen)
		end
	end

	if #nameMatches == 1 then
		M.logger.w("Screen UUID changed; matched by name: " .. savedScreen.name)

		return nameMatches[1]
	end

	--
	-- 3. Unique resolution
	--
	if savedScreen.frame then
		local resolutionMatches = {}

		for _, currentScreen in ipairs(currentScreens) do
			local frame = currentScreen:frame()

			if frame.w == savedScreen.frame.w and frame.h == savedScreen.frame.h then
				table.insert(resolutionMatches, currentScreen)
			end
		end

		if #resolutionMatches == 1 then
			local screen = resolutionMatches[1]

			M.logger.w(
				"Screen UUID changed; matched by resolution: "
					.. screen:name()
					.. " ("
					.. savedScreen.frame.w
					.. "x"
					.. savedScreen.frame.h
					.. ")"
			)

			return screen
		end
	end

	M.logger.w(
		"Unable to uniquely match saved screen: "
			.. (savedScreen.name or "<unknown>")
			.. " ["
			.. (savedScreen.uuid or "no UUID")
			.. "]"
	)

	return nil
end

-- -------------------------------------------------------------------------
-- Window lookup
-- -------------------------------------------------------------------------

--- Finds a saved window and its parent saved screen.
---
--- Windows are matched by:
---
---     bundle ID + exact title
---
--- Returns:
---
---     savedWindow, savedScreen
---
--- If there are zero matches or more than one match, nil is returned.
function M.findSavedWindow(bundleID, title)
	local matches = {}

	for _, savedScreen in ipairs(M.state.screens or {}) do
		for _, savedWindow in ipairs(savedScreen.windows or {}) do
			if savedWindow.bundleID == bundleID and savedWindow.title == title then
				table.insert(matches, {
					window = savedWindow,
					screen = savedScreen,
				})
			end
		end
	end

	if #matches == 1 then
		return matches[1].window, matches[1].screen
	end

	if #matches > 1 then
		M.logger.w(
			"Ambiguous saved window: "
				.. (title ~= "" and title or "<untitled>")
				.. " ["
				.. bundleID
				.. "]"
				.. " ("
				.. #matches
				.. " matches)"
		)
	end

	return nil, nil
end

-- -------------------------------------------------------------------------
-- Saving
-- -------------------------------------------------------------------------

function M.saveLayout()
	M.logger.i("Saving desktop state...")

	local arrangement = {
		version = 1,
		screens = {},
	}

	for _, screen in ipairs(hs.screen.allScreens()) do
		local screenFrame = screen:frame()

		local screenState = {
			uuid = screen:getUUID(),
			name = screen:name(),

			frame = {
				x = screenFrame.x,
				y = screenFrame.y,
				w = screenFrame.w,
				h = screenFrame.h,
			},

			windows = {},
		}

		M.logger.i("Saving screen: " .. screenState.name .. " [" .. screenState.uuid .. "]")

		local windows = hs.window.filter.new(true):setScreens(screen:getUUID()):getWindows()

		for _, window in ipairs(windows) do
			local app = window:application()

			if app then
				local bundleID = app:bundleID()

				if bundleID then
					local frame = window:frame()

					local windowState = {
						bundleID = bundleID,
						appName = app:name(),
						title = window:title() or "",

						-- Store the position relative to the display
						-- instead of macOS global coordinates.
						frame = {
							x = frame.x - screenFrame.x,
							y = frame.y - screenFrame.y,
							w = frame.w,
							h = frame.h,
						},
					}

					table.insert(screenState.windows, windowState)

					M.logger.i(
						"Saving window: "
							.. (windowState.title ~= "" and windowState.title or "<untitled>")
							.. " ["
							.. bundleID
							.. "]"
					)
				else
					M.logger.w("Skipping window without bundle ID: " .. (window:title() or "<untitled>"))
				end
			end
		end

		table.insert(arrangement.screens, screenState)
	end

	M.logger.i("Desktop arrangement:\n" .. hs.inspect(arrangement))

	if M.writeState(arrangement) then
		M.state = arrangement

		M.logger.i("Desktop state saved to " .. M.stateFile)
	end
end

-- -------------------------------------------------------------------------
-- Restoring
-- -------------------------------------------------------------------------

--- Restores one live window from its saved state.
function M.restoreWindow(window, savedWindow, savedScreen)
	local currentScreen = M.findCurrentScreen(savedScreen)

	if not currentScreen then
		M.logger.w(
			"Cannot restore window because its screen "
				.. "could not be matched: "
				.. (savedWindow.title ~= "" and savedWindow.title or "<untitled>")
		)

		return false
	end

	local frame = savedWindow.frame

	if not frame then
		M.logger.w("Saved window has no frame: " .. (savedWindow.title or "<untitled>"))

		return false
	end

	local screenFrame = currentScreen:frame()

	-- Convert the saved screen-relative coordinates back into
	-- the current macOS global coordinate space.
	local targetFrame = {
		x = screenFrame.x + frame.x,
		y = screenFrame.y + frame.y,
		w = frame.w,
		h = frame.h,
	}

	M.logger.i(
		"Restoring window: "
			.. (savedWindow.title ~= "" and savedWindow.title or "<untitled>")
			.. " ["
			.. savedWindow.bundleID
			.. "]"
			.. " -> "
			.. currentScreen:name()
	)

	window:setFrame(targetFrame)

	return true
end

--- Attempts to restore a live window from M.state.
function M.tryRestoreWindow(window)
	if not window then
		return false
	end

	local app = window:application()

	if not app then
		return false
	end

	local bundleID = app:bundleID()

	if not bundleID then
		return false
	end

	local title = window:title() or ""

	local savedWindow, savedScreen = M.findSavedWindow(bundleID, title)

	if not savedWindow then
		M.logger.d("No saved position for: " .. (title ~= "" and title or "<untitled>") .. " [" .. bundleID .. "]")

		return false
	end

	return M.restoreWindow(window, savedWindow, savedScreen)
end

--- Restores all currently-open windows that uniquely match the saved state.
function M.restoreLayout()
	M.logger.i("Restoring desktop state...")

	-- Reload from disk so manual changes to wm.json are picked up.
	if not M.reloadState() then
		return
	end

	for _, window in ipairs(hs.window.allWindows()) do
		M.tryRestoreWindow(window)
	end
end

-- -------------------------------------------------------------------------
-- Window watcher
-- -------------------------------------------------------------------------

--- Starts a permanent watcher for newly-created windows.
---
--- Newly-created windows are matched against M.state and automatically
--- restored when a unique bundle ID + title match exists.
---
--- The watcher remains active for the lifetime of the module. Because
--- there is no runtime "pending" state, a window can be closed and later
--- reopened and will be restored again.
function M.startWindowWatcher()
	if M.windowWatcher then
		return
	end

	M.logger.i("Starting window watcher...")

	M.windowWatcher = hs.window.filter.new(true)

	M.windowWatcher:subscribe(hs.window.filter.windowCreated, function(window)
		-- Some applications expose their accessibility window before
		-- its title has been populated. Delay matching slightly.
		hs.timer.doAfter(0.5, function()
			if not window then
				return
			end

			local app = window:application()

			if not app then
				return
			end

			local bundleID = app:bundleID()

			if not bundleID then
				return
			end

			local title = window:title() or ""

			M.logger.i("Window created: " .. (title ~= "" and title or "<untitled>") .. " [" .. bundleID .. "]")

			M.tryRestoreWindow(window)
		end)
	end)
end

function M.stopWindowWatcher()
	if not M.windowWatcher then
		return
	end

	M.windowWatcher:unsubscribeAll()
	M.windowWatcher = nil

	M.logger.i("Window watcher stopped")
end

return M
