return {
    "vimwiki/vimwiki",
    init = function()
        -- Configure Vimwiki options
        vim.g.vimwiki_list = {
            { path = "~/notes/notes/", syntax = "markdown", ext = ".md" },
        }

        -- Optional: Set key bindings
        -- Set <Leader>ww to open the Vimwiki index page
        vim.api.nvim_set_keymap('n', '<Leader>ww', ':VimwikiIndex<CR>', { noremap = true, silent = true })
    end,
}
