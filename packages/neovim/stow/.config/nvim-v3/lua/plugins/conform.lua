return {
  "stevearc/conform.nvim",

  opts = function(_, opts)
    -- Preserve existing formatter configurations
    opts.formatters_by_ft = opts.formatters_by_ft or {}
    opts.formatters = opts.formatters or {}

    -- Configure C/C++ formatters
    opts.formatters_by_ft.c = { "clang_format" }
    opts.formatters_by_ft.cpp = { "clang_format" }

    -- Extend clang-format configuration
    opts.formatters.clang_format = vim.tbl_deep_extend("force", opts.formatters.clang_format or {}, {
      prepend_args = function(_, ctx)
        local root = vim.fn.expand("~/projects/code/42-projects")
        local filename = vim.api.nvim_buf_get_name(ctx.buf)
        if vim.startswith(filename, root .. "/") then
          return { "--style=file:" .. root .. "/.clang-format" }
        end
        return {}
      end,
    })
  end,
  keys = {
    {
      "<leader>cf",
      function()
        require("conform").format({ async = true, lsp_format = "never" })
      end,
      mode = { "n", "v" },
      desc = "Format code with Conform",
    },
  },
}
