return {
  "folke/noice.nvim",
  opts = {
    lsp = {
      hover = {
        enabled = true,
        view = "hover",
      },
      signature = {
        enabled = false,
        view = "hover",
      },
    },
    views = {
      hover = {
        border = {
          style = "rounded",
        },
      },
    },
  },
}
