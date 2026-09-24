local M = {
	bindings = {},
	beforeHandlers = {},
	enabled = true,
}

function M.addBeforeHandler(handler)
	table.insert(M.beforeHandlers, handler)
end

function M.bind(modifiers, key, handler, options)
	options = options or {}
	local binding = hs.hotkey.bind(modifiers, key, function()
		if options.dismissOverlays ~= false then
			for _, beforeHandler in ipairs(M.beforeHandlers) do
				beforeHandler()
			end
		end
		handler()
	end)

	table.insert(M.bindings, {
		hotkey = binding,
		persistent = options.persistent == true,
	})

	if not M.enabled and not options.persistent then
		binding:disable()
	end

	return binding
end

function M.setEnabled(enabled)
	M.enabled = enabled == true

	for _, binding in ipairs(M.bindings) do
		if binding.persistent or M.enabled then
			binding.hotkey:enable()
		else
			binding.hotkey:disable()
		end
	end
end

function M.isEnabled()
	return M.enabled
end

return M
