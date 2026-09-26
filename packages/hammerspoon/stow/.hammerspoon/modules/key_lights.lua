local M = {
	devices = {},
	onChange = nil,
}

local defaultConfig = {
	serviceType = "_elg._tcp.",
	serviceDomain = "local.",
	refreshInterval = 15,
	brightnessStep = 5,
	brightnessMin = 3,
	temperatureStep = 5,
	temperatureMin = 143,
	temperatureMax = 344,
	left = { match = "8B25" },
	right = { match = "07C7" },
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

local function notify()
	if M.onChange then M.onChange(M.status()) end
end

local function endpointFor(service)
	local hostname = service:hostname()
	local port = service:port()
	if not hostname or not port or port < 1 then return nil end
	hostname = hostname:gsub("%.$", "")
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

function M.status()
	return { left = M.devices.left, right = M.devices.right }
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

function M.adjust(role, property, delta)
	local device = M.devices[role]
	if not device or not device.state then return false end
	if property == "brightness" then
		local current = device.state.brightness or M.config.brightnessMin
		return put(device, {
			brightness = stepValue(
				current,
				delta,
				M.config.brightnessStep,
				M.config.brightnessMin,
				100
			),
		})
	end
	if property == "temperature" then
		local current = device.state.temperature or M.config.temperatureMin
		return put(device, {
			temperature = stepValue(
				current,
				delta,
				M.config.temperatureStep,
				M.config.temperatureMin,
				M.config.temperatureMax
			),
		})
	end
	return false
end

function M.setup(config, onChange)
	M.config = merge(defaultConfig, config or {})
	M.onChange = onChange
	for _, role in ipairs({ "left", "right" }) do
		M.devices[role] = {
			role = role,
			config = M.config[role],
			revision = 0,
		}
		configureHost(M.devices[role], M.config[role].host, M.config[role].port)
	end
	discover()
	M.refreshTimer = hs.timer.doEvery(M.config.refreshInterval, M.refresh)
	notify()
end

return M
