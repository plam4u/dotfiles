return {
  {
    "nvim-lualine/lualine.nvim",
    opts = function(_, opts)
      opts.options.component_separators = "|"
      opts.options.section_separators = ""
      -- show tmux session name in lualine in section z
      opts.sections.lualine_z = {
        function()
          local tmux_session = vim.fn.system("tmux display-message -p '#W:#S'")
          return " " .. tmux_session:gsub("%s+", "")
        end,
      }
      return opts
    end,
  },
}
