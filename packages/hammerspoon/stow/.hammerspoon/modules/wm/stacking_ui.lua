local M = {
	canvases = {},
}

local function liveMemberCount(workspace)
	local count = 0

	for _, member in ipairs(workspace.members) do
		if member.window then
			count = count + 1
		end
	end

	return count
end

local function memberName(member)
	local app = member.window and member.window:application()
	local name = app and app:name()

	return name or member.bundleID
end

local function workspaceName(workspace)
	local names = {}

	for _, member in ipairs(workspace.members) do
		table.insert(names, memberName(member))
	end

	if #names == 0 then
		return "Empty workspace"
	end

	return table.concat(names, "  +  ")
end

function M.clear()
	for _, canvas in pairs(M.canvases) do
		canvas:delete()
	end

	M.canvases = {}
end

function M.render(screens, screenOrder, options, expandedWorkspace)
	M.clear()

	local lineWidth = options.lineWidth or 3
	local lineHeight = options.lineHeight or 24
	local spacing = options.spacing or 5
	local leftInset = options.leftInset or 3
	local topInset = options.topInset or leftInset
	local expandedWidth = options.expandedWidth or 240

	for _, screenName in ipairs(screenOrder) do
		local virtualScreen = screens[screenName]
		local workspaceCount = #virtualScreen.workspaces
		local isExpandedScreen = expandedWorkspace and expandedWorkspace.screenName == screenName
		local focusedWorkspaceIndex = isExpandedScreen and expandedWorkspace.workspaceIndex or nil

		if workspaceCount > 0 then
			local frame = {
				x = virtualScreen.frame.x + leftInset,
				y = virtualScreen.frame.y + topInset,
				w = isExpandedScreen and expandedWidth or lineWidth,
				h = workspaceCount * lineHeight + math.max(0, workspaceCount - 1) * spacing,
			}
			local canvas = hs.canvas.new(frame)

			if isExpandedScreen then
				canvas:appendElements({
					type = "rectangle",
					action = "fill",
					frame = { x = 0, y = 0, w = expandedWidth, h = frame.h },
					fillColor = { red = 0.08, green = 0.09, blue = 0.11, alpha = 1 },
					roundedRectRadii = { xRadius = 4, yRadius = 4 },
				})
			end

			for index, workspace in ipairs(virtualScreen.workspaces) do
				local y = (index - 1) * (lineHeight + spacing)
				local liveCount = liveMemberCount(workspace)
				local isActive = index == virtualScreen.activeWorkspace
				local isExpanded = isExpandedScreen
				local isFocused = index == focusedWorkspaceIndex
				local alpha = liveCount > 0 and 1 or 0.3

				if isFocused then
					canvas:appendElements({
						type = "rectangle",
						action = "stroke",
						frame = { x = 1, y = y + 1, w = expandedWidth - 2, h = lineHeight - 2 },
						strokeColor = { red = 0.3, green = 0.75, blue = 1, alpha = 1 },
						strokeWidth = 2,
						roundedRectRadii = { xRadius = 4, yRadius = 4 },
					})
				end

				canvas:appendElements({
					type = "rectangle",
					action = "fill",
					frame = { x = 0, y = y, w = lineWidth, h = lineHeight },
					fillColor = isActive and { red = 0.3, green = 0.75, blue = 1, alpha = alpha }
						or { white = 0.65, alpha = alpha },
					roundedRectRadii = { xRadius = lineWidth / 2, yRadius = lineWidth / 2 },
				})

				if isExpanded then
					canvas:appendElements({
						type = "text",
						text = workspaceName(workspace),
						frame = { x = lineWidth + 9, y = y + 2, w = expandedWidth - lineWidth - 15, h = lineHeight - 4 },
						textAlignment = "left",
						textColor = { white = 0.96, alpha = 1 },
						textSize = options.textSize or 13,
					})
				end
			end

			canvas:clickActivating(false)
			canvas:show()
			M.canvases[screenName] = canvas
		end
	end
end

return M
