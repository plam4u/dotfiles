local meh = { "shift", "ctrl", "alt" }
local hyper = { "shift", "ctrl", "alt", "cmd" }

require("apps").setup({
	mapping = {
		hide = { meh, "g" },
	},
})
require("grid").setup({
	mapping = {
		-- Focus window
		{ "focusWest", { "alt" }, "h" },
		{ "focusSouth", { "alt" }, "j" },
		{ "focusNorth", { "alt" }, "k" },
		{ "focusEast", { "alt" }, "l" },

		-- Move window
		{ "pushWindowUp", meh, "k" },
		{ "pushWindowDown", meh, "j" },
		{ "pushWindowLeft", meh, "h" },
		{ "pushWindowRight", meh, "l" },

		-- Resize window
		{ "resizeWindowThinner", hyper, "h" },
		{ "resizeWindowWider", hyper, "l" },
		{ "resizeWindowShorter", hyper, "k" },
		{ "resizeWindowTaller", hyper, "j" },

		-- Left / center / right
		{ "leftQHDWindow", meh, "u" },
		{ "centeredQHDWindow", meh, "i" },
		{ "rightQHDWindow", meh, "o" },

		-- Grid size
		{ "setGrid2", meh, "2" },
		{ "setGrid3", meh, "3" },
		{ "setGrid4", meh, "4" },
		{ "setGrid6", meh, "6" },
		{ "setGrid7", meh, "7" },
		{ "setGrid8", meh, "8" },
		{ "setGrid9", meh, "9" },
		{ "setGrid10", meh, "0" },

		-- Wide layouts
		{ "wideCenteredWindowPadded", meh, "5" },
		{ "wideCenteredWindowFullHeight", hyper, "5" },

		-- This duplicates meh + 6 from the original configuration.
		{ "tileCenterWindow", meh, "6" },

		-- Screen / positioning
		{ "moveWindowToNextScreen", meh, "/" },
		{ "snapWindow", meh, "," },
		{ "centerWindow", meh, "t" },

		-- Maximize
		{ "maximizeWindow", meh, "space" },
		{ "maximizeWindow", meh, "n" },

		-- 640x480, preserving position
		{ "minimizeWindow", meh, "." },
	},
})
require("caffeine").setup({})
require("wm").setup({
	mapping = {
		saveDesktop = { meh, "=" },
		restoreDesktop = { hyper, "=" },
	},
})
require("reload").setup({})
