local M = {
	devices = {},
	cycles = {},
}

local defaultConfig = {
	serviceType = "_elg._tcp.",
	serviceDomain = "local.",
	refreshInterval = 15,
	brightnessStep = 5,
	brightnessMin = 1,
	temperatureStep = 50,
	temperatureMin = 143,
	temperatureMax = 344,
	left = { match = "8B25" },
	right = { match = "07C7" },
}

local rows = {
	{ heading = "All lights", role = "all", property = "power" },
	{ heading = "Left power", role = "left", property = "power" },
	{ heading = "Left temperature", role = "left", property = "temperature" },
	{ heading = "Left brightness", role = "left", property = "brightness" },
	{ heading = "Right power", role = "right", property = "power" },
	{ heading = "Right temperature", role = "right", property = "temperature" },
	{ heading = "Right brightness", role = "right", property = "brightness" },
}

local function merge(base, override)
	local result = {}
	for key, value in pairs(base or {}) do
		result[key] = type(value) == "table" and merge(value, {}) or value
	end
	for key, value in pairs(override or {}) do
		if type(value) == "table" and type(result[key]) == "table" then
			result[key] = merge(result[key], value)
		else
			result[key] = value
		end
	end
	return result
end

local function clamp(value, minimum, maximum)
	return math.max(minimum, math.min(maximum, value))
end

local function stepValue(value, delta, step, minimum, maximum)
	local stepped
	if delta < 0 then
		stepped = math.ceil(value / step) * step - step
	else
		stepped = math.floor(value / step) * step + step
	end
	return clamp(stepped, minimum, maximum)
end

local function roundToStep(value, step)
	return math.floor(value / step + 0.5) * step
end

local function temperatureToKelvin(temperature)
	return roundToStep(1000000 / temperature, M.config.temperatureStep)
end

local function kelvinToTemperature(kelvin)
	return clamp(
		math.floor(1000000 / kelvin + 0.5),
		M.config.temperatureMin,
		M.config.temperatureMax
	)
end

local function notify()
	M.updateItem()
end

local function endpointFor(service)
	local addresses = service:addresses() or {}
	local hostname
	for _, address in ipairs(addresses) do
		if not address:find(":", 1, true) then
			hostname = address
			break
		end
	end
	hostname = hostname or addresses[1] or service:hostname()
	local port = service:port()
	if not hostname or not port or port < 1 then return nil end
	hostname = hostname:gsub("%.$", "")
	if hostname:find(":", 1, true) then hostname = "[" .. hostname .. "]" end
	return string.format("http://%s:%d", hostname, port)
end

local function decodeLight(body)
	local ok, response = pcall(hs.json.decode, body or "")
	if not ok or type(response) ~= "table" then return nil end
	local light = type(response.lights) == "table" and response.lights[1]
	if type(light) ~= "table" then return nil end
	return {
		on = tonumber(light.on) == 1,
		brightness = tonumber(light.brightness),
		temperature = tonumber(light.temperature),
	}
end

local function applyResponse(device, revision, status, body)
	if revision and revision ~= device.revision then return end
	status = tonumber(status) or 0
	if status < 200 or status >= 300 then
		device.reachable = false
		notify()
		return
	end
	local state = decodeLight(body)
	if state then device.state = state end
	device.reachable = true
	notify()
end

local function requestState(device)
	if not device.endpoint or device.requesting then return end
	device.requesting = true
	local revision = device.revision
	hs.http.asyncGet(device.endpoint .. "/elgato/lights", {}, function(status, body)
		device.requesting = false
		applyResponse(device, revision, status, body)
	end)
end

local function configureHost(device, host, port)
	if not host or host == "" then return end
	device.endpoint = string.format("http://%s:%d", host:gsub("%.$", ""), port or 9123)
	device.reachable = nil
	requestState(device)
end

local function matches(device, serviceName)
	local wanted = device.config.match
	if not wanted or wanted == "" then return false end
	return serviceName:lower():find(tostring(wanted):lower(), 1, true) ~= nil
end

local function resolve(device, service)
	device.service = service
	device.name = service:name()
	service:resolve(5, function(resolved, result)
		if device.service ~= service then return end
		if result == "resolved" then
			device.endpoint = endpointFor(resolved)
			device.reachable = nil
			resolved:stop()
			requestState(device)
		elseif result == "error" or result == "stop" then
			device.reachable = false
			notify()
		end
	end)
end

local function discover()
	M.browser = hs.bonjour.new():findServices(M.config.serviceType, M.config.serviceDomain, function(_, kind, added, service)
		if kind ~= "domain" or not service then return end
		local serviceName = service:name() or ""
		for _, role in ipairs({ "left", "right" }) do
			local device = M.devices[role]
			if matches(device, serviceName) then
				if added then
					resolve(device, service)
				elseif device.name == serviceName then
					device.service = nil
					device.endpoint = nil
					device.reachable = false
					notify()
				end
			end
		end
	end)
end

local function put(device, values)
	if not device or not device.endpoint then return false end
	device.revision = device.revision + 1
	local revision = device.revision
	device.state = device.state or {}
	for key, value in pairs(values) do device.state[key] = value end
	device.reachable = true
	notify()

	local payload = { numberOfLights = 1, lights = { {} } }
	for key, value in pairs(values) do
		payload.lights[1][key] = key == "on" and (value and 1 or 0) or value
	end
	hs.http.asyncPut(
		device.endpoint .. "/elgato/lights",
		hs.json.encode(payload),
		{ ["Content-Type"] = "application/json" },
		function(status, body) applyResponse(device, revision, status, body) end
	)
	return true
end

local function powerValue(role)
	local roles = role == "all" and { "left", "right" } or { role }
	local onCount, offCount, knownCount = 0, 0, 0
	for _, deviceRole in ipairs(roles) do
		local device = M.devices[deviceRole]
		local state = device and device.reachable ~= false and device.state
		if state then
			knownCount = knownCount + 1
			if state.on then onCount = onCount + 1 else offCount = offCount + 1 end
		end
	end
	if knownCount == 0 then return "Unavailable" end
	if knownCount < #roles then return "Partial" end
	if onCount > 0 and offCount > 0 then return "Mixed" end
	if onCount > 0 then return "On" end
	if offCount > 0 then return "Off" end
	return "Unavailable"
end

local function rowValue(row)
	if row.property == "power" then return powerValue(row.role) end
	local device = M.devices[row.role]
	local state = device and device.reachable ~= false and device.state
	if not state then return "Unavailable" end
	if row.property == "brightness" then
		return state.brightness and string.format("%d%%", state.brightness) or "—"
	end
	if state.temperature then return string.format("%dK", temperatureToKelvin(state.temperature)) end
	return "—"
end

local function cycleKey(row)
	return row.role .. "." .. row.property
end

local function resetCycle(row)
	if row and row.property ~= "power" then M.cycles[cycleKey(row)] = nil end
end

local function propertyBounds(property)
	if property == "brightness" then return M.config.brightnessMin, 100 end
	return M.config.temperatureMax, M.config.temperatureMin
end

local function cycleValue(row)
	local device = M.devices[row.role]
	if not device or not device.state then return false end
	local current = device.state[row.property]
	if not current then return false end
	local key = cycleKey(row)
	local cycle = M.cycles[key]
	if not cycle or cycle.applied ~= current then
		cycle = { original = current, index = 0 }
		M.cycles[key] = cycle
	end
	cycle.index = cycle.index % 3 + 1
	local minimum, maximum = propertyBounds(row.property)
	local values = { maximum, minimum, cycle.original }
	local target = values[cycle.index]
	cycle.applied = target
	return put(device, { [row.property] = target })
end

function M.refresh()
	requestState(M.devices.left)
	requestState(M.devices.right)
end

function M.setPower(role, enabled)
	if role == "all" then
		local changed = false
		for _, deviceRole in ipairs({ "left", "right" }) do
			changed = put(M.devices[deviceRole], { on = enabled }) or changed
		end
		return changed
	end
	return put(M.devices[role], { on = enabled })
end

function M.togglePower(role)
	if role == "all" then
		local allOn = true
		local found = false
		for _, deviceRole in ipairs({ "left", "right" }) do
			local device = M.devices[deviceRole]
			local state = device.reachable ~= false and device.state
			if state then
				found = true
				allOn = allOn and state.on == true
			end
		end
		if not found then return M.setPower("all", true) end
		return M.setPower("all", not allOn)
	end
	local device = M.devices[role]
	local enabled = not (device and device.state and device.state.on == true)
	return M.setPower(role, enabled)
end

function M.adjust(row, delta)
	local device = row and M.devices[row.role]
	if not device or not device.state or row.property == "power" then return false end
	resetCycle(row)
	if row.property == "brightness" then
		local current = device.state.brightness or M.config.brightnessMin
		return put(device, {
			brightness = stepValue(current, delta, M.config.brightnessStep, M.config.brightnessMin, 100),
		})
	end
	local currentKelvin = temperatureToKelvin(device.state.temperature or M.config.temperatureMax)
	local minimumKelvin = temperatureToKelvin(M.config.temperatureMax)
	local maximumKelvin = temperatureToKelvin(M.config.temperatureMin)
	local targetKelvin = stepValue(
		currentKelvin,
		-delta,
		M.config.temperatureStep,
		minimumKelvin,
		maximumKelvin
	)
	return put(device, { temperature = kelvinToTemperature(targetKelvin) })
end

function M.clearPopup()
	if M.ui then M.ui.run({ "--set", "key_lights", "popup.drawing=off", "--remove", "/^wm.key_lights\\./" }) end
end

function M.updateItem()
	if not M.ui or not M.ui.executable or not M.devices.left or not M.devices.right then return end
	local status = powerValue("all")
	M.ui.run({ "--set", "key_lights", "label=" .. (status == "Unavailable" and "…" or status) })
	if M.detailsVisible then M.renderDetails() end
end

function M.renderDetails()
	if not M.detailsVisible then return end
	local args = { "--set", "/^wm.key_lights\\./", "background.drawing=off" }
	for index, row in ipairs(rows) do
		local name = "wm.key_lights." .. tostring(index)
		table.insert(args, "--set")
		table.insert(args, name)
		table.insert(args, "label=" .. rowValue(row))
		if index == M.rowIndex then table.insert(args, "background.drawing=on") end
	end
	M.ui.run(args)
end

function M.openDetails()
	M.ui.closeMenu()
	M.ui.closeCodexUsageDetails()
	M.clearPopup()
	M.rowIndex = M.rowIndex or 1
	local args = {}
	for index, row in ipairs(rows) do
		local name = "wm.key_lights." .. tostring(index)
		for _, argument in ipairs({
			"--add", "item", name, "popup.key_lights",
			"--set", name,
			"icon=" .. row.heading,
			"icon.font=Hack Nerd Font:Bold:13.0",
			"icon.width=132",
			"icon.align=left",
			"icon.padding_left=10",
			"icon.padding_right=4",
			"label=" .. rowValue(row),
			"label.font=Hack Nerd Font:Regular:13.0",
			"label.width=92",
			"label.align=right",
			"label.padding_left=4",
			"label.padding_right=10",
			"background.color=0xff3b82f6",
			"background.corner_radius=6",
			"background.height=26",
			"background.drawing=" .. (index == M.rowIndex and "on" or "off"),
		}) do table.insert(args, argument) end
	end
	M.ui.run(args)
	M.ui.run({ "--set", "key_lights", "popup.drawing=on" })
	M.detailsVisible = true
	M.refresh()
end

function M.closeDetails()
	if not M.detailsVisible then return end
	M.clearPopup()
	M.detailsVisible = false
	M.rowIndex = nil
	M.repeatDirection = nil
end

function M.syncDetails(active, selected, menuIndex)
	local shouldShow = active and selected and selected.id == "key_lights" and not menuIndex
	if shouldShow and not M.detailsVisible then
		M.openDetails()
	elseif not shouldShow and M.detailsVisible then
		M.closeDetails()
	end
end

function M.handleVertical(selected, delta)
	if not selected or selected.id ~= "key_lights" or not M.detailsVisible then return false end
	M.rowIndex = ((M.rowIndex - 1 + delta) % #rows) + 1
	M.repeatDirection = nil
	M.renderDetails()
	return true
end

function M.handleHorizontal(selected, delta)
	if not selected or selected.id ~= "key_lights" or not M.detailsVisible then return false end
	local row = rows[M.rowIndex or 1]
	if not row or row.property == "power" then return false end
	M.adjust(row, delta)
	M.repeatDirection = delta
	return true
end

function M.repeatAdjustment(delta)
	if M.repeatDirection == delta then M.adjust(rows[M.rowIndex or 1], delta) end
end

function M.stopRepeat()
	M.repeatDirection = nil
end

function M.invokeSelected(selected)
	if not selected or selected.id ~= "key_lights" or not M.detailsVisible then return false end
	local row = rows[M.rowIndex or 1]
	if row.property == "power" then M.togglePower(row.role) else cycleValue(row) end
	return true
end

function M.setup(config, ui)
	M.config = merge(defaultConfig, config or {})
	M.ui = ui
	M.cycles = {}
	for _, role in ipairs({ "left", "right" }) do
		M.devices[role] = { role = role, config = M.config[role], revision = 0 }
		configureHost(M.devices[role], M.config[role].host, M.config[role].port)
	end
	discover()
	M.refreshTimer = hs.timer.doEvery(M.config.refreshInterval, M.refresh)
	M.clearPopup()
	notify()
end

return M
