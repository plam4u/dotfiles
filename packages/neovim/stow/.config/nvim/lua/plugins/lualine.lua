return {
  {
    "nvim-lualine/lualine.nvim",
    opts = function(_, opts)
      opts.options.component_separators = "|"
      opts.options.section_separators = ""

      local tmux_session = ""
      opts.sections.lualine_z = {
        function()
          if tmux_session == "" and vim.env.TMUX then
            local result = vim.fn.system("tmux display-message -p '#W:#S' 2>/dev/null")
            if vim.v.shell_error == 0 then
              tmux_session = " " .. result:gsub("%s+", "")
            else
              tmux_session = "no-session"
            end
          end
          return tmux_session
        end,
      }

      return opts
    end,
  },
}
