return {
  "stevearc/conform.nvim",

  opts = function(_, opts)
    -- Preserve existing formatter configurations
    opts.formatters_by_ft = opts.formatters_by_ft or {}
    opts.formatters = opts.formatters or {}

    -- Register the 42-specific formatter
    opts.formatters.c_formatter_42 = {
      command = "c_formatter_42",
      stdin = true,
    }

    -- Check whether a buffer belongs to your 42 projects
    local root = vim.fn.expand("~/projects/code/42-projects")
    local function is_42_project(bufnr)
      local filename = vim.api.nvim_buf_get_name(bufnr)
      return vim.startswith(filename, root .. "/")
    end

    -- Select formatter depending on project location
    opts.formatters_by_ft.c = function(bufnr)
      if is_42_project(bufnr) then
        return { "c_formatter_42" }
      end

      return { "clang_format" }
    end

    -- Preserve existing clang-format settings
    -- No custom style path needed for c_formatter_42
  end,

  keys = {
    {
      "<leader>cf",
      function()
        require("conform").format({
          async = true,
          lsp_format = "never",
        })
      end,
      mode = { "n", "v" },
      desc = "Format code with Conform",
    },
  },
}
