return {
  "Diogo-ss/42-header.nvim",
  config = function()
    vim.g.user = "pandreev"
    vim.g.mail = "pandreev@student.42barcelona.com"
    require("42header").setup({
      user = "pandreev",
      mail = "pandreev@student.42barcelona.com",
      default_map = true,
      auto_update = false,
    })
  end,
}
