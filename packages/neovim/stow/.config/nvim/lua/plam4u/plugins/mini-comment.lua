return {
    "echasnovski/mini.comment",
    event = "VeryLazy",
    config = function(_, opts)
        require("mini.comment").setup(opts)
    end,
}
