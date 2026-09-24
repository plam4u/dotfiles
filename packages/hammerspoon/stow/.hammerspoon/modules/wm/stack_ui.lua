local M = {
	canvases = {},
}

local function liveMemberCount(group)
	local count = 0

	for _, member in ipairs(group.members) do
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

local function groupName(group)
	local names = {}

	for _, member in ipairs(group.members) do
		table.insert(names, memberName(member))
	end

	return table.concat(names, "  +  ")
end

function M.clear()
	for _, canvas in pairs(M.canvases) do
		canvas:delete()
	end

	M.canvases = {}
end

function M.render(regions, regionOrder, options, expandedGroup)
	M.clear()

	local lineWidth = options.lineWidth or 3
	local lineHeight = options.lineHeight or 24
	local spacing = options.spacing or 5
	local leftInset = options.leftInset or 3
	local topInset = options.topInset or leftInset
	local expandedWidth = options.expandedWidth or 240

	for _, regionName in ipairs(regionOrder) do
		local region = regions[regionName]
		local groupCount = #region.groups
		local isExpandedRegion = expandedGroup and expandedGroup.regionName == regionName
		local focusedGroupIndex = isExpandedRegion and expandedGroup.groupIndex or nil

		if groupCount > 0 then
			local frame = {
				x = region.frame.x + leftInset,
				y = region.frame.y + topInset,
				w = isExpandedRegion and expandedWidth or lineWidth,
				h = groupCount * lineHeight + math.max(0, groupCount - 1) * spacing,
			}
			local canvas = hs.canvas.new(frame)

			if isExpandedRegion then
				canvas:appendElements({
					type = "rectangle",
					action = "fill",
					frame = { x = 0, y = 0, w = expandedWidth, h = frame.h },
					fillColor = { red = 0.08, green = 0.09, blue = 0.11, alpha = 1 },
					roundedRectRadii = { xRadius = 4, yRadius = 4 },
				})
			end

			for index, group in ipairs(region.groups) do
				local y = (index - 1) * (lineHeight + spacing)
				local liveCount = liveMemberCount(group)
				local isActive = index == region.activeGroup
				local isExpanded = isExpandedRegion
				local isFocused = index == focusedGroupIndex
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
						text = groupName(group),
						frame = { x = lineWidth + 9, y = y + 2, w = expandedWidth - lineWidth - 15, h = lineHeight - 4 },
						textAlignment = "left",
						textColor = { white = 0.96, alpha = 1 },
						textSize = options.textSize or 13,
					})
				end
			end

			canvas:clickActivating(false)
			canvas:show()
			M.canvases[regionName] = canvas
		end
	end
end

return M
