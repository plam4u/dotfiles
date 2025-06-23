return {
    "akinsho/bufferline.nvim",
    event = "VeryLazy",
    keys = {
        { "<leader>bp", "<Cmd>BufferLineTogglePin<CR>",            desc = "Toggle pin" },
        { "<leader>bP", "<Cmd>BufferLineGroupClose ungrouped<CR>", desc = "Delete non-pinned buffers" },
    },
    opts = {
        options = {
            diagnostics = "nvim_lsp",
            always_show_bufferline = false,
            diagnostics_indicator = function(_, _, diag)
                local icons = require("plam4u.config.icons").diagnostics
                local ret = (diag.error and icons.Error .. diag.error .. " " or "")
                    .. (diag.warning and icons.Warning .. diag.warning or "")
                return vim.trim(ret)
            end,
            offsets = {
                {
                    filetype = "neo-tree",
                    text = "Neo-tree",
                    highlight = "Directory",
                    text_align = "left",
                },
            },
        },
    },
}
