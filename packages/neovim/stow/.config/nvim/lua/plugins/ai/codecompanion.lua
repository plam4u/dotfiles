return {
  {
    "olimorris/codecompanion.nvim",
    opts = {
      extensions = {
        history = {
          enabled = true,
          opts = {
            keymap = "gh",
            save_chat_keymap = "gu",
            auto_save = false,
            auto_generate_title = true,
            continue_last_chat = false,
            delete_on_clearing_chat = true,
            picker = "snacks",
            enable_logging = false,
            dir_to_save = vim.fn.stdpath("data") .. "/codecompanion-history",
          },
        },
      },
      strategies = {
        chat = {
          adapter = {
            name = "copilot",
            model = "claude-sonnet-4",
          },
          roles = {
            user = "P",
          },
          keymaps = {
            stop = { modes = { n = "Q" } },
            close = { modes = { n = "q", i = "<C-c>" } },
            send = { modes = { i = { "<C-CR>", "<C-s>" } } },
            completion = { modes = { i = "<C-x>" } },
            auto_tool_mode = { modes = { n = "gat" } },
          },
          slash_commands = {
            ["symbols"] = {
              provider = "snacks",
            },
            ["buffer"] = {
              keymaps = {
                modes = {
                  i = "<C-b>",
                },
              },
            },
            ["fetch"] = {
              keymaps = {
                modes = {
                  i = "<C-f>",
                },
              },
            },
            ["help"] = {
              opts = {
                max_lines = 1000,
              },
            },
            ["image"] = {
              keymaps = {
                modes = {
                  i = "<C-i>",
                },
              },
              opts = {
                dirs = { "~/Documents/Screenshots" },
              },
            },
          },
        },
        inline = {
          adapter = {
            name = "copilot",
            model = "gpt-4.1", --"claude-sonnet-3",
          },
        },
      },
      display = {
        action_palette = {
          provider = "default",
        },
        chat = {
          auto_scroll = false,
          start_in_insert_mode = false,
          show_references = true,
          show_header_separator = true,
          show_settings = false,
          intro_message = "Enter your prompt here! Press ? for options",
        },
        diff = {
          provider = "default", -- "mini_diff"
        },
      },
    },
    keys = {
      -- General
      {
        "gi",
        function()
          if vim.bo.filetype == "codecompanion" then
            vim.cmd("normal! G")
            vim.cmd("startinsert!")
            vim.cmd("$put! =''")
          end
        end,
        mode = { "n" },
        desc = "Start prompt typing... (CodeCompanion)",
      },
      { "<leader>ia", "<cmd>CodeCompanionActions<cr>", mode = { "n", "v" }, desc = "Open Actions (CodeCompanion)" },
      { "<leader>ic", "<cmd>CodeCompanionCmd<cr>", mode = { "n", "v" }, desc = "Gen Neovim Command (CodeCompanion)" },

      -- Chat
      { "<leader>in", "<cmd>CodeCompanionChat<cr>", mode = { "n", "v" }, desc = "New Chat (CodeCompanion)" },
      { "<leader>ii", "<cmd>CodeCompanionChat Toggle<cr>", mode = { "n", "v" }, desc = "Toggle (CodeCompanion)" },
      {
        "go",
        function()
          local current_scrolloff = vim.o.scrolloff
          if current_scrolloff == 999 then
            vim.o.scrolloff = 0
          else
            vim.o.scrolloff = 999
          end
        end,
        mode = { "n" },
        desc = "Toggle scrolloff=999/0 (CodeCompanion)",
        ft = { "codecompanion" },
      },
      {
        "gt",
        function()
          vim.o.scrolloff = 0
          vim.cmd("normal! G")
          vim.fn.search("^## CodeCompanion (", "bW")
          vim.cmd("normal! zt")
        end,
        mode = { "n" },
        desc = "Goto Last Response (CodeCompanion)",
        ft = { "codecompanion" },
      },
      {
        "gn",
        function()
          vim.o.scrolloff = 0
          vim.cmd("call vimwiki#base#goto_next_header()")
          vim.cmd("normal! zt")
        end,
        mode = { "n" },
        desc = "Goto Next Header (CodeCompanion)",
        ft = { "codecompanion" },
      },
      {
        "<leader>gd",
        function()
          local CodeCompanion = require("codecompanion")
          local chat = CodeCompanion.last_chat()
          if not chat then
            chat = CodeCompanion.chat()
            vim.cmd("normal! 2o")
          else
            vim.cmd("CodeCompanionChat Add")
            vim.cmd("wincmd l")
            vim.cmd("normal! G")
            vim.cmd("normal! o")
          end
        end,
        mode = { "v" },
        desc = "Add Selection to Chat (CodeCompanion)",
      },
      {
        "gd",
        function()
          local CodeCompanion = require("codecompanion")
          local chat = CodeCompanion.last_chat()
          if not chat then
            chat = CodeCompanion.chat()
            vim.cmd("normal! 2o")
          else
            vim.cmd("CodeCompanionChat Add")
            vim.cmd("wincmd l")
            vim.cmd("normal! G")
            vim.cmd("normal! o")
          end
        end,
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
    init = function()
      vim.cmd([[cab cc CodeCompanion]])
      require("plugins.ai.codecompanion.spinner"):init()

      local group = vim.api.nvim_create_augroup("CodeCompanionEvents", { clear = true })
      vim.api.nvim_create_autocmd("User", {
        pattern = "CodeCompanionRequestStarted",
        group = group,
        callback = function()
          if vim.bo.filetype == "codecompanion" then
            vim.cmd("normal! zt")
          end
        end,
      })
    end,
    dependencies = {
      "j-hui/fidget.nvim", -- Display status
      "ravitemer/codecompanion-history.nvim", -- Save and load conversation history
      {
        "ravitemer/mcphub.nvim", -- Manage MCP servers
        enabled = false, -- TODO: Enable when MCPHub is ready
        cmd = "MCPHub",
        build = "npm install -g mcp-hub@latest",
        config = true,
      },
      {
        "HakonHarnes/img-clip.nvim", -- Share images with the chat buffer
        enabled = false,
        event = "VeryLazy",
        cmd = "PasteImage",
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
    },
  },
  {
    "folke/which-key.nvim",
    optional = true,
    opts = {
      spec = {
        { "<leader>a", group = "Avante" },
        { "<leader>i", group = "CodeCompanion" },
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
    enabled = false, -- TODO:
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
