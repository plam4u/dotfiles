return {
	-- onedark
	{
		"navarasu/onedark.nvim",
		config = function()
			require("onedark").setup({}) -- { style = "darker" })
			vim.cmd.colorscheme("onedark")
		end,
		priority = 1000,
	},

	-- tokyonight
	{
		"folke/tokyonight.nvim",
		lazy = true,
		opts = { style = "moon" },
	},

	-- catppuccin
	{
		"catppuccin/nvim",
		lazy = true,
		name = "catppuccin",
	},
}
