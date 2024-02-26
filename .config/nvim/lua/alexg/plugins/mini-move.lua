local minimove_config = function()
    local opts = {
        -- Module mappings. Use `''` (empty string) to disable one.
        mappings = {
            -- Move visual selection in Visual mode. Defaults are Alt (Meta) + hjkl.
            left = '<left>',
            right = '<right>',
            down = '<down>',
            up = '<up>',

            -- Move current line in Normal mode
            line_left = '<left>',
            line_right = '<right>',
            line_down = '<down>',
            line_up = '<up>',
        },

        -- Options which control moving behavior
        options = {
            -- Automatically reindent selection during linewise vertical move
            reindent_linewise = true,
        },
    }
    require('mini.move').setup(opts)
end
return { 'echasnovski/mini.move', version = '*' , config = minimove_config}
