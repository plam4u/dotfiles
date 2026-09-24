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

function M.clear()
	for _, canvas in pairs(M.canvases) do
		canvas:delete()
	end

	M.canvases = {}
end

function M.render(regions, regionOrder, options)
	M.clear()

	local size = options.size or 14
	local spacing = options.spacing or 5
	local inset = options.inset or 8

	for _, regionName in ipairs(regionOrder) do
		local region = regions[regionName]
		local groupCount = #region.groups

		if groupCount > 0 then
			local width = groupCount * size + math.max(0, groupCount - 1) * spacing
			local frame = {
				x = region.frame.x + inset,
				y = region.frame.y + inset,
				w = width,
				h = size,
			}
			local canvas = hs.canvas.new(frame)

			for index, group in ipairs(region.groups) do
				local liveCount = liveMemberCount(group)
				local isActive = index == region.activeGroup
				local alpha = liveCount > 0 and 0.9 or 0.25
				local itemFrame = {
					x = (index - 1) * (size + spacing),
					y = 0,
					w = size,
					h = size,
				}

				canvas:appendElements({
					type = "rectangle",
					action = "fill",
					frame = itemFrame,
					fillColor = isActive and { red = 0.3, green = 0.75, blue = 1, alpha = alpha }
						or { white = 0.65, alpha = alpha },
					roundedRectRadii = { xRadius = size / 2, yRadius = size / 2 },
				})

				if #group.members == 2 then
					canvas:appendElements({
						type = "text",
						text = "2",
						frame = itemFrame,
						textAlignment = "center",
						textColor = { white = 0.1, alpha = alpha },
						textSize = 10,
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
