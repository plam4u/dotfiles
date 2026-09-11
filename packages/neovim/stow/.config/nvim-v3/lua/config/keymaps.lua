-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

vim.keymap.set("n", "<leader>L", "<cmd>LazyExtras<CR>", { desc = "LazyExtras" })
vim.keymap.set("n", "<leader>se", function()
  vim.wo.scrollbind = not vim.wo.scrollbind
end, { desc = "Toggle scrollbind" })
