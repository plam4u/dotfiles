return {
  {
    "vimwiki/vimwiki",
    config = function(_, _)
      vim.api.nvim_create_autocmd("LspAttach", {
        callback = function(args)
          -- print("LspAttach autocmd triggered for Vimwiki, bufnr = " .. args.buf)
          local client = vim.lsp.get_client_by_id(args.data.client_id) or {}
          local bufnr = args.buf
          local filetype = vim.bo[bufnr].filetype
          if filetype == "markdown" and client.name == "marksman" then
            vim.lsp.buf_detach_client(bufnr, client.id)
          end
        end,
      })
    end,
    -- FileType is triggered too early (before LSP is attached)
    --   vim.api.nvim_create_autocmd("FileType", {
    --     pattern = "vimwiki",
    --     callback = function()
    --       print("Vimwiki filetype detected, setting up LSP client..., bufnr = " .. vim.api.nvim_get_current_buf())
    --       local clients = vim.lsp.get_clients()
    --       for _, client in ipairs(clients) do
    --         if client.name == "marksman" then
    --           vim.lsp.buf_detach_client(0, client.id)
    --           return true
    --         end
    --       end
    --       return false
    --     end,
    --   })
    -- end,
    init = function()
      -- Configure Vimwiki options
      vim.g.vimwiki_list = {
        { path = "~/notes/notes/", syntax = "markdown", ext = ".md" },
      }

      -- Optional: Set key bindings
      -- Set <Leader>ww to open the Vimwiki index page
      vim.api.nvim_set_keymap("n", "<Leader>ww", "<Plug>VimwikiIndex<CR>", { noremap = true, silent = true })
      vim.api.nvim_set_keymap("n", "gl<Space>", "<Plug>VimwikiToggleListItem<CR>", { noremap = true, silent = true })
    end,
  },
  -- Disable diagnostics for marksman globally
  -- {
  --   "neovim/nvim-lspconfig",
  --   opts = {
  --     servers = {
  --       marksman = {
  --         handlers = {
  --           ["textDocument/publishDiagnostics"] = function() end, -- Disable diagnostics
  --         },
  --       },
  --     },
  --   },
  -- },
}
