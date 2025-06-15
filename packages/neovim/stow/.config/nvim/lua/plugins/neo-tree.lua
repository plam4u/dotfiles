return {
  "nvim-neo-tree/neo-tree.nvim",
  enabled = false,
  opts = {
    auto_clean_after_session_restore = true, -- Automatically clean up broken neo-tree buffers saved in sessions
    close_if_last_window = true, -- Close Neo-tree if it is the last window left in the tab
    window = {
      width = 30, -- applies to left and right positions
      auto_expand_width = true,
    },
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
