local telescope_config = {
    pickers = {
        find_files = {
            theme = "dropdown",
        },
    }
}
local telescope = {
    'nvim-telescope/telescope.nvim',
    tag = '0.1.8',
    dependencies = {
        'nvim-lua/plenary.nvim',
    },
    lazy = false,
}

return telescope
