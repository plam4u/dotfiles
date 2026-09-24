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

local function visibleWorkspaces(group)
	local result = {}
	for index, workspace in ipairs(group.workspaces or {}) do
		if liveMemberCount(workspace) > 0 then
			table.insert(result, { index = index, workspace = workspace })
		end
	end
	return result
end

local function appendWorkspace(canvas, group, entry, y, options, expandedWorkspace, expandedWidth)
	local lineWidth = options.lineWidth or 3
	local lineHeight = options.lineHeight or 24
	local isActive = entry.index == group.activeWorkspace
	local isFocused = expandedWorkspace
		and expandedWorkspace.screenName == group.id
		and expandedWorkspace.workspaceIndex == entry.index

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
		fillColor = isActive and { red = 0.3, green = 0.75, blue = 1, alpha = 1 }
			or { white = 0.65, alpha = 1 },
		roundedRectRadii = { xRadius = lineWidth / 2, yRadius = lineWidth / 2 },
	})

	if expandedWorkspace then
		canvas:appendElements({
			type = "text",
			text = workspaceName(entry.workspace),
			frame = { x = lineWidth + 9, y = y + 2, w = expandedWidth - lineWidth - 15, h = lineHeight - 4 },
			textAlignment = "left",
			textColor = { white = 0.96, alpha = 1 },
			textSize = options.textSize or 13,
		})
	end
end

function M.render(screens, screenOrder, options, expandedWorkspace, collapsed)
	M.clear()

	local lineWidth = options.lineWidth or 3
	local lineHeight = options.lineHeight or 24
	local spacing = options.spacing or 5
	local leftInset = options.leftInset or 3
	local topInset = options.topInset or leftInset
	local expandedWidth = options.expandedWidth or 240

	if collapsed then
		local first = screens[screenOrder[1]]
		local entries = {}
		local groupGap = options.groupGap or 10

		for _, screenName in ipairs(screenOrder) do
			local group = screens[screenName]
			group.id = screenName
			for _, entry in ipairs(visibleWorkspaces(group)) do
				table.insert(entries, {
					group = group,
					entry = entry,
				})
			end
		end

		if first and #entries > 0 then
			local isExpanded = expandedWorkspace ~= nil
			local height = #entries * lineHeight + math.max(0, #entries - 1) * spacing
			local previousGroup
			for _, item in ipairs(entries) do
				if previousGroup and previousGroup ~= item.group.id then
					height = height + groupGap
				end
				previousGroup = item.group.id
			end

			local canvas = hs.canvas.new({
				x = first.frame.x + leftInset,
				y = first.frame.y + topInset,
				w = isExpanded and expandedWidth or lineWidth,
				h = height,
			})

			if isExpanded then
				canvas:appendElements({
					type = "rectangle",
					action = "fill",
					frame = { x = 0, y = 0, w = expandedWidth, h = height },
					fillColor = { red = 0.08, green = 0.09, blue = 0.11, alpha = 1 },
					roundedRectRadii = { xRadius = 4, yRadius = 4 },
				})
			end

			local y = 0
			previousGroup = nil
			for _, item in ipairs(entries) do
				if previousGroup and previousGroup ~= item.group.id then
					y = y + groupGap
				end
				appendWorkspace(canvas, item.group, item.entry, y, options, expandedWorkspace, expandedWidth)
				y = y + lineHeight + spacing
				previousGroup = item.group.id
			end

			canvas:clickActivating(false)
			canvas:show()
			M.canvases.collapsed = canvas
		end

		return
	end

	for _, screenName in ipairs(screenOrder) do
		local virtualScreen = screens[screenName]
		virtualScreen.id = screenName
		local visible = visibleWorkspaces(virtualScreen)
		local workspaceCount = #visible
		local isExpandedScreen = expandedWorkspace and expandedWorkspace.screenName == screenName

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

			for visibleIndex, entry in ipairs(visible) do
				local y = (visibleIndex - 1) * (lineHeight + spacing)
				appendWorkspace(
					canvas,
					virtualScreen,
					entry,
					y,
					options,
					isExpandedScreen and expandedWorkspace or nil,
					expandedWidth
				)
			end

			canvas:clickActivating(false)
			canvas:show()
			M.canvases[screenName] = canvas
		end
	end
end

return M
