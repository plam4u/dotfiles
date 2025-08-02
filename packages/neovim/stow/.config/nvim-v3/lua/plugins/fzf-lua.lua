return {
  {
    "ibhagwan/fzf-lua",
    cmd = "FzfLua",
    opts = function(_, opts)
      local config = {
        files = { hidden = true },
        grep = { hidden = true },
      }
      return vim.tbl_deep_extend("force", opts, config)
    end,
    keys = {
      { "<leader>fF", LazyVim.pick("files"), desc = "Find Files (cwd)" },
      { "<leader>ff", LazyVim.pick("files", { root = false }), desc = "Find Files (Root dir)" },
      { "<leader>sg", LazyVim.pick("live_grep", { root = false }), desc = "Grep (cwd)" },
      { "<leader>/", LazyVim.pick("live_grep", { root = false }), desc = "Grep (cwd)" },
      { "<leader>sG", LazyVim.pick("live_grep"), desc = "Grep (Root Dir)" },
    },
  },
}
