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
			-- Always use geometric navigation instead of cycling workspaces.
			focusDirectionalNorth = { "alt", "i" },
			focusDirectionalSouth = { "alt", "," },
		},
	},
	stacking = {
		config = {
			ultrawideWidth = 5120,
			ultrawideHeight = 1440,
			resizeStep = 80,
			defaultMinWidth = 200,
			indicatorDuration = 1,
			ui = {
				lineWidth = 3,
				lineHeight = 24,
				spacing = 5,
				leftInset = 3,
				topInset = 3,
				expandedWidth = 240,
				textSize = 16,
			},
		},
		mapping = {
			-- Persist and restore the complete workspace model on demand.
			saveStacks = { meh, "=" },
			loadStacks = { hyper, "=" },
			-- Select or create a workspace on the focused virtual screen.
			focusWorkspace1 = { "alt", "1" },
			focusWorkspace2 = { "alt", "2" },
			focusWorkspace3 = { "alt", "3" },
			focusWorkspace4 = { "alt", "4" },
			focusWorkspace5 = { "alt", "5" },
			focusWorkspace6 = { "alt", "6" },
			focusWorkspace7 = { "alt", "7" },
			focusWorkspace8 = { "alt", "8" },
			focusWorkspace9 = { "alt", "9" },
			-- Move the focused window directly to a numbered workspace.
			moveFocusedWindowToWorkspace1 = { { "alt", "shift" }, "1" },
			moveFocusedWindowToWorkspace2 = { { "alt", "shift" }, "2" },
			moveFocusedWindowToWorkspace3 = { { "alt", "shift" }, "3" },
			moveFocusedWindowToWorkspace4 = { { "alt", "shift" }, "4" },
			moveFocusedWindowToWorkspace5 = { { "alt", "shift" }, "5" },
			moveFocusedWindowToWorkspace6 = { { "alt", "shift" }, "6" },
			moveFocusedWindowToWorkspace7 = { { "alt", "shift" }, "7" },
			moveFocusedWindowToWorkspace8 = { { "alt", "shift" }, "8" },
			moveFocusedWindowToWorkspace9 = { { "alt", "shift" }, "9" },
			deleteActiveWorkspace = { "alt", "." },
			-- Move the focused window into a new workspace.
			moveWindowToLeft = { meh, "u" },
			moveWindowToCenter = { meh, "i" },
			moveWindowToRight = { meh, "o" },
			-- Add the focused window to the active workspace.
			addWindowToLeftWorkspace = { hyper, "u" },
			addWindowToCenterWorkspace = { hyper, "i" },
			addWindowToRightWorkspace = { hyper, "o" },
			extractWindowFromWorkspace = { hyper, "p" },
			-- Resize the focused member inside a two-window workspace.
			shrinkFocusedMember = { hyper, "h" },
			growFocusedMember = { hyper, "l" },
			resetWorkspaceSplit = { hyper, ";" },
		},
	},
	-- modules.wm.persistence is intentionally disabled. Stacking owns
	-- managed window restoration; persistence.lua remains as reference.
})
require("reload").setup({
	includeSuffixes = { ".lua", ".json" },
	excludePaths = { "state/" },
})
