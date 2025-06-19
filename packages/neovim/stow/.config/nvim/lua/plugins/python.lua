local icons = LazyVim.config.icons

return {
  { "theHamsta/nvim-dap-virtual-text", enabled = false },
  {
    "mfussenegger/nvim-dap",
    keys = {
      { "<leader>do", false },
      { "<leader>dO", false },
      {
        "<leader>dO",
        function()
          require("dap").step_out()
        end,
        desc = "Step Out",
      },
      {
        "<leader>do",
        function()
          require("dap").step_over()
        end,
        desc = "Step Over",
      },
      {
        "<leader>dd",
        function()
          local dap = require("dap")
          local lines =
            vim.fn.getregion(vim.fn.getpos("."), vim.fn.getpos("v"), { type = vim.api.nvim_get_mode().mode })
          dap.repl.open()
          dap.repl.execute(table.concat(lines, "\n"))
          vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Esc>", true, false, true), "n", false)
        end,
        desc = "Execute selection",
        mode = "x",
      },
      -- { "<leader>dr", function() require("dap").repl.toggle() end, desc = "Toggle REPL", },
      -- { "<leader>dr", false },
      {
        "<C-e>",
        function()
          require("dap").repl.execute(".clear")
        end,
        mode = "i",
        desc = "Clear REPL",
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
      {
        "<leader>d1",
        function()
          local dap = require("dap")
          dap.run(dap.configurations.python[1])
        end,
        desc = "Run Config 1",
      },
      {
        "<leader><leader>d",
        function()
          local dap = require("dap")
          dap.run_last()
        end,
        desc = "Run Last Config",
      },
    },
  },
  {
    "rcarriga/nvim-dap-ui",
    opts = function(_, _)
      -- prevent debugger from showing on debug session start
      -- local dap = require("dap")
      -- dap.listeners.after.event_initialized["dapui_config"] = function() end

      return {
        layouts = {
          {
            elements = {
              { id = "scopes", size = 0.7 }, -- 40% of left panel
              { id = "breakpoints", size = 0.1 }, -- 20% of left panel
              { id = "stacks", size = 0.1 }, -- 20% of left panel
              { id = "watches", size = 0.1 }, -- 20% of left panel
            },
            size = 40,
            position = "left",
          },
          {
            elements = {
              "repl",
              "console",
            },
            size = 0.25,
            position = "bottom",
          },
        },
      }
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
    keys = {
      {
        "q",
        function()
          vim.api.nvim_win_close(0, false)
        end,
        desc = "Close DAP UI window",
        ft = "dap-float",
      },
      {
        "<CR>",
        function()
          local line = vim.api.nvim_get_current_line()
          -- Strip the "dap> " prompt if present
          local command = line:gsub("^dap> ", "")
          if command ~= "" then
            -- Move to the end of the line and simulate insert mode Enter
            vim.api.nvim_win_set_cursor(0, { vim.api.nvim_win_get_cursor(0)[1], #line })
            vim.api.nvim_feedkeys("a\n", "n", false)
          end
        end,
        desc = "Execute REPL entry",
        ft = "dap-repl",
        mode = "n",
      },
      {
        "<leader>dK",
        function()
          require("dap.ui.widgets").hover()
        end,
        desc = "Hover",
      },
      {
        "<leader>df",
        function()
          local dap_elements = {
            { name = "Console", element = "console", desc = "DAP protocol messages" },
            { name = "REPL", element = "repl", desc = "Interactive debugging console" },
            { name = "Scopes", element = "scopes", desc = "Variable scopes (local/global)" },
            { name = "Breakpoints", element = "breakpoints", desc = "Breakpoint list" },
            { name = "Stacks", element = "stacks", desc = "Call stack" },
            { name = "Watches", element = "watches", desc = "Watch expressions" },
          }

          vim.ui.select(dap_elements, {
            prompt = "Select DAP UI widget to float:",
            format_item = function(item)
              return string.format("%s - %s", item.name, item.desc)
            end,
          }, function(choice)
            if choice then
              require("dapui").float_element(choice.element, {
                title = choice.name,
                width = 100,
                height = 30,
                enter = true,
                position = "center",
              })
            end
          end)
        end,
        desc = "Float DAP UI widget",
      },
      { "<leader>dw", "<leader>df", mode = "n", remap = true, desc = "Float DAP UI widget" },
    },
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
