return {
  "echasnovski/mini.files",
  opts = function(_, opts)
    local set_mark = function(id, path, desc)
      MiniFiles.set_bookmark(id, path, { desc = desc })
    end
    vim.api.nvim_create_autocmd("User", {
      pattern = "MiniFilesExplorerOpen",
      callback = function()
        set_mark("h", "~", "Home directory")
        set_mark("d", vim.fn.expand("~/dev"), "dev directory")
        set_mark("c", vim.fn.stdpath("config"), "Config")
        set_mark("w", vim.fn.getcwd, "Working directory")
      end,
    })
    return vim.tbl_deep_extend("force", opts or {}, {
      windows = {
        preview = false,
        width_focus = 35,
        width_nofocus = 15,
        width_preview = 25,
      },
      options = {
        -- Whether to use for editing directories
        -- Disabled by default in LazyVim because neo-tree is used for that
        use_as_default_explorer = true,
      },
    })
  end,
  keys = {
    -- Open the file explorer
    {
      "<leader>e",
      function()
        if not MiniFiles.close() then
          -- if not MiniFiles.is_open() then
          if MiniFiles.get_latest_path() == nil then
            MiniFiles.open(vim.fn.expand("%:p:h"), nil, vim.g.mf_custom_state)
          else
            MiniFiles.open(MiniFiles.get_latest_path(), nil, vim.g.mf_custom_state)
          end
        else
          MiniFiles.close()
        end
      end,
      desc = "Open file explorer",
    },
    -- -- Open the file explorer in current directory
    -- {
    --   "<leader>e",
    --   function()
    --     require("mini.files").open(vim.fn.expand("%:p:h"))
    --   end,
    --   desc = "Open file explorer in current directory",
    -- },
    {
      "gP",
      function()
        local config = require("mini.files").config
        config.windows.preview = not config.windows.preview
        MiniFiles.refresh({ windows = { preview = config.windows.preview } })
      end,
      ft = "minifiles",
      desc = "Toggle preview",
    },
    {
      "gp",
      function()
        vim.g.mf_custom_state = vim.g.mf_custom_state or { windows = { preview = false, width_preview = 0 } }
        local state = vim.g.mf_custom_state
        if not state.windows.preview then
          state.windows = { preview = true, width_preview = 25 }
        elseif state.windows.width_preview == 25 then
          state.windows = { preview = true, width_preview = 70 }
        elseif state.windows.width_preview == 70 then
          state.windows = { preview = false, width_preview = 0 }
        end
        MiniFiles.refresh(state)
        if not state.windows.preview then
          MiniFiles.trim_right()
        end
        vim.g.mf_custom_state = state
      end,
      ft = "minifiles",
      desc = "Cycle preview width",
    },
    { "P", "gp", ft = "minifiles", desc = "Cycle preview width" },
    {
      "gy",
      function()
        local path = (MiniFiles.get_fs_entry() or {}).path
        if path == nil then
          return vim.notify("Cursor is not on valid entry")
        end
        vim.fn.setreg(vim.v.register, path)
      end,
      ft = "minifiles",
      desc = "Yank path",
    },
    {
      "go",
      function()
        vim.ui.open(MiniFiles.get_fs_entry().path)
      end,
      ft = "minifiles",
      desc = "OS open",
    },
  },
}
