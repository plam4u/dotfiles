-- - favorites:
--
--    ayu-mirage
--    catppuccin
--    gruvbox-material
--    kanagawa
--    rose-pine-moon
--    tokyonight-moon

return {
  {
    "ellisonleao/gruvbox.nvim",
    priority = 1000,
    config = function()
      require("gruvbox").setup()
      vim.o.background = "dark" -- or "light" for light mode
      -- vim.cmd.colorscheme("gruvbox")
    end,
  },
  {
    "sainnhe/gruvbox-material",
    lazy = false,
    priority = 1000,
    config = function()
      vim.g.gruvbox_material_background = "medium" -- "hard", "medium", "soft"
      vim.g.gruvbox_material_palette = "material" -- "material", "mix", "original"
      -- vim.cmd.colorscheme("gruvbox-material")
    end,
  },
  {
    "luisiacc/gruvbox-baby",
    lazy = false,
    priority = 1000,
    config = function()
      vim.g.gruvbox_baby_background_color = "medium" -- "dark", "medium", "light"
      -- vim.cmd.colorscheme("gruvbox-baby")
    end,
  },
  {
    "rose-pine/neovim",
    name = "rose-pine",
    lazy = false,
    priority = 1000,
    config = function()
      -- vim.cmd("colorscheme rose-pine-moon")
    end,
  },

  -- copied from TJ Devries
  "tjdevries/colorbuddy.nvim",
  "rktjmp/lush.nvim",
  "tckmn/hotdog.vim",
  "dundargoc/fakedonalds.nvim",
  "craftzdog/solarized-osaka.nvim",
  { "rose-pine/neovim", name = "rose-pine" },
  "eldritch-theme/eldritch.nvim",
  "jesseleite/nvim-noirbuddy",
  "miikanissi/modus-themes.nvim",
  "rebelot/kanagawa.nvim",
  "gremble0/yellowbeans.nvim",
  "rockyzhang24/arctic.nvim",
  "folke/tokyonight.nvim",
  "Shatur/neovim-ayu",
  -- "RRethy/base16-nvim",
  "xero/miasma.nvim",
  "cocopon/iceberg.vim",
  "kepano/flexoki-neovim",
  "ntk148v/komau.vim",
  { "catppuccin/nvim", name = "catppuccin" },
  "uloco/bluloco.nvim",
  "LuRsT/austere.vim",
  "ricardoraposo/gruvbox-minor.nvim",
  "NTBBloodbath/sweetie.nvim",
  "vim-scripts/MountainDew.vim",
  "maxmx03/fluoromachine.nvim",
}
