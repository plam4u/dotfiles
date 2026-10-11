return {
  "hardyrafael17/norminette42.nvim",

  ft = { "c" },

  config = function()
    require("norminette").setup({
      runOnSave = true,
      maxErrorsToShow = 10,
      active = true,
    })
  end,
}
