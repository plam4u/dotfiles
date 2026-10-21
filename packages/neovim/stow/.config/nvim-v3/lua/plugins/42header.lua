return {
  "Diogo-ss/42-header.nvim",
  config = function()
    require("42header").setup({
      user = "pandreev",
      mail = "pandreev@student.42barcelona.com",
      default_map = true,
      auto_update = true,
    })
  end,
}
