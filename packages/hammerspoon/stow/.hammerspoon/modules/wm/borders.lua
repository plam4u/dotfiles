local M = {
	task = nil,
}

local function findExecutable(configured)
	local paths = { "/opt/homebrew/bin/borders", "/usr/local/bin/borders" }
	if configured then table.insert(paths, 1, configured) end

	for _, path in ipairs(paths) do
		if hs.fs.attributes(path, "mode") == "file" then return path end
	end
	return nil
end

local function isRunning()
	local _, success = hs.execute("/usr/bin/pgrep -x borders >/dev/null 2>&1")
	return success == true
end

function M.ensureRunning()
	if isRunning() then return true end
	if M.task and M.task:isRunning() then return true end
	if not M.executable then
		M.logger.w("JankyBorders executable was not found")
		return false
	end

	local arguments = { "LANG=en_US.UTF-8", M.executable }
	for _, argument in ipairs(M.config.arguments or {}) do
		table.insert(arguments, tostring(argument))
	end

	M.task = hs.task.new("/usr/bin/env", function(exitCode, _, standardError)
		if exitCode ~= 0 then
			M.logger.e("JankyBorders exited: " .. tostring(standardError))
		end
		M.task = nil
	end, arguments)

	if not M.task or not M.task:start() then
		M.logger.e("Unable to start JankyBorders")
		M.task = nil
		return false
	end

	M.logger.i("JankyBorders started")
	return true
end

function M.setup(config)
	M.config = config or {}
	M.logger = hs.logger.new("wm-borders", "info")
	M.executable = findExecutable(M.config.executable)
	M.ensureRunning()
end

return M
