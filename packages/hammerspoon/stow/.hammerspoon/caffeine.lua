local M = {}
local caffeine = hs.menubar.new()
local home = os.getenv("HOME")
local icons = {
	sleepy = hs.image.imageFromPath(home .. "/.hammerspoon/resources/coffee.empty.16.png"),
	awake = hs.image.imageFromPath(home .. "/.hammerspoon/resources/coffee.fill.16.png"),
}
local shouldDisplayTitle = hs.settings.get("caffeine.shouldDisplayTitle") or false

local function setCaffeineDisplay(state)
	if state then
		caffeine:setIcon(icons.awake)
		caffeine:setTitle(shouldDisplayTitle and "Awake" or nil)
	else
		caffeine:setIcon(icons.sleepy)
		caffeine:setTitle(shouldDisplayTitle and "Sleepy" or nil)
	end
end

local function caffeineClicked(mods)
	if mods.alt then
		shouldDisplayTitle = not shouldDisplayTitle
		hs.settings.set("caffeine.shouldDisplayTitle", shouldDisplayTitle)
		setCaffeineDisplay(hs.caffeinate.get("displayIdle"))
	else
		local state = hs.caffeinate.toggle("displayIdle")
		hs.settings.set("caffeine.state", state)
		setCaffeineDisplay(state)
	end
end

if caffeine then
	local savedState = hs.settings.get("caffeine.state")
	if savedState ~= nil then
		hs.caffeinate.set("displayIdle", savedState)
	end
	caffeine:setClickCallback(caffeineClicked)
	setCaffeineDisplay(hs.caffeinate.get("displayIdle"))

	if M.hotkey then
		M.hotkey:delete()
	end
	M.hotkey = hs.hotkey.new(mash, "y", function()
		caffeineClicked({})
		hs.alert.show("Caffeine: " .. (hs.caffeinate.get("displayIdle") and "Awake" or "Sleepy"))
	end)
	M.hotkey:enable()
end
M.caffeine = caffeine
return M
