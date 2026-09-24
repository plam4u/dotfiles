local M = {}

function M.exists(path)
	local attributes = hs.fs.attributes(path)

	return attributes and attributes.mode == "file" or false
end

function M.load(path)
	local attributes = hs.fs.attributes(path)

	if not attributes or attributes.mode ~= "file" then
		return nil
	end

	return hs.json.read(path)
end

function M.save(path, state)
	local directory = path:match("^(.*)/[^/]+$")

	if directory then
		hs.fs.mkdir(directory)
	end

	return hs.json.write(state, path, true, true)
end

return M
