-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
-- Add any additional autocmds here

vim.api.nvim_create_autocmd("VimEnter", {
  callback = function()
    local project_launch = vim.fn.getcwd() .. "/.nvim/launch.lua"
    if vim.fn.filereadable(project_launch) == 1 then
      dofile(project_launch)
    end
  end,
})

vim.api.nvim_create_autocmd("TextYankPost", {
  group = vim.api.nvim_create_augroup("lazyvim_highlight_yank", { clear = true }),
  callback = function()
    (vim.hl or vim.highlight).on_yank({ timeout = 50 }) -- 50 ms, very quick!
  end,
})
