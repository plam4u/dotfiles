-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

vim.keymap.set("n", "<leader>mr", function()
  vim.cmd("normal! qa")
end, { desc = "Start Macro Recording" })
vim.keymap.set("n", "<leader>ms", function()
  vim.cmd("normal! q")
end, { desc = "Stop Macro Recording" })
