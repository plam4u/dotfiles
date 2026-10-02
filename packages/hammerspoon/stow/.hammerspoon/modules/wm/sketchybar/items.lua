local caffeine = require("modules.caffeine")
local inputSource = require("modules.keyboard.input_source")
local keyLights = require("modules.wm.sketchybar.key_lights")
local plex = require("modules.wm.sketchybar.plex")
local transmission = require("modules.wm.sketchybar.transmission")

local M = {}

local definitions = {
	{
		id = "front_app",
		actions = {
			{
				id = "hide",
				label = "Hide front application",
				handler = function()
					local app = hs.application.frontmostApplication()
					if app then app:hide() end
				end,
			},
		},
	},
	{
		id = "input_source",
		defaultOrder = 1,
		setup = function(_, ui) inputSource.subscribe(ui.updateInputSource) end,
		refresh = function(_, ui) ui.updateInputSource(inputSource.currentState()) end,
		onSpace = function() inputSource.cycle(1) end,
		onVertical = function(delta) inputSource.cycle(delta) end,
		actions = {
			{
				id = "cycle",
				label = "Change input language",
				handler = inputSource.cycle,
			},
		},
	},
	{
		id = "clock",
		defaultOrder = 8,
		actions = {
			{
				id = "calendar",
				label = "Open Calendar",
				handler = function() hs.application.launchOrFocus("Calendar") end,
			},
		},
	},
	{
		id = "volume",
		defaultOrder = 7,
		actions = {
			{
				id = "mute",
				label = "Toggle mute",
				handler = function()
					local device = hs.audiodevice.defaultOutputDevice()
					if device then device:setMuted(not device:muted()) end
				end,
			},
			{
				id = "up",
				label = "Volume up",
				handler = function()
					local device = hs.audiodevice.defaultOutputDevice()
					if device then device:setVolume(math.min(100, device:volume() + 5)) end
				end,
			},
			{
				id = "down",
				label = "Volume down",
				handler = function()
					local device = hs.audiodevice.defaultOutputDevice()
					if device then device:setVolume(math.max(0, device:volume() - 5)) end
				end,
			},
		},
	},
	{
		id = "battery",
		defaultOrder = 6,
		actions = {
			{
				id = "settings",
				label = "Open System Settings",
				handler = function() hs.application.launchOrFocus("System Settings") end,
			},
		},
	},
	{
		id = "codex",
		defaultOrder = 2,
		actions = {},
	},
	{
		id = "key_lights",
		defaultOrder = 3,
		setup = function(config, ui) keyLights.setup(config.keyLights or {}, ui) end,
		actions = {
			{
				id = "toggle",
				label = "Toggle all key lights",
				handler = function() keyLights.togglePower("all") end,
			},
		},
	},
	{
		id = "caffeine",
		defaultOrder = 4,
		setup = function(_, ui) caffeine.subscribe(ui.updateCaffeine) end,
		actions = {
			{
				id = "toggle",
				label = "Toggle Caffeine",
				handler = function() caffeine.caffeineClicked({}) end,
			},
		},
	},
	{
		id = "plex",
		defaultOrder = 5,
		setup = function(config, ui) plex.setup(config.plex or {}, ui) end,
		actions = {
			{
				id = "toggle",
				label = "Toggle Plex Media Server",
				handler = plex.toggleServer,
			},
		},
	},
    {
        id = "transmission",
        defaultOrder = 5.5,
        setup = function(config, ui) transmission.setup(config.transmission or {}, ui) end,
        actions = {
            { id = "toggle", label = "Toggle Transmission service", handler = transmission.toggleService },
        },
    },
}

function M.all()
	return definitions
end

function M.find(itemID)
	for _, item in ipairs(definitions) do
		if item.id == itemID then return item end
	end
	return nil
end

function M.defaultRightOrder()
	local rightItems = {}
	for _, item in ipairs(definitions) do
		if item.defaultOrder then table.insert(rightItems, item) end
	end
	table.sort(rightItems, function(left, right)
		return left.defaultOrder < right.defaultOrder
	end)

	local order = {}
	for _, item in ipairs(rightItems) do table.insert(order, item.id) end
	return order
end

function M.setupEnabled(order, config, ui)
	for _, itemID in ipairs(order) do
		local item = M.find(itemID)
		if item and item.setup then item.setup(config, ui) end
	end
end

function M.refreshEnabled(order, config, ui)
	for _, itemID in ipairs(order) do
		local item = M.find(itemID)
		if item and item.refresh then item.refresh(config, ui) end
	end
end

function M.handleSpace(itemID)
	local item = M.find(itemID)
	if not item or not item.onSpace then return false end
	item.onSpace()
	return true
end

function M.handleVertical(itemID, delta)
	local item = M.find(itemID)
	if not item or not item.onVertical then return false end
	item.onVertical(delta)
	return true
end

return M
