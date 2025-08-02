return {
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        texlab = {
          settings = {
            texlab = {
              build = {
                executable = "latexmk",
                args = { "-pdf", "-interaction=nonstopmode", "-synctex=1", "%f" },
                onSave = true,
              },
              forwardSearch = {
                executable = "open",
                args = { "-a", "Skim", "%p" },
              },
            },
          },
        },
        ltex = {
          filetypes = { "latex", "tex", "bib" },
          settings = {
            ltex = {
              enabled = { "latex", "tex", "bib" },
              language = "en-US",
              checkFrequency = "save",
              additionalRules = {
                enablePickyRules = true,
              },
            },
          },
        },
      },
    },
  },
  {
    "stevearc/conform.nvim",
    opts = {
      formatters_by_ft = {
        tex = { "latexindent" },
      },
      formatters = {
        latexindent = {
          prepend_args = { "-g", "/dev/null" }, -- Don't create log files
        },
      },
    },
  },
  {
    "williamboman/mason.nvim",
    opts = {
      ensure_installed = {
        "texlab",
        "ltex-ls",
        "latexindent",
      },
    },
  },
  -- {
  --   "neovim/nvim-lspconfig",
  --   opts = function()
  --     local keys = require("lazyvim.plugins.lsp.keymaps").get()
  --     -- Add LaTeX-specific keymaps
  --     vim.list_extend(keys, {
  --       { "<localleader>lb", "<cmd>TexlabBuild<cr>", desc = "Build LaTeX", ft = "tex" },
  --       { "<localleader>lf", "<cmd>TexlabForward<cr>", desc = "Forward Search", ft = "tex" },
  --     })
  --   end,
  -- },
}
