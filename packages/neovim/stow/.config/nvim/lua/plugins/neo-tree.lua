return {
  "nvim-neo-tree/neo-tree.nvim",
  opts = {
    filesystem = {
      filtered_items = {
        visible = true, -- Show filtered (hidden) items by default
        show_hidden_count = true,
        hide_dotfiles = true, -- Do not hide dotfiles (show them)
        hide_gitignored = true, -- Do not hide gitignored files
      },
    },
  },
}
