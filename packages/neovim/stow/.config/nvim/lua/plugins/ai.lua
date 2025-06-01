if true then
  return {
    {
      "olimorris/codecompanion.nvim",
      lazy = true,
      opts = {},
      dependencies = {
        "nvim-lua/plenary.nvim",
        "nvim-treesitter/nvim-treesitter",
        "ravitemer/mcphub.nvim",
      },
    },
    {
      "olimorris/codecompanion.nvim",
      opts = {},
      dependencies = {
        "nvim-lua/plenary.nvim",
        "nvim-treesitter/nvim-treesitter",
        "ravitemer/mcphub.nvim",
      },
      keys = {
        -- General
        { "<leader>ac", "<cmd>CodeCompanionActions<cr>", mode = { "n", "v" }, desc = "Open Actions (CodeCompanion)" },
        { "<leader>at", "<cmd>CodeCompanionCmd<cr>", mode = { "n", "v" }, desc = "Write Cmd (CodeCompanion)" },

        -- Chat
        { "<leader>an", "<cmd>CodeCompanionChat<cr>", mode = { "n", "v" }, desc = "New Chat (CodeCompanion)" },
        { "<leader>aa", "<cmd>CodeCompanionChat Toggle<cr>", mode = { "n", "v" }, desc = "Toggle (CodeCompanion)" },
        {
          "gs",
          "<cmd>CodeCompanionChat Add<cr><esc>:wincmd l<cr>",
          mode = { "v" },
          desc = "Add Selection to Chat (CodeCompanion)",
        },

        -- Inline Assistant
        { "ga", ":CodeCompanion ", mode = { "v" }, desc = "Ask Inline (CodeCompanion)" },
        { "ge", ":CodeCompanion @editor ", mode = { "v" }, desc = "Edit Inline (CodeCompanion)" },

        -- LocalLeader
        { "<localleader>a", "<cmd>CodeCompanionChat Toggle<cr>", mode = { "n", "v" }, desc = "Toggle (CodeCompanion)" },
        { "<localleader>e", ":CodeCompanion /explain<cr>", mode = { "v" }, desc = "Explain Selection (CodeCompanion)" },
        {
          "<localleader>d",
          "<cmd>CodeCompanion /prompt_example<cr>",
          mode = { "n" },
          desc = "Example Prompt (CodeCompanion)",
        },
      },
      config = function(_, _)
        -- Expand 'cc' into 'CodeCompanion' in the command line
        vim.cmd([[cab cc CodeCompanion]])

        require("codecompanion").setup({
          extensions = {
            mcphub = {
              callback = "mcphub.extensions.codecompanion",
              opts = {
                make_vars = true,
                make_slash_commands = true,
                show_result_in_chat = true,
              },
            },
          },
          prompt_library = {
            ["Example Prompt"] = {
              strategy = "chat",
              description = "This is a sample prompt description.",
              opts = {
                index = 11,
                is_slash_cmd = false,
                auto_submit = false,
                short_name = "prompt_example",
              },
              references = {
                {
                  type = "file",
                  path = {
                    "README.md",
                    "TODO.md",
                  },
                },
              },
              prompts = {
                {
                  role = "user",
                  content = [[
I'm rewriting the documentation for my python code, as I'm moving to a uv project manager. Can you help me rewrite it?

I'm sharing my `README.md` and `TODO.md` with you. 
]],
                },
              },
            },
          },
        })
      end,
    },
    {
      "folke/which-key.nvim",
      optional = true,
      opts = {
        spec = {
          { "<leader>a", group = "CodeCompanion" },
        },
      },
    },
    {
      "MeanderingProgrammer/render-markdown.nvim",
      ft = { "markdown", "codecompanion" },
    },
    {
      "OXY2DEV/markview.nvim",
      lazy = false,
      opts = {
        preview = {
          filetypes = { "markdown", "codecompanion" },
          ignore_buftypes = {},
        },
      },
    },
    {
      "echasnovski/mini.diff",
      config = function()
        local diff = require("mini.diff")
        diff.setup({
          -- Disabled by default
          source = diff.gen_source.none(),
        })
      end,
    },
    {
      "HakonHarnes/img-clip.nvim",
      opts = {
        filetypes = {
          codecompanion = {
            prompt_for_file_name = false,
            template = "[Image]($FILE_PATH)",
            use_absolute_path = true,
          },
        },
      },
    },
    {
      "saghen/blink.cmp",
      opts = {
        sources = {
          per_filetype = {
            codecompanion = { "codecompanion" },
          },
        },
      },
    },
  }
end

return {
  "yetone/avante.nvim",
  event = "VeryLazy",
  version = false, -- Never set this value to "*"! Never!
  opts = {
    provider = "copilot",
    auto_suggestions_provider = "copilot",
    -- provider = "openai",
    -- openai = {
    --   endpoint = "https://api.openai.com/v1",
    --   model = "gpt-4o", -- your desired model (or use gpt-4o, etc.)
    --   timeout = 30000, -- Timeout in milliseconds, increase this for reasoning models
    --   temperature = 0,
    --   max_completion_tokens = 8192, -- Increase this to include reasoning tokens (for reasoning models)
    --reasoning_effort = "medium", -- low|medium|high, only used for reasoning models
    -- },
  },
  -- if you want to build from source then do `make BUILD_FROM_SOURCE=true`
  build = "make",
  -- build = "powershell -ExecutionPolicy Bypass -File Build.ps1 -BuildFromSource false" -- for windows
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
}
