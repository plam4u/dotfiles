if true then
  return {}
end

return {
  {
    "yetone/avante.nvim",
    event = "VeryLazy",
    version = false, -- Never set this value to "*"! Never!
    opts = {
      provider = "copilot",
      auto_suggestions_provider = nil,
      providers = {
        copilot = {
          model = "claude-sonnet-4",
        },
      },
      mappings = {
        sidebar = {
          close_from_input = { normal = "<Esc>", insert = "<C-d>" },
          switch_windows = "<C-n>",
          reverse_switch_windows = "<C-p>",
        },
      },
      windows = {
        ---@type "right" | "left" | "top" | "bottom"
        position = "right",
        wrap = true,
        width = 45, -- in %
        input = {
          height = 7, -- Height of the input window in vertical layout
        },
        edit = {
          border = "rounded", -- Border style for the edit window
        },
        ask = {
          border = "rounded", -- Border style for the edit window
        },
      },
    },
    build = "make",
    dependencies = {
      "nvim-treesitter/nvim-treesitter",
      "stevearc/dressing.nvim",
      "nvim-lua/plenary.nvim",
      "MunifTanjim/nui.nvim",
      --- The below dependencies are optional,
      "echasnovski/mini.pick", -- for file_selector provider mini.pick
      "nvim-telescope/telescope.nvim", -- for file_selector provider telescope
      "hrsh7th/nvim-cmp", -- autocompletion for avante commands and mentions
      "ibhagwan/fzf-lua", -- for file_selector provider fzf
      "nvim-tree/nvim-web-devicons", -- or echasnovski/mini.icons
      "zbirenbaum/copilot.lua", -- for providers='copilot'
      {
        -- support for image pasting
        "HakonHarnes/img-clip.nvim",
        event = "VeryLazy",
        opts = {
          -- recommended settings
          default = {
            embed_image_as_base64 = false,
            prompt_for_file_name = false,
            drag_and_drop = {
              insert_mode = true,
            },
            -- required for Windows users
            use_absolute_path = true,
          },
        },
      },
      {
        -- Make sure to set this up properly if you have lazy=true
        "MeanderingProgrammer/render-markdown.nvim",
        opts = {
          file_types = { "markdown", "Avante" },
        },
        ft = { "markdown", "Avante" },
      },
    },
  },
}
