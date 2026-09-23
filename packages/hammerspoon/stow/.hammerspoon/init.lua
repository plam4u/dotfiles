meh = { "shift", "ctrl", "alt" }
hyper = { "shift", "ctrl", "alt", "cmd" }

require("apps").setup({
	mapping = {
		hide = { meh, "g" },
	},
})
require("grid").setup({})
require("caffeine").setup({})
require("wm").setup({
	mapping = {
		saveDesktop = { hyper, "=" },
		restoreDesktop = { meh, "=" },
	},
})
require("reload").setup({})
