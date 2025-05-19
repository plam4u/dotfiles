local icons = LazyVim.config.icons

return {
  {
    "nvim-lualine/lualine.nvim",
    opts = {
      sections = {
        lualine_c = {
          LazyVim.lualine.root_dir(),
          {
            "diagnostics",
            symbols = {
              error = icons.diagnostics.Error,
              warn = icons.diagnostics.Warn,
              info = icons.diagnostics.Info,
              hint = icons.diagnostics.Hint,
            },
          },
          { "filetype", icon_only = true, separator = "", padding = { left = 1, right = 0 } },
          { LazyVim.lualine.pretty_path() },
          {
            function()
              local venv = os.getenv("VIRTUAL_ENV")
              local python_bin = "python"
              if venv then
                python_bin = venv .. "/bin/python"
              end
              local handle = io.popen(python_bin .. " --version 2>&1")
              if handle then
                local result = handle:read("*a") or ""
                handle:close()
                local version = result:match("Python%s+([%d%.]+)")
                if version then
                  return " " .. version
                end
              end
              return ""
            end,
            cond = function()
              return vim.bo.filetype == "python"
            end,
          },
        },
      },
    },
  },
}
