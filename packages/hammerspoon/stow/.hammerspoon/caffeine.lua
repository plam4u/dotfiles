local caffeine = hs.menubar.new()
local home = os.getenv("HOME")
local icons = {
	sleepy = hs.image.imageFromPath(home .. "/.hammerspoon/resources/coffee.empty.16.png"),
	awake = hs.image.imageFromPath(home .. "/.hammerspoon/resources/coffee.fill.16.png"),
}
local shouldDisplayTitle = false

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
		setCaffeineDisplay(hs.caffeinate.get("displayIdle"))
	else
		setCaffeineDisplay(hs.caffeinate.toggle("displayIdle"))
	end
end

if caffeine then
	caffeine:setClickCallback(caffeineClicked)
	setCaffeineDisplay(hs.caffeinate.get("displayIdle"))
end
