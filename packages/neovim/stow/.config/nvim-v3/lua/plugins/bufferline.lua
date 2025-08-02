local function toggle_bufferline()
  if vim.o.showtabline == 0 then
    vim.o.showtabline = 2
  else
    vim.o.showtabline = 0
  end
end

-- Create a command
vim.api.nvim_create_user_command("BufferLineToggle", toggle_bufferline, {})

-- Or bind to a key
vim.keymap.set("n", "<leader>bt", toggle_bufferline, { desc = "Toggle bufferline" })
local bufferline = require("bufferline")
return {
  {
    "akinsho/bufferline.nvim",
    opts = {
      options = {
        style_preset = bufferline.style_preset.minimal, -- or bufferline.style_preset.minimal,
      },
    },
  },
}
