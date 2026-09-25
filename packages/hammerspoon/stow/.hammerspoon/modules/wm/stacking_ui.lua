local M = {
	canvases = {},
	iconCache = {},
	hitRegions = {},
}

local validDisplayModes = {
	icon = true,
	icon_label = true,
	label = true,
}

local validStackIconModes = {
	both = true,
	left = true,
	right = true,
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

local function liveMembers(workspace)
	local result = {}

	for _, member in ipairs(workspace.members or {}) do
		if member.window then
			table.insert(result, member)
		end
	end

	return result
end

local function memberName(member)
	local app = member.window and member.window:application()
	local name = app and app:name()

	return name or member.bundleID
end

local function workspaceName(members)
	local names = {}

	for _, member in ipairs(members) do
		table.insert(names, memberName(member))
	end

	if #names == 0 then
		return "Empty workspace"
	end

	return table.concat(names, "  +  ")
end

local function displayMode(options, expandedWorkspace)
	local mode = expandedWorkspace and expandedWorkspace.source == "mouse"
		and (options.mouseWorkspaceDisplayMode or "icon")
		or (options.workspaceDisplayMode or "label")
	return validDisplayModes[mode] and mode or "label"
end

local function genericIcon()
	if M.genericIcon == nil then
		M.genericIcon = hs.image.imageFromPath(
			"/System/Library/CoreServices/CoreTypes.bundle/Contents/Resources/GenericApplicationIcon.icns"
		) or false
	end
	return M.genericIcon or nil
end

local function memberIcon(member)
	local app = member.window and member.window:application()
	local bundleID = (app and app:bundleID()) or member.bundleID
	if not bundleID then return genericIcon() end

	if M.iconCache[bundleID] == nil then
		M.iconCache[bundleID] = hs.image.imageFromAppBundle(bundleID) or false
	end

	return M.iconCache[bundleID] or genericIcon()
end

local function expandedWidthFor(options, expandedWorkspace)
	if displayMode(options, expandedWorkspace) ~= "icon" then return options.expandedWidth or 240 end

	local lineWidth = options.lineWidth or 3
	local iconSize = options.iconSize or 44
	local iconMargin = options.iconMargin or 9
	return options.iconOnlyWidth or lineWidth + iconMargin * 2 + iconSize
end

local function appendMemberIcon(canvas, member, x, y, size)
	local icon = memberIcon(member)
	if icon then
		canvas:appendElements({
			type = "image",
			image = icon,
			imageScaling = "scaleProportionally",
			frame = { x = x, y = y, w = size, h = size },
		})
		return
	end

	canvas:appendElements({
		type = "rectangle",
		action = "fill",
		frame = { x = x, y = y, w = size, h = size },
		fillColor = { white = 0.28, alpha = 1 },
		roundedRectRadii = { xRadius = 4, yRadius = 4 },
	})
	canvas:appendElements({
		type = "text",
		text = "?",
		frame = { x = x, y = y + 1, w = size, h = size - 1 },
		textAlignment = "center",
		textColor = { white = 0.95, alpha = 1 },
		textSize = math.max(9, size - 6),
	})
end

local function appendWorkspaceIcons(canvas, members, x, y, size, options)
	if #members == 0 then return end
	if #members == 1 then
		appendMemberIcon(canvas, members[1], x, y, size)
		return
	end

	local mode = options.stackIconMode or "both"
	if not validStackIconModes[mode] then mode = "both" end
	if mode == "left" then
		appendMemberIcon(canvas, members[1], x, y, size)
	elseif mode == "right" then
		appendMemberIcon(canvas, members[#members], x, y, size)
	else
		local stackedSize = tonumber(options.stackedIconSize) or size / 2
		stackedSize = math.max(1, math.min(size, stackedSize))
		appendMemberIcon(canvas, members[1], x, y, stackedSize)
		appendMemberIcon(
			canvas,
			members[#members],
			x + size - stackedSize,
			y + size - stackedSize,
			stackedSize
		)
	end
end

function M.clear()
	for _, canvas in pairs(M.canvases) do
		canvas:delete()
	end

	M.canvases = {}
	M.hitRegions = {}
end

local function pointInFrame(point, frame)
	return point
		and point.x >= frame.x
		and point.x < frame.x + frame.w
		and point.y >= frame.y
		and point.y < frame.y + frame.h
end

function M.hitTest(point)
	for _, region in pairs(M.hitRegions) do
		if pointInFrame(point, region.frame) then
			local localY = point.y - region.frame.y
			for _, row in ipairs(region.rows) do
				if localY >= row.y and localY < row.y + row.h then
					return row.screenName, row.workspaceIndex, true
				end
			end
			return region.screenName, nil, true
		end
	end

	return nil, nil, false
end

function M.containsPoint(point)
	local _, _, inside = M.hitTest(point)
	return inside
end

local function configureInteraction(key, canvas, frame, rows, callbacks, screenName)
	M.hitRegions[key] = {
		frame = frame,
		rows = rows,
		screenName = screenName,
	}

	canvas:canvasMouseEvents(true, true, false, false)
	canvas:mouseCallback(function(_, message)
		if message ~= "mouseUp" or not callbacks or not callbacks.onWorkspaceClick then return end

		local targetScreen, workspaceIndex = M.hitTest(hs.mouse.absolutePosition())
		if targetScreen and workspaceIndex then
			callbacks.onWorkspaceClick(targetScreen, workspaceIndex)
		end
	end)
end

local function visibleWorkspaces(group, showUnavailableWorkspaces)
	local result = {}
	for index, workspace in ipairs(group.workspaces or {}) do
		if showUnavailableWorkspaces or liveMemberCount(workspace) > 0 then
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
	local members = liveMembers(entry.workspace)

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
		local mode = displayMode(options, expandedWorkspace)
		local iconMargin = options.iconMargin or 9
		local contentX = lineWidth + iconMargin
		if mode == "icon" or mode == "icon_label" then
			local iconSize = math.min(options.iconSize or 44, lineHeight - 4)
			local iconY = y + (lineHeight - iconSize) / 2

			appendWorkspaceIcons(canvas, members, contentX, iconY, iconSize, options)
			contentX = contentX + iconSize

			if mode == "icon_label" and #members > 0 then
				contentX = contentX + (options.iconLabelGap or 7)
			end
		end

		if mode ~= "icon" then
			local textSize = options.textSize or 13
			local textHeight = math.min(lineHeight, textSize + 6)
			canvas:appendElements({
				type = "text",
				text = workspaceName(members),
				frame = {
					x = contentX,
					y = y + (lineHeight - textHeight) / 2,
					w = expandedWidth - contentX - 6,
					h = textHeight,
				},
				textAlignment = "left",
				textColor = { white = 0.96, alpha = 1 },
				textSize = textSize,
			})
		end
	end
end

function M.render(screens, screenOrder, options, expandedWorkspace, collapsed, showUnavailableWorkspaces, callbacks)
	M.clear()

	local lineWidth = options.lineWidth or 3
	local lineHeight = options.lineHeight or 24
	local spacing = options.spacing or 5
	local leftInset = options.leftInset or 3
	local topInset = options.topInset or leftInset
	local expandedWidth = expandedWidthFor(options, expandedWorkspace)

	if collapsed then
		local first = screens[screenOrder[1]]
		local entries = {}
		local groupGap = options.groupGap or 10

		for _, screenName in ipairs(screenOrder) do
			local group = screens[screenName]
			group.id = screenName
			for _, entry in ipairs(visibleWorkspaces(group, showUnavailableWorkspaces)) do
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

			local frame = {
				x = first.frame.x + leftInset,
				y = first.frame.y + topInset,
				w = isExpanded and expandedWidth or lineWidth,
				h = height,
			}
			local canvas = hs.canvas.new(frame)

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
			local rows = {}
			previousGroup = nil
			for _, item in ipairs(entries) do
				if previousGroup and previousGroup ~= item.group.id then
					y = y + groupGap
				end
				appendWorkspace(canvas, item.group, item.entry, y, options, expandedWorkspace, expandedWidth)
				table.insert(rows, {
					y = y,
					h = lineHeight,
					screenName = item.group.id,
					workspaceIndex = item.entry.index,
				})
				y = y + lineHeight + spacing
				previousGroup = item.group.id
			end

			canvas:clickActivating(false)
			configureInteraction("collapsed", canvas, frame, rows, callbacks)
			canvas:show()
			M.canvases.collapsed = canvas
		end

		return
	end

	for _, screenName in ipairs(screenOrder) do
		local virtualScreen = screens[screenName]
		virtualScreen.id = screenName
		local visible = visibleWorkspaces(virtualScreen, showUnavailableWorkspaces)
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

			local rows = {}
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
				table.insert(rows, {
					y = y,
					h = lineHeight,
					screenName = screenName,
					workspaceIndex = entry.index,
				})
			end

			canvas:clickActivating(false)
			configureInteraction(screenName, canvas, frame, rows, callbacks, screenName)
			canvas:show()
			M.canvases[screenName] = canvas
		end
	end
end

return M
