vim.opt_local.tabstop = 4
vim.opt_local.shiftwidth = 4
vim.opt_local.softtabstop = 4
vim.opt_local.expandtab = false

vim.opt.list = false
vim.opt.listchars = {
  tab = "→ ",
  space = "·",
  trail = "•",
  eol = "↵",
}

vim.keymap.set("n", "<leader>dx", function()
  local file = vim.fn.expand("%:p")
  local output = vim.fn.expand("%:p:r")

  local result = vim.fn.system({
    "clang",
    "-g",
    "-O0",
    "-Wall",
    "-Wextra",
    "-Werror",
    file,
    "-o",
    output,
  })

  if vim.v.shell_error ~= 0 then
    vim.notify(result, vim.log.levels.ERROR)
    return
  end

  require("dap").run({
    type = "codelldb",
    request = "launch",
    name = "Debug current C file",
    program = output,
    cwd = vim.fn.getcwd(),
    stopOnEntry = false,
    terminal = "integrated",
  })
end, {
  buffer = true,
  desc = "Compile and debug current C file",
})
