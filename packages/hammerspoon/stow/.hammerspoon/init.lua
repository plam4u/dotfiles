local meh = { "shift", "ctrl", "alt" }
local hyper = { "shift", "ctrl", "alt", "cmd" }

require("modules.caffeine").setup({
	mapping = {
		toggle = { meh, "y" },
	},
})
require("modules.wm").setup({
	apps = {
		mapping = {
			hideApp = { meh, "g" },
		},
	},
	layout = {
		config = {
			gridSize = "8x8",
			margins = "0,0",
			animationDuration = 0,
		},
		mapping = {
			-- Move window
			pushWindowUp = { meh, "k" },
			pushWindowDown = { meh, "j" },
			pushWindowLeft = { meh, "h" },
			pushWindowRight = { meh, "l" },
			-- Resize window
			resizeWindowShorter = { hyper, "k" },
			resizeWindowTaller = { hyper, "j" },
			-- Predefined floating-window sizes
			tileCenterWindow = { meh, "p" },
			maximizeWindow = { meh, "space" },
			minimizeWindow = { meh, "." },
			-- Position
			moveWindowToNextScreen = { meh, "/" },
			snapWindow = { meh, "," },
			centerWindow = { meh, "t" },
		},
	},
	navigation = {
		mapping = {
			-- Focus window
			focusWest = { "alt", "h" },
			focusSouth = { "alt", "j" },
			focusNorth = { "alt", "k" },
			focusEast = { "alt", "l" },
			-- Always use geometric navigation instead of cycling groups.
			focusDirectionalNorth = { "alt", "i" },
			focusDirectionalSouth = { "alt", "," },
		},
	},
	stacking = {
		config = {
			screenWidth = 5120,
			screenHeight = 1440,
			resizeStep = 80,
			defaultMinWidth = 200,
		},
		mapping = {
			-- Persist and restore the complete stack model on demand.
			saveStacks = { meh, "=" },
			loadStacks = { hyper, "=" },
			-- Move the focused window into a new group.
			moveWindowToLeft = { meh, "u" },
			moveWindowToCenter = { meh, "i" },
			moveWindowToRight = { meh, "o" },
			-- Add the focused window to the active group.
			addWindowToLeftGroup = { hyper, "u" },
			addWindowToCenterGroup = { hyper, "i" },
			addWindowToRightGroup = { hyper, "o" },
			extractWindowFromGroup = { hyper, "p" },
			-- Resize the focused member inside a two-window group.
			shrinkFocusedMember = { hyper, "h" },
			growFocusedMember = { hyper, "l" },
			resetGroupSplit = { hyper, ";" },
		},
	},
	-- modules.wm.persistence is intentionally disabled. Stacking owns
	-- managed window restoration; persistence.lua remains as reference.
})
require("reload").setup({})
