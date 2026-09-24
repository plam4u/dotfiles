local M = {}

M.modulePrefix = "modules.wm"

function M.setup(config)
	config = config or {}

	-- Setup order matters: stacking owns the model, SketchyBar observes it,
	-- and control binds the persistent pause toggle last.
	local setupOrder = { "apps", "layout", "navigation", "stacking", "borders", "sketchybar", "control" }
	local configured = {}

	for _, moduleName in ipairs(setupOrder) do
		if config[moduleName] then
			M.setupModule(moduleName, config[moduleName])
			configured[moduleName] = true
		end
	end

	for moduleName, moduleConfig in pairs(config) do
		if not configured[moduleName] then
			M.setupModule(moduleName, moduleConfig)
		end
	end
end

function M.setupModule(moduleName, config)
	local modulePath = M.modulePrefix .. "." .. moduleName
	local module = require(modulePath)

	if type(module.setup) ~= "function" then
		error(string.format("WM module '%s' does not provide setup()", modulePath), 2)
	end

	module.setup(config or {})
end

return M
