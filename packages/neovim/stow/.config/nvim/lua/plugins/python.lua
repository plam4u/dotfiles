local icons = LazyVim.config.icons

return {
  { "theHamsta/nvim-dap-virtual-text", enabled = false },
  {
    "mfussenegger/nvim-dap",
    keys = {
      {
        "<leader>dd",
        function()
          local dap = require("dap")
          local lines =
            vim.fn.getregion(vim.fn.getpos("."), vim.fn.getpos("v"), { type = vim.api.nvim_get_mode().mode })
          dap.repl.open()
          dap.repl.execute(table.concat(lines, "\n"))
        end,
        desc = "Execute selection",
        mode = "x",
      },
      {
        "<leader>dR",
        function()
          require("dap").repl.execute(".clear")
        end,
        desc = "Clear REPL",
      },
      {
        "<leader>d1",
        function()
          local dap = require("dap")
          dap.run(dap.configurations.python[1])
        end,
        desc = "Run Config 1",
      },
      {
        "<leader>d2",
        function()
          local dap = require("dap")
          dap.run(dap.configurations.python[2])
        end,
        desc = "Run Config 2",
      },
      {
        "<leader>d3",
        function()
          local dap = require("dap")
          dap.run(dap.configurations.python[3])
        end,
        desc = "Run Config 3",
      },
      {
        "<leader>d4",
        function()
          local dap = require("dap")
          dap.run(dap.configurations.python[4])
        end,
        desc = "Run Config 4",
      },
      {
        "<leader>d5",
        function()
          local dap = require("dap")
          dap.run(dap.configurations.python[5])
        end,
        desc = "Run Config 5",
      },
      { "<leader>dL", ":luafile %<cr>", desc = "Reload Launch File" },
    },
  },
  {
    "rcarriga/nvim-dap-ui",
    opts = function(_, _)
      local dap = require("dap")
      dap.listeners.after.event_initialized["dapui_config"] = function() end
    end,

    config = function(_, opts)
      local dap = require("dap")
      local dapui = require("dapui")
      dapui.setup(opts)
      dap.listeners.after.event_initialized["dapui_config"] = function()
        -- dapui.open({})
      end
      dap.listeners.before.event_terminated["dapui_config"] = function()
        dapui.close({})
      end
      dap.listeners.before.event_exited["dapui_config"] = function()
        dapui.close({})
      end
    end,
  },
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
