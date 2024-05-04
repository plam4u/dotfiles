mash = {"shift", "ctrl", "alt"}
mash2 = {"shift", "ctrl", "alt", "cmd"}

require "apps"
require "grid"

-- hs.loadSpoon("ArrangeDesktop")
-- spoon.bindHotkeysToSpec(def, mapping)

hs.loadSpoon("ReloadConfiguration")
spoon.ReloadConfiguration:start()

hs.alert("Hammerspoon config loaded")
