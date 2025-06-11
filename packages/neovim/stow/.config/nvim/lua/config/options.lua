-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here

vim.g.snacks_animate = false
vim.opt.spell = false
vim.g.ai_cmp = true
vim.o.scrolloff = 1
vim.g.copilot_telemetry = 0

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
