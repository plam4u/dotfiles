return {
  {
    "nvim-orgmode/orgmode",
    enabled = false, -- TODO: try later
    event = "VeryLazy",
    ft = { "org" },
    config = function()
      require("orgmode").setup({
        org_agenda_files = "~/notes/notes/orgmode/**/*",
        org_default_notes_file = "~/notes/notes/orgfiles/refile.org",
      })
    end,
  },
}
