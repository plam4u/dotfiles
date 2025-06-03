mash = { "shift", "ctrl", "alt" }
mash2 = { "shift", "ctrl", "alt", "cmd" }

require("apps")
require("grid")
require("caffeine")

hs.loadSpoon("ReloadConfiguration")
spoon.ReloadConfiguration:start()

hs.alert("Hammerspoon config loaded")
