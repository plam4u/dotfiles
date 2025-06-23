return {
  "nvim-neo-tree/neo-tree.nvim",
  enabled = true,
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
      follow_current_file = {
        enabled = false, -- This will find and focus the file in the active buffer every time
        --               -- the current file is changed while the tree is open.
        leave_dirs_open = false, -- `false` closes auto expanded dirs, such as with `:Neotree reveal`
      },
    },
  },
}
