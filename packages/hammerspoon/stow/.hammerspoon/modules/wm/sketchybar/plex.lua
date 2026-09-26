local M = {
	running = false,
	streamCount = 0,
	updatingLibraries = false,
}

local defaultConfig = {
	bundleID = "com.plexapp.plexmediaserver",
	baseURL = "http://127.0.0.1:32400",
	webURL = "http://127.0.0.1:32400/web",
	refreshInterval = 15,
	tokenPlist = os.getenv("HOME") .. "/Library/Preferences/com.plexapp.plexmediaserver.plist",
}

local rows = {
	{ id = "streams", interactive = false },
	{ id = "open", heading = "Open Plex", interactive = true },
	{ id = "refresh", heading = "Update Libraries", interactive = true },
}

local function merge(base, override)
	local result = {}
	for key, value in pairs(base or {}) do result[key] = value end
	for key, value in pairs(override or {}) do result[key] = value end
	return result
end

local function token()
	local preferences = hs.plist.read(M.config.tokenPlist)
	local value = type(preferences) == "table" and preferences.PlexOnlineToken or nil
	if type(value) ~= "string" or value == "" then return nil end
	return value
end

local function headers()
	local plexToken = token()
	if not plexToken then return nil end
	return {
		["Accept"] = "application/xml",
		["X-Plex-Token"] = plexToken,
	}
end

local function serverApplication()
	return hs.application.get(M.config.bundleID)
end

local function streamText()
	if M.streamCount == 0 then return "No streams" end
	if M.streamCount == 1 then return "1 stream" end
	return string.format("%d streams", M.streamCount)
end

local function rowHeading(row)
	if row.id == "streams" then return streamText() end
	return row.heading
end

local function rowValue(row)
	if row.id == "refresh" and M.updatingLibraries then return "Updating…" end
	return ""
end

function M.updateItem()
	if not M.ui or not M.ui.executable then return end
	M.ui.run({ "--set", "plex", "label=" .. (M.running and "On" or "Off") })
	if M.detailsVisible then M.renderDetails() end
end

local function applySessionsResponse(status, body)
	if tonumber(status) and tonumber(status) >= 200 and tonumber(status) < 300 then
		M.streamCount = tonumber((body or ""):match('<MediaContainer[^>]-size="(%d+)"')) or 0
	end
	M.updateItem()
end

local function applyIdentityResponse(status)
	local code = tonumber(status) or 0
	M.running = code >= 200 and code < 300
	if not M.running then
		M.streamCount = 0
		M.updatingLibraries = false
		M.updateItem()
		return
	end

	local requestHeaders = headers()
	if not requestHeaders then
		M.updateItem()
		return
	end
	hs.http.asyncGet(M.config.baseURL .. "/status/sessions", requestHeaders, applySessionsResponse)
	M.updateItem()
end

function M.refresh()
	hs.http.asyncGet(M.config.baseURL .. "/identity", headers() or {}, applyIdentityResponse)
end

function M.toggleServer()
	local application = serverApplication()
	if application then
		if M.running then
			application:kill()
		else
			application:kill()
			hs.timer.doAfter(0.5, function() hs.application.launchOrFocusByBundleID(M.config.bundleID) end)
		end
	else
		hs.application.launchOrFocusByBundleID(M.config.bundleID)
	end
	M.running = not M.running
	if not M.running then M.streamCount = 0 end
	M.updateItem()
	hs.timer.doAfter(1, M.refresh)
end

function M.openPlex()
	hs.urlevent.openURL(M.config.webURL)
end

local function finishLibraryRequest()
	M.pendingLibraryRequests = math.max(0, (M.pendingLibraryRequests or 1) - 1)
	if M.pendingLibraryRequests == 0 then
		M.updatingLibraries = false
		M.updateItem()
	end
end

local function refreshSections(status, body)
	if not tonumber(status) or tonumber(status) < 200 or tonumber(status) >= 300 then
		M.updatingLibraries = false
		M.updateItem()
		return
	end

	local sectionKeys = {}
	for key in (body or ""):gmatch('<Directory[^>]-key="(%d+)"') do
		sectionKeys[#sectionKeys + 1] = key
	end
	if #sectionKeys == 0 then
		M.updatingLibraries = false
		M.updateItem()
		return
	end

	M.pendingLibraryRequests = #sectionKeys
	local requestHeaders = headers()
	for _, key in ipairs(sectionKeys) do
		hs.http.asyncGet(
			M.config.baseURL .. "/library/sections/" .. key .. "/refresh",
			requestHeaders,
			finishLibraryRequest
		)
	end
end

function M.updateLibraries()
	if not M.running or M.updatingLibraries then return false end
	local requestHeaders = headers()
	if not requestHeaders then return false end
	M.updatingLibraries = true
	M.updateItem()
	hs.http.asyncGet(M.config.baseURL .. "/library/sections", requestHeaders, refreshSections)
	return true
end

function M.clearPopup()
	if M.ui then M.ui.run({ "--set", "plex", "popup.drawing=off", "--remove", "/^wm.plex\\./" }) end
end

function M.renderDetails()
	if not M.detailsVisible then return end
	local args = { "--set", "/^wm.plex\\./", "background.drawing=off" }
	for index, row in ipairs(rows) do
		local name = "wm.plex." .. tostring(index)
		table.insert(args, "--set")
		table.insert(args, name)
		table.insert(args, "icon=" .. rowHeading(row))
		table.insert(args, "label=" .. rowValue(row))
		if index == M.rowIndex then table.insert(args, "background.drawing=on") end
	end
	M.ui.run(args)
end

function M.openDetails()
	M.ui.closeMenu()
	M.ui.closeCodexUsageDetails()
	M.clearPopup()
	M.rowIndex = 0
	local args = {}
	for index, row in ipairs(rows) do
		local name = "wm.plex." .. tostring(index)
		for _, argument in ipairs({
			"--add", "item", name, "popup.plex",
			"--set", name,
			"icon=" .. rowHeading(row),
			"icon.font=Hack Nerd Font:Bold:13.0",
			"icon.width=156",
			"icon.align=left",
			"icon.padding_left=10",
			"icon.padding_right=4",
			"label=" .. rowValue(row),
			"label.font=Hack Nerd Font:Regular:13.0",
			"label.width=82",
			"label.align=right",
			"label.padding_left=4",
			"label.padding_right=10",
			"background.color=0xff3b82f6",
			"background.corner_radius=6",
			"background.height=26",
			"background.drawing=off",
		}) do table.insert(args, argument) end
	end
	M.ui.run(args)
	M.ui.run({ "--set", "plex", "popup.drawing=on" })
	M.detailsVisible = true
	M.refresh()
end

function M.closeDetails()
	if not M.detailsVisible then return end
	M.clearPopup()
	M.detailsVisible = false
	M.rowIndex = nil
end

function M.syncDetails(active, selected, menuIndex)
	local shouldShow = active and selected and selected.id == "plex" and not menuIndex
	if shouldShow and not M.detailsVisible then
		M.openDetails()
	elseif not shouldShow and M.detailsVisible then
		M.closeDetails()
	end
end

function M.handleVertical(selected, delta)
	if not selected or selected.id ~= "plex" or not M.detailsVisible then return false end
	M.rowIndex = ((M.rowIndex + delta) % (#rows + 1))
	M.renderDetails()
	return true
end

function M.invokeSelected(selected)
	if not selected or selected.id ~= "plex" or not M.detailsVisible then return false end
	if M.rowIndex == 0 then
		M.toggleServer()
	else
		local row = rows[M.rowIndex]
		if row.id == "open" then
			M.openPlex()
		elseif row.id == "refresh" then
			M.updateLibraries()
		end
	end
	return true
end

function M.setup(config, ui)
	M.config = merge(defaultConfig, config or {})
	M.ui = ui
	M.clearPopup()
	M.applicationWatcher = hs.application.watcher.new(function(_, event, application)
		if application and application:bundleID() == M.config.bundleID then
			if event == hs.application.watcher.launched or event == hs.application.watcher.terminated then
				hs.timer.doAfter(0.5, M.refresh)
			end
		end
	end):start()
	M.refreshTimer = hs.timer.doEvery(M.config.refreshInterval, M.refresh)
	M.refresh()
end

return M
