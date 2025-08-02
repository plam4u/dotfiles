return {
  {
    enabled = false,
    "vimwiki/vimwiki",
    init = function()
      vim.g.vimwiki_list = {
        {
          path = "~/notes/notes/",
          -- diary_rel_path = "../diary/",
          syntax = "markdown",
          ext = ".md",
        },
      }
    end,
    keys = {
      { "<Leader>ww", "<Plug>VimwikiIndex<CR>", desc = "Open Vimwiki Index", silent = true },
      { "<Leader>w<Leader>w", "<Plug>VimwikiDiaryIndex<CR>", desc = "Open Vimwiki Diary Index", silent = true },
      { "gl<Space>", "<Plug>VimwikiToggleListItem<CR>", desc = "Toggle Vimwiki List Item", silent = true },
    },
    -- config = function(_, _)
    --   vim.api.nvim_create_autocmd("LspAttach", {
    --     callback = function(args)
    --       -- print("LspAttach autocmd triggered for Vimwiki, bufnr = " .. args.buf)
    --       local client = vim.lsp.get_client_by_id(args.data.client_id) or {}
    --       local bufnr = args.buf
    --       local filetype = vim.bo[bufnr].filetype
    --       if filetype == "markdown" and client.name == "marksman" then
    --         vim.lsp.buf_detach_client(bufnr, client.id)
    --       end
    --     end,
    --   })
    -- end,
  },
  -- Disable diagnostics for marksman globally
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        marksman = {
          handlers = {
            ["textDocument/publishDiagnostics"] = function() end, -- Disable diagnostics
          },
        },
      },
    },
  },
}
