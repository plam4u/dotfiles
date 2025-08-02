return {
  {
    "neovim/nvim-lspconfig",
    opts = function()
      local lspconfig = require("lspconfig")
      lspconfig.lua_ls.setup({
        settings = {
          Lua = {
            workspace = {
              -- Path to your Addons directory
              userThirdParty = { os.getenv("HOME") .. "/.local/share/LuaAddons" },
              checkThirdParty = "Apply",
            },
          },
        },
      })
    end,
  },
}
