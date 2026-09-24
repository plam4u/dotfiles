local M = {}

local function frame(x, y, width, height)
	return { x = x, y = y, w = width, h = height }
end

function M.resolve(physicalFrame, config)
	config = config or {}
	local ultrawideWidth = config.ultrawideWidth or 5120
	local ultrawideHeight = config.ultrawideHeight or 1440

	if physicalFrame.w == ultrawideWidth and physicalFrame.h == ultrawideHeight then
		local sideWidth = physicalFrame.w / 4

		return {
			profileName = "ultrawide",
			order = { "left", "center", "right" },
			screens = {
				left = {
					frame = frame(physicalFrame.x, physicalFrame.y, sideWidth, physicalFrame.h),
				},
				center = {
					frame = frame(physicalFrame.x + sideWidth, physicalFrame.y, sideWidth * 2, physicalFrame.h),
				},
				right = {
					frame = frame(physicalFrame.x + sideWidth * 3, physicalFrame.y, sideWidth, physicalFrame.h),
				},
			},
		}
	end

	return {
		profileName = "single",
		order = { "main" },
		screens = {
			main = { frame = frame(physicalFrame.x, physicalFrame.y, physicalFrame.w, physicalFrame.h) },
		},
	}
end

return M
