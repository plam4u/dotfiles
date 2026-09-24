local M = {}

local function trimTrailingSlash(path)
	return path:gsub("/+$", "")
end

local function relativePath(path, root)
	root = trimTrailingSlash(root)

	if path == root then
		return ""
	end

	local prefix = root .. "/"

	if path:sub(1, #prefix) == prefix then
		return path:sub(#prefix + 1)
	end

	return path
end

local function hasIncludedSuffix(path, suffixes)
	if #suffixes == 0 then
		return true
	end

	for _, suffix in ipairs(suffixes) do
		if path:sub(-#suffix) == suffix then
			return true
		end
	end

	return false
end

local function isExcluded(path, excludedPaths)
	for _, excludedPath in ipairs(excludedPaths) do
		local excluded = excludedPath:gsub("^/+", "")
		local prefix = excluded

		if prefix:sub(-1) ~= "/" then
			prefix = prefix .. "/"
		end

		local exactPath = prefix:sub(1, -2)
		local nestedPrefix = "/" .. prefix
		local exactSuffix = "/" .. excluded:gsub("/+$", "")

		if path == exactPath
			or path:sub(1, #prefix) == prefix
			or path:find(nestedPrefix, 1, true)
			or path:sub(-#exactSuffix) == exactSuffix
		then
			return true
		end
	end

	return false
end

function M.shouldReload(paths, root)
	for _, path in ipairs(paths) do
		local relative = relativePath(path, root)

		if not isExcluded(relative, M.excludePaths) and hasIncludedSuffix(relative, M.includeSuffixes) then
			return true
		end
	end

	return false
end

function M.stop()
	for _, watcher in ipairs(M.watchers or {}) do
		watcher:stop()
	end

	M.watchers = {}
end

function M.setup(config)
	M.config = config or {}
	M.watchPaths = M.config.watchPaths or { hs.configdir }
	M.includeSuffixes = M.config.includeSuffixes or { ".lua", ".json" }
	M.excludePaths = M.config.excludePaths or { "state/" }
	M.stop()

	for _, root in ipairs(M.watchPaths) do
		local watchedRoot = root
		local watcher = hs.pathwatcher.new(watchedRoot, function(paths)
			if M.shouldReload(paths, watchedRoot) then
				hs.reload()
			end
		end)

		table.insert(M.watchers, watcher:start())
	end

	hs.alert.show("Hammerspoon has started!")
end

return M
