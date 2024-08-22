return {
    'nvim-telescope/telescope.nvim',
    cmd = 'Telescope',
    lazy = true,
    dependencies = {
		'andrew-george/telescope-themes',
    },
    config = function()
	    -- load extension
	    local telescope = require('telescope')
	    telescope.load_extension('themes')
    end
}
