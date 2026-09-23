local M = {}
function M.setup(config)
	M.config = config or {}
	hs.loadSpoon("ReloadConfiguration")
	spoon.ReloadConfiguration:start()
	hs.alert("Hammerspoon has started!")
end
return M
