return {
  "mfussenegger/nvim-dap",

  dependencies = {
    "rcarriga/nvim-dap-ui",
  },

  config = function()
    local dap = require("dap")

    local codelldb = vim.fn.stdpath("data") .. "/mason/bin/codelldb"

    dap.adapters.codelldb = {
      type = "server",
      port = "${port}",
      executable = {
        command = codelldb,
        args = { "--port", "${port}" },
      },
    }

    dap.configurations.c = {
      {
        name = "Debug C executable",
        type = "codelldb",
        request = "launch",

        program = function()
          return vim.fn.input("Executable: ", vim.fn.getcwd() .. "/", "file")
        end,

        cwd = "${workspaceFolder}",
        stopOnEntry = false,
      },
    }

    dap.configurations.cpp = dap.configurations.c
  end,
}
