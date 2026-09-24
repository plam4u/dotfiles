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
			resizeWindowThinner = { hyper, "h" },
			resizeWindowWider = { hyper, "l" },
			resizeWindowShorter = { hyper, "k" },
			resizeWindowTaller = { hyper, "j" },
			-- Predefined window sizes
			leftQHDWindow = { meh, "u" },
			centeredQHDWindow = { meh, "i" },
			rightQHDWindow = { meh, "o" },
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
		},
	},
	persistence = {
		mapping = {
			saveLayout = { meh, "=" },
			restoreLayout = { hyper, "=" },
		},
	},
})
require("reload").setup({})
