local M = {}

local function frame(x, y, width, height)
	return { x = x, y = y, w = width, h = height }
end

local function copyArray(values)
	local result = {}
	for _, value in ipairs(values or {}) do
		table.insert(result, value)
	end
	return result
end

local function normalizedWeights(order, configured)
	local weights = {}
	local total = 0

	for _, groupID in ipairs(order) do
		local weight = tonumber(configured and configured[groupID]) or 1
		weight = math.max(0.05, weight)
		weights[groupID] = weight
		total = total + weight
	end

	for _, groupID in ipairs(order) do
		weights[groupID] = weights[groupID] / total
	end

	return weights
end

function M.resolve(physicalFrame, config, runtimeLayout)
	config = config or {}
	runtimeLayout = runtimeLayout or {}
	local ultrawideWidth = config.ultrawideWidth or 5120
	local ultrawideHeight = config.ultrawideHeight or 1440
	local ultrawideMinAspectRatio = config.ultrawideMinAspectRatio or 2.3
	local order = copyArray(runtimeLayout.order or config.groupOrder or { "left", "center", "right" })
	local aspectRatio = physicalFrame.w / math.max(1, physicalFrame.h)
	local isUltrawide = (physicalFrame.w == ultrawideWidth and physicalFrame.h == ultrawideHeight)
		or aspectRatio >= ultrawideMinAspectRatio
	local screens = {}

	if isUltrawide then
		local weights = normalizedWeights(order, runtimeLayout.weights or config.groupWeights)
		local x = physicalFrame.x

		for index, groupID in ipairs(order) do
			local width = index == #order and physicalFrame.x + physicalFrame.w - x
				or math.floor(physicalFrame.w * weights[groupID] + 0.5)
			screens[groupID] = {
				frame = frame(x, physicalFrame.y, width, physicalFrame.h),
				label = (config.groupLabels or {})[groupID] or groupID,
			}
			x = x + width
		end

		return {
			profileName = "ultrawide",
			order = order,
			screens = screens,
			collapsed = false,
			weights = weights,
		}
	end

	local reservedTop = tonumber(config.laptopBarHeight) or 0
	local laptopFrame = frame(
		physicalFrame.x,
		physicalFrame.y + reservedTop,
		physicalFrame.w,
		math.max(1, physicalFrame.h - reservedTop)
	)

	for _, groupID in ipairs(order) do
		screens[groupID] = {
			frame = frame(laptopFrame.x, laptopFrame.y, laptopFrame.w, laptopFrame.h),
			label = (config.groupLabels or {})[groupID] or groupID,
		}
	end

	return {
		profileName = "laptop",
		order = order,
		screens = screens,
		collapsed = true,
		weights = normalizedWeights(order, runtimeLayout.weights or config.groupWeights),
	}
end

return M
