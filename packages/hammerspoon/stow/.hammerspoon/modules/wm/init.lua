local M = {}

M.modulePrefix = "modules.wm"

function M.setup(config)
	config = config or {}

	for moduleName, moduleConfig in pairs(config) do
		M.setupModule(moduleName, moduleConfig)
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
