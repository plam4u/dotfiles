return {
  "echasnovski/mini.files",
  opts = function(_, opts)
    local root_dir = vim.uv.cwd()
    local set_mark = function(id, path, desc)
      MiniFiles.set_bookmark(id, path, { desc = desc })
    end
    vim.api.nvim_create_autocmd("User", {
      pattern = "MiniFilesExplorerOpen",
      callback = function()
        set_mark("h", "~", "Home directory")
        set_mark("d", vim.fn.expand("~/dev"), "Projects (~/dev)")
        set_mark("c", vim.fn.stdpath("config"), "Config")
        set_mark("w", vim.fn.getcwd, "Working directory")
        set_mark("r", root_dir, "Shell start dir")
      end,
    })
    return vim.tbl_deep_extend("force", opts or {}, {
      windows = {
        preview = true,
        width_focus = 35,
        width_nofocus = 15,
        width_preview = 70,
      },
      options = {
        -- Whether to use for editing directories
        -- Disabled by default in LazyVim because neo-tree is used for that
        use_as_default_explorer = true,
      },
      mappings = {
        close = "q",
        go_in = "L",
        go_in_plus = "l",
        go_out = "h",
        go_out_plus = "H",
        mark_goto = "'",
        mark_set = "m",
        reset = "<BS>",
        reveal_cwd = "@",
        show_help = "g?",
        synchronize = "=",
        trim_left = "<",
        trim_right = ">",
      },
    })
  end,
  keys = {
    -- Open the file explorer
    {
      "<leader>r",
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
    {
      "<leader>fm",
      function()
        require("mini.files").open(vim.api.nvim_buf_get_name(0), true, vim.g.mf_custom_state)
      end,
      desc = "Open mini.files (Directory of Current File)",
    },
    {
      "<leader>fM",
      function()
        require("mini.files").open(vim.uv.cwd(), true, vim.g.mf_custom_state)
      end,
      desc = "Open mini.files (cwd)",
    },
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
        vim.g.mf_custom_state = vim.g.mf_custom_state or { windows = { preview = true, width_preview = 70 } }
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
    {
      "<C-s>",
      function()
        MiniFiles.synchronize()
      end,
      ft = "minifiles",
      desc = "Synchronize",
    },
  },
}
