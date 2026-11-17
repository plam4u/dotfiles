local caffeine = require("modules.caffeine")
local M = {}
local rows = {
    { id = "enabled", heading = "Caffeine", action = function() caffeine.caffeineClicked({}) end },
    { id = "mode", heading = "Sleep prevention", action = caffeine.toggleMode },
    { id = "display", heading = "Keep display on (-d)", action = caffeine.toggleDisplay },
    { id = "label", action = caffeine.toggleLabel },
}
local function rowHeading(row)
    if row.id == "label" then return caffeine.getState().showLabel and "Hide label" or "Show label" end
    return row.heading
end
local function rowValue(row)
    local state = caffeine.getState()
    if row.id == "enabled" then return state.enabled and "On" or "Off" end
    if row.id == "display" then return state.keepDisplayOn and "On" or "Off" end
    if row.id == "mode" then return state.mode == "idle" and "Idle (-i)" or "System (-s, AC)" end
    return ""
end

function M.clearPopup()
	if M.ui then M.ui.run({ "--set", "caffeine", "popup.drawing=off", "--remove", "/^wm.caffeine\\./" }) end
end

function M.renderDetails()
	if not M.detailsVisible then return end
	local args = { "--set", "/^wm.caffeine\\./", "background.drawing=off" }
	for index, row in ipairs(rows) do
		local name = "wm.caffeine." .. tostring(index)
		table.insert(args, "--set")
		table.insert(args, name)
		table.insert(args, "icon=" .. rowHeading(row))
		table.insert(args, "label=" .. rowValue(row))
		if index == M.rowIndex then table.insert(args, "background.drawing=on") end
	end
	M.ui.run(args)
end

function M.openDetails()
	M.ui.closeMenu()
	M.ui.closeCodexUsageDetails()
	M.clearPopup()
	M.rowIndex = 1
	local args = {}
	for index, row in ipairs(rows) do
		local name = "wm.caffeine." .. tostring(index)
		for _, argument in ipairs({
			"--add", "item", name, "popup.caffeine",
			"--set", name,
			"icon=" .. rowHeading(row),
			"icon.font=Hack Nerd Font:Bold:13.0",
			"icon.width=210",
			"icon.align=left",
			"icon.padding_left=10",
			"icon.padding_right=4",
			"label=" .. rowValue(row),
			"label.font=Hack Nerd Font:Regular:13.0",
			"label.width=150",
			"label.align=right",
			"label.padding_left=4",
			"label.padding_right=10",
			"background.color=0xff3b82f6",
			"background.corner_radius=6",
			"background.height=26",
			"background.drawing=off",
            "click_script=/usr/bin/open -g 'hammerspoon://wm-bar?command=caffeine-row&index=" .. index .. "'",
		}) do table.insert(args, argument) end
	end
	M.ui.run(args)
	M.ui.run({ "--set", "caffeine", "popup.drawing=on" })
	M.detailsVisible = true
	M.renderDetails()
end

function M.closeDetails()
	if not M.detailsVisible then return end
	M.clearPopup()
	M.detailsVisible = false
	M.rowIndex = nil
end

function M.syncDetails(active, selected, menuIndex)
	local shouldShow = active and selected and selected.id == "caffeine" and not menuIndex
	if shouldShow and not M.detailsVisible then
		M.openDetails()
	elseif not shouldShow and M.detailsVisible then
		M.closeDetails()
	end
end

function M.handleVertical(selected, delta)
	if not selected or selected.id ~= "caffeine" or not M.detailsVisible then return false end
	M.rowIndex = ((M.rowIndex - 1 + delta) % #rows) + 1
	M.renderDetails()
	return true
end

function M.invokeSelected(selected)
    if not selected or selected.id ~= "caffeine" or not M.detailsVisible then return false end
    rows[M.rowIndex].action()
    return true
end

function M.setup(_, ui)
    M.ui = ui
    M.clearPopup()
    caffeine.subscribe(function(state)
        ui.updateCaffeine(state)
        if M.detailsVisible then M.renderDetails() end
    end)
end

return M
