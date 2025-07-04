if true then
  return {}
end

return {
  { dir = "~/git/LamboLSP" },
  { dir = "~/plugins/boot.nvim" },
  { dir = "~/plugins/present.nvim" },
  { dir = "~/git/tree-sitter-cram" },
  { dir = "~/plugins/chat-llm.nvim" },
  -- { dir = "~/plugins/css.nvim/" },
  { dir = "~/plugins/php.nvim/" },
  -- { "CWood-sdf/banana.nvim" },
  { dir = "~/plugins/two-idiots-one-keyboard.nvim/" },
  {
    dir = "~/plugins/luai",
    config = function()
      local parsed = require("custom.dotenv").parse_plugin_env()
      if not parsed.ANTHROPIC_TOKEN then
        return
      end

      require("luai").setup {
        token = parsed.ANTHROPIC_TOKEN,
      }
    end,
  },
  { dir = "~/plugins/misery.nvim/plugins/misery.nvim" },
  { "iwillreku3206/websocket.nvim" },
}
