if vim.g.neovide then
  vim.g.neovide_input_macos_option_key_is_meta = "only_left"
  vim.opt.clipboard = "unnamedplus"
  vim.keymap.set({ "n", "v" }, "<D-v>", '"+p', { noremap = true, silent = true })
  vim.keymap.set("i", "<D-v>", "<C-r>+", { noremap = true, silent = true })
  vim.keymap.set("c", "<D-v>", function()
    vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<C-r>+", true, false, true), "n", false)
    vim.schedule(function()
      vim.cmd("redraw")
    end)
    return ""
  end, { expr = true })
end
