-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
-- Add any additional autocmds here

local function augroup(name)
  return vim.api.nvim_create_augroup("lazyvim_" .. name, { clear = true })
end

-- restore last session for current directory
vim.api.nvim_create_autocmd("VimEnter", {
  callback = function()
    require("persistence").load()
  end,
})
-- delete empty buffers after session restoration
vim.api.nvim_create_autocmd("User", {
  pattern = "SessionLoadPost",
  callback = function()
    for _, buf in ipairs(vim.api.nvim_list_bufs()) do
      if vim.fn.bufname(buf) == "" then
        vim.api.nvim_buf_delete(buf, { force = true })
      end
    end
  end,
})

-- load local lua settings (e.g. config a python debugger)
vim.api.nvim_create_autocmd("VimEnter", {
  callback = function()
    local project_launch = vim.fn.getcwd() .. "/.nvim/launch.lua"
    if vim.fn.filereadable(project_launch) == 1 then
      dofile(project_launch)
    end
  end,
})

-- highlight on yank
vim.api.nvim_create_autocmd("TextYankPost", {
  group = augroup("highlight_yank"),
  callback = function()
    (vim.hl or vim.highlight).on_yank({ timeout = 50 }) -- 50 ms, very quick!
  end,
})

-- wrap and check for spell in text filetypes
vim.api.nvim_create_autocmd("FileType", {
  group = augroup("wrap_spell"),
  pattern = { "text", "plaintex", "typst", "gitcommit", "markdown" },
  callback = function()
    vim.opt_local.wrap = true
    vim.opt_local.spell = false
  end,
})
