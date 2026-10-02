local M = { running = false, activeCount = 0, torrentCount = 0 }

local defaultConfig = {
    baseURL = "http://127.0.0.1:9091",
    brew = "/opt/homebrew/bin/brew",
    refreshInterval = 15,
}

local rows = {
    { id = "open", heading = "Open Web UI", interactive = true },
    { id = "torrents", interactive = true },
    { id = "status", interactive = false },
    { id = "speed", interactive = false },
}

local function speedText(rate)
    if not M.running or rate == nil then return "—" end
    if rate >= 1000 then return string.format("%.1f MB/s", rate / 1000) end
    return string.format("%.1f kB/s", rate)
end

local function rowHeading(row)
    if row.id == "status" then
        if M.error then return M.error end
        return string.format("%d torrents", M.torrentCount)
    end
    if row.id == "speed" then return "↓ " .. speedText(M.downloadSpeed) end
    if row.id == "torrents" then return M.activeCount > 0 and "Pause All" or "Resume All" end
    return row.heading
end

local function rowValue(row)
    if row.id == "speed" then return "↑ " .. speedText(M.uploadSpeed) end
    if row.id == "status" and M.running then return string.format("%d active", M.activeCount) end
    if row.id == "torrents" and M.pending then return "Working…" end
    return ""
end

function M.updateItem()
    if not M.ui or not M.ui.executable then return end
    M.ui.run({ "--set", "transmission", "label=" .. (M.busy and "…" or (M.running and "On" or "Off")) })
    if M.detailsVisible then M.renderDetails() end
end

-- Transmission's CLI handles the RPC session-id handshake and protocol version.
local function remote(arguments, callback)
    local args = { M.config.baseURL .. "/transmission/rpc" }
    for _, value in ipairs(arguments) do table.insert(args, value) end
    local task
    task = hs.task.new("/opt/homebrew/opt/transmission-cli/bin/transmission-remote", function(code, stdout, stderr)
        M.tasks[task] = nil
        callback(code, stdout, stderr)
    end, args)
    if not task then callback(-1, "", "Could not create task"); return end
    M.tasks[task] = true
    if not task:start() then M.tasks[task] = nil; callback(-1, "", "Could not start task") end
end

function M.refresh()
    if M.refreshing then return end
    M.refreshing = true
    remote({ "--list" }, function(code, stdout)
        M.refreshing = false
        M.running = code == 0
        M.error = nil
        M.activeCount, M.torrentCount = 0, 0
        M.uploadSpeed, M.downloadSpeed = nil, nil
        if M.running then
            for line in (stdout or ""):gmatch("[^\r\n]+") do
                if line:match("^Sum:") then
                    local upload, download = line:match("([%d.]+)%s+([%d.]+)%s*$")
                    M.uploadSpeed, M.downloadSpeed = tonumber(upload), tonumber(download)
                end
                if line:match("^%s*%d+[%*%s]") then
                    M.torrentCount = M.torrentCount + 1
                    if not line:match("%sStopped%s") and not line:match("%sFinished%s") then
                        M.activeCount = M.activeCount + 1
                    end
                end
            end
        else
            M.error = "RPC unavailable"
        end
        M.updateItem()
    end)
end

function M.toggleService()
    if M.busy then return end
    M.busy = true
    M.updateItem()
    -- Ask brew for service state: an RPC failure does not imply a stopped service.
    local task
    task = hs.task.new(M.config.brew, function(code, stdout)
        M.tasks[task] = nil
        local ok, services = pcall(hs.json.decode, stdout or "")
        if code ~= 0 or not ok or type(services) ~= "table" or not services[1] then
            M.busy = false
            hs.alert.show("Unable to read Transmission service state")
            M.updateItem()
            return
        end
        local service = services[1]
        local command = (service.running or service.loaded) and "stop" or "run"
        local serviceTask
        serviceTask = hs.task.new(M.config.brew, function(exitCode)
            M.tasks[serviceTask] = nil
            M.busy = false
            if exitCode ~= 0 then hs.alert.show("Transmission service " .. command .. " failed") end
            M.refresh()
            hs.timer.doAfter(2, M.refresh)
        end, { "services", command, "transmission-cli" })
        if not serviceTask then M.busy = false; M.updateItem(); return end
        M.tasks[serviceTask] = true
        if not serviceTask:start() then M.tasks[serviceTask] = nil; M.busy = false; M.updateItem() end
    end, { "services", "info", "transmission-cli", "--json" })
    if not task then M.busy = false; M.updateItem(); return end
    M.tasks[task] = true
    if not task:start() then M.tasks[task] = nil; M.busy = false; M.updateItem() end
end

function M.openWeb()
    hs.urlevent.openURL(M.config.baseURL .. "/transmission/web/")
end

function M.toggleTorrents()
    if M.pending or not M.running then
        if not M.running then hs.alert.show("Start Transmission before controlling torrents") end
        return
    end
    M.pending = true
    -- Refresh immediately before choosing the action, including queued torrents.
    remote({ "--list" }, function(code, stdout)
        if code ~= 0 then M.pending = false; hs.alert.show("Transmission RPC unavailable"); M.refresh(); return end
        local active = false
        for line in (stdout or ""):gmatch("[^\r\n]+") do
            if line:match("^%s*%d+[%*%s]") and not line:match("%sStopped%s") and not line:match("%sFinished%s") then active = true end
        end
        remote({ "--torrent", "all", active and "--stop" or "--start" }, function(exitCode)
            M.pending = false
            if exitCode ~= 0 then hs.alert.show("Unable to change Transmission torrent state") end
            M.refresh()
        end)
    end)
    M.updateItem()
end

function M.clearPopup()
	if M.ui then M.ui.run({ "--set", "transmission", "popup.drawing=off", "--remove", "/^wm.transmission\\./" }) end
end

function M.renderDetails()
	if not M.detailsVisible then return end
	local args = { "--set", "/^wm.transmission\\./", "background.drawing=off" }
	for index, row in ipairs(rows) do
		local name = "wm.transmission." .. tostring(index)
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
		local name = "wm.transmission." .. tostring(index)
		for _, argument in ipairs({
			"--add", "item", name, "popup.transmission",
			"--set", name,
			"icon=" .. rowHeading(row),
			"icon.font=Hack Nerd Font:Bold:13.0",
			"icon.width=156",
			"icon.align=left",
			"icon.padding_left=10",
			"icon.padding_right=4",
			"label=" .. rowValue(row),
			"label.font=Hack Nerd Font:Regular:13.0",
			"label.width=110",
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
	M.ui.run({ "--set", "transmission", "popup.drawing=on" })
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
	local shouldShow = active and selected and selected.id == "transmission" and not menuIndex
	if shouldShow and not M.detailsVisible then
		M.openDetails()
	elseif not shouldShow and M.detailsVisible then
		M.closeDetails()
	end
end

function M.handleVertical(selected, delta)
	if not selected or selected.id ~= "transmission" or not M.detailsVisible then return false end
	M.rowIndex = ((M.rowIndex + delta) % (#rows + 1))
	M.renderDetails()
	return true
end

function M.invokeSelected(selected)
	if not selected or selected.id ~= "transmission" or not M.detailsVisible then return false end
	local shouldClose = false
	if M.rowIndex == 0 then
		M.toggleService()
	else
		local row = rows[M.rowIndex]
		if row.id == "open" then
			M.openWeb()
			shouldClose = true
		elseif row.id == "torrents" then
			M.toggleTorrents()
			shouldClose = true
		end
	end
	return true, shouldClose
end

function M.setup(config, ui)
    M.config = {}
    for key, value in pairs(defaultConfig) do M.config[key] = value end
    for key, value in pairs(config or {}) do M.config[key] = value end
    M.ui = ui
    M.tasks = {}
    M.clearPopup()
    M.refreshTimer = hs.timer.doEvery(M.config.refreshInterval, M.refresh)
    M.popupRefreshTimer = hs.timer.doEvery(2, function()
        if M.detailsVisible then M.refresh() end
    end)
    M.refresh()
end

return M
