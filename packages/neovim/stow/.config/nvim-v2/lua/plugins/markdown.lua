return {
  -- {
  --   "stevearc/conform.nvim",
  --   enabled = false,
  -- },
  { "iamcco/markdown-preview.nvim", lazy = false }, --, enabled = false },
  -- { "OXY2DEV/markview.nvim", enabled = false }, -- added by CodeCompanion
  {
    "MeanderingProgrammer/render-markdown.nvim",
    opts = {
      code = {
        sign = false,
        width = "block",
        right_pad = 1,
      },
      heading = {
        -- backgrounds = {}, -- Disable background highlighting that extends to end of line
        width = "block", -- Only highlight the text, not full line
      },
      checkbox = {
        enabled = true,
      },
      link = {
        enabled = true,
        wiki = {
          -- icon = "󱗖 ",
          icon = "",
          body = function()
            return nil
          end,
          highlight = "RenderMarkdownWikiLink",
        },
      },
    },
  },
}
