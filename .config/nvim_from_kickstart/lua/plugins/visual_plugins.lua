return {
    -- Colorscheme
    {
        "rebelot/kanagawa.nvim",
        lazy = false,         -- make sure we load this during startup if it is your main colorscheme
        priority = 1000,      -- make sure to load this before all the other start plugins
        opts = {
            compile = false,  -- enable compiling the colorscheme
            undercurl = true, -- enable undercurls
            commentStyle = { italic = true },
            functionStyle = {},
            keywordStyle = { italic = true },
            statementStyle = { bold = true },
            typeStyle = {},
            transparent = false,   -- do not set background color
            dimInactive = true,    -- dim inactive window `:h hl-NormalNC`
            terminalColors = true, -- define vim.g.terminal_color_{0,17}
            colors = {             -- add/modify theme and palette colors
                palette = {},
                theme = { wave = {}, lotus = {}, dragon = {}, all = {} },
            },
            overrides = function(colors) -- add/modify highlights
                return {}
            end,
            theme = "wave",    -- Load "wave" theme when 'background' option is not set
            background = {     -- map the value of 'background' option to a theme
                dark = "wave", -- try "dragon" !
                light = "lotus"
            },
        },
        config = function()
            vim.cmd([[colorscheme kanagawa]])
        end,
    },

    -- Status Line
    {
        'echasnovski/mini.statusline',
        version = false,
        config = function()
            require('mini.statusline').setup({
                use_icons = vim.g.have_nerd_font,
            })
            require('mini.statusline').section_location = function()
                return string.format(' %s:%s ', vim.fn.line('.'), vim.fn.col('.'))
            end
        end,
    },
}
