require("lspconfig").lua_ls.setup({
  settings = {
    Lua = {
      runtime = {
        version = "LuaJIT",
        special = {
          ["love.filesystem.load"] = "loadfile",
        },
      },
      workspace = {
        library = {
          vim.fn.expand("~/.local/share/LuaAddons/love2d/"),
        },
        checkThirdParty = false,
      },
      diagnostics = {
        globals = { "love" },
        disable = { "duplicate-set-field" },
      },
    },
  },
})
