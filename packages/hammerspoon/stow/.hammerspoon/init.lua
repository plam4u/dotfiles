local meh = { "shift", "ctrl", "alt" }
local hyper = { "shift", "ctrl", "alt", "cmd" }

require("modules.caffeine").setup({
	mapping = {
		toggle = { meh, "y" },
	},
})
require("modules.wm").setup({
	borders = {
		arguments = {
			"active_color=0xff61afef",
			"inactive_color=0x00000000",
			"width=5.0",
		},
	},
	control = {
		mapping = {
			toggle = { hyper, "m" },
		},
	},
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
			groupOrder = { "left", "center", "right" },
			groupLabels = {
				left = "Left",
				center = "Center",
				right = "Right",
			},
			groupWeights = {
				left = 0.25,
				center = 0.50,
				right = 0.25,
			},
			laptopBarHeight = 40,
			mouseFollowsFocus = true,
			-- "standard": wheel up = previous; "natural": wheel up = next.
			workspaceScrollDirection = "natural",
			workspaceScrollThrottle = 0.18,
			resizeStep = 80,
			defaultMinWidth = 200,
			indicatorDuration = 1,
			ui = {
				lineWidth = 3,
				lineHeight = 48,
				spacing = 6,
				leftInset = 3,
				topInset = 3,
				-- Keyboard-triggered expansion: "label", "icon_label", or "icon".
				workspaceDisplayMode = "icon_label",
				-- Mouse group-hover expansion has its own presentation mode.
				mouseWorkspaceDisplayMode = "icon",
				iconSize = 44,
				iconMargin = 9,
				iconLabelGap = 7,
				iconOnlyWidth = 65,
				-- Two-window icon slot: "both", "left", or "right".
				stackIconMode = "both",
				stackedIconSize = 33,
				expandedWidth = 280,
				textSize = 18,
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
			moveWorkspaceEarlier = { meh, "n" },
			moveWorkspaceLater = { meh, "m" },
			-- Move the focused window into a new workspace.
			moveWindowToGroup1 = { meh, "u" },
			moveWindowToGroup2 = { meh, "i" },
			moveWindowToGroup3 = { meh, "o" },
			-- Add the focused window to the active workspace.
			addWindowToGroup1 = { hyper, "u" },
			addWindowToGroup2 = { hyper, "i" },
			addWindowToGroup3 = { hyper, "o" },
			extractWindowFromWorkspace = { hyper, "p" },
			-- Resize the focused member inside a two-window workspace.
			shrinkFocusedMember = { hyper, "h" },
			growFocusedMember = { hyper, "l" },
			resetWorkspaceSplit = { hyper, ";" },
			-- Reorder and resize virtual-screen groups at runtime.
			moveGroupEarlier = { hyper, "," },
			moveGroupLater = { hyper, "." },
			shrinkGroup = { hyper, "[" },
			growGroup = { hyper, "]" },
		},
	},
	sketchybar = {
		-- Options: "background", "border", "underline", "left_bar", "text".
		workspaceFocusStyle = "underline",
		initialSelectedItem = "clock",
		mapping = {
			toggleNavigation = { "alt", "m" },
		},
	},
	-- modules.wm.persistence is intentionally disabled. Stacking owns
	-- managed window restoration; persistence.lua remains as reference.
})
require("reload").setup({
	includeSuffixes = { ".lua", ".json" },
	excludePaths = { "state/" },
})
