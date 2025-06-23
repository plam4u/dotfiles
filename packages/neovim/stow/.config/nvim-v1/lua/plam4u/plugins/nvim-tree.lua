local status_ok, icons = pcall(require, "plam4u.config.icons")
if not status_ok then
    return
end

return {
    "nvim-tree/nvim-tree.lua",
    lazy = false,
    keys = {
	    { "<leader>e", "<cmd>NvimTreeToggle<cr>", desc = "Toggle NvimTree" },
    },
    opts = {
        auto_reload_on_write = false,
        disable_netrw = false,
        hijack_cursor = false,
        hijack_netrw = true,
        hijack_unnamed_buffer_when_opening = false,
        ignore_buffer_on_setup = false,
        sort_by = "name",
        root_dirs = {},
        prefer_startup_root = false,
        sync_root_with_cwd = true,
        reload_on_bufenter = false,
        respect_buf_cwd = false,
        on_attach = "disable",
        remove_keymaps = false,
        select_prompts = false,
        view = {
            adaptive_size = false,
            centralize_selection = true,
            width = 40,
            hide_root_folder = false,
            side = "left",
            preserve_window_proportions = false,
            number = false,
            relativenumber = false,
            signcolumn = "yes",
            mappings = {
                custom_only = false,
                list = {
                    { key = { "l", "<CR>", "o" }, action = "edit", mode = "n" },
                    { key = "h", action = "close_node" },
                    { key = "v", action = "vsplit" },
                    { key = "C", action = "cd" },
                    { key = "<C-e>", action = "" },
                    { key = "<esc>", action = "<cmd>NvimTreeClose<cr>" },
                    -- { key = "gtf",                action = "telescope_find_files", action_cb = telescope_find_files },
                    -- { key = "gtg",                action = "telescope_live_grep",  action_cb = telescope_live_grep },
                },
            },
            float = {
                enable = false,
                quit_on_focus_loss = true,
                open_win_config = function()
                    local HEIGHT_RATIO = 0.85  -- You can change this
                    local WIDTH_RATIO = 0.5   -- You can change this too

                    local screen_w = vim.opt.columns:get()
                    local screen_h = vim.opt.lines:get() - vim.opt.cmdheight:get()
                    local window_w = screen_w * WIDTH_RATIO
                    local window_h = screen_h * HEIGHT_RATIO
                    local window_w_int = math.floor(window_w)
                    local window_h_int = math.floor(window_h)
                    local center_x = (screen_w - window_w) / 2
                    local center_y = ((vim.opt.lines:get() - window_h) / 2)
                    - vim.opt.cmdheight:get()
                    return {
                        border = 'rounded',
                        relative = 'editor',
                        row = center_y,
                        col = center_x,
                        width = window_w_int,
                        height = window_h_int,
                    }
                end,
                -- open_win_config = {
                --     relative = "editor",
                --     border = "rounded",
                --     width = 30,
                --     height = 30,
                --     row = 1,
                --     col = 1,
                -- },
            },
        },
        renderer = {
            add_trailing = false,
            group_empty = false,
            highlight_git = true,
            full_name = false,
            highlight_opened_files = "none",
            root_folder_label = ":t",
            indent_width = 2,
            indent_markers = {
                enable = false,
                inline_arrows = true,
                icons = {
                    corner = "└",
                    edge = "│",
                    item = "│",
                    none = " ",
                },
            },
            icons = {
                webdev_colors = true,
                git_placement = "after",
                padding = " ",
                symlink_arrow = " ➛ ",
                show = {
                    file = true,
                    folder = true,
                    folder_arrow = true,
                    git = false,
                },
                glyphs = {
                    default = icons.ui.Text,
                    symlink = icons.ui.FileSymlink,
                    bookmark = icons.ui.BookMark,
                    folder = {
                        arrow_closed = icons.ui.TriangleShortArrowRight,
                        arrow_open = icons.ui.TriangleShortArrowDown,
                        default = icons.ui.Folder,
                        open = icons.ui.FolderOpen,
                        empty = icons.ui.EmptyFolder,
                        empty_open = icons.ui.EmptyFolderOpen,
                        symlink = icons.ui.FolderSymlink,
                        symlink_open = icons.ui.FolderOpen,
                    },
                    git = {
                        unstaged = icons.git.FileUnstaged,
                        staged = icons.git.FileStaged,
                        unmerged = icons.git.FileUnmerged,
                        renamed = icons.git.FileRenamed,
                        untracked = icons.git.FileUntracked,
                        deleted = icons.git.FileDeleted,
                        ignored = icons.git.FileIgnored,
                    },
                },
            },
            special_files = { "Cargo.toml", "Makefile", "README.md", "readme.md" },
            symlink_destination = true,
        },
        hijack_directories = {
            enable = false,
            auto_open = true,
        },
        update_focused_file = {
            enable = true,
            debounce_delay = 15,
            update_root = true,
            ignore_list = {},
        },
        diagnostics = {
            enable = true,
            show_on_dirs = false,
            show_on_open_dirs = true,
            debounce_delay = 50,
            severity = {
                min = vim.diagnostic.severity.HINT,
                max = vim.diagnostic.severity.ERROR,
            },
            icons = {
                hint = icons.diagnostics.BoldHint,
                info = icons.diagnostics.BoldInformation,
                warning = icons.diagnostics.BoldWarning,
                error = icons.diagnostics.BoldError,
            },
        },
        filters = {
            dotfiles = false,
            git_clean = false,
            no_buffer = false,
            custom = { "node_modules", "\\.cache" },
            exclude = {},
        },
        filesystem_watchers = {
            enable = true,
            debounce_delay = 50,
            ignore_dirs = {},
        },
        git = {
            enable = true,
            ignore = false,
            show_on_dirs = true,
            show_on_open_dirs = true,
            timeout = 200,
        },
        actions = {
            use_system_clipboard = true,
            change_dir = {
                enable = false,
                global = false,
                restrict_above_cwd = false,
            },
            expand_all = {
                max_folder_discovery = 300,
                exclude = {},
            },
            file_popup = {
                open_win_config = {
                    col = 1,
                    row = 1,
                    relative = "cursor",
                    border = "shadow",
                    style = "minimal",
                },
            },
            open_file = {
                quit_on_open = false,
                resize_window = false,
                window_picker = {
                    enable = true,
                    picker = "default",
                    chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890",
                    exclude = {
                        filetype = { "notify", "lazy", "qf", "diff", "fugitive", "fugitiveblame" },
                        buftype = { "nofile", "terminal", "help" },
                    },
                },
            },
            remove_file = {
                close_window = true,
            },
        },
        trash = {
            cmd = "trash",
            require_confirm = true,
        },
        live_filter = {
            prefix = "[FILTER]: ",
            always_show_folders = true,
        },
        tab = {
            sync = {
                open = false,
                close = false,
                ignore = {},
            },
        },
        notify = {
            threshold = vim.log.levels.INFO,
        },
        log = {
            enable = false,
            truncate = false,
            types = {
                all = false,
                config = false,
                copy_paste = false,
                dev = false,
                diagnostics = false,
                git = false,
                profile = false,
                watcher = false,
            },
        },
        system_open = {
            cmd = nil,
            args = {},
        },

    },
    dependencies = { "nvim-tree/nvim-web-devicons" },
}

