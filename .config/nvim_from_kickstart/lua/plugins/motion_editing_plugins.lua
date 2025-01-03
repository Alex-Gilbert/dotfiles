return {
    -- Surround
    {
        "kylechui/nvim-surround",
        version = "*", -- Use for stability; omit to use `main` branch for the latest features
        event = "VeryLazy",
        opts = { keymaps = require("alex-config.keymaps").surround_keys },
    },

    -- Mini Move
    {
        'echasnovski/mini.move',
        version = '*',
        opts = {
            mappings = require('alex-config.keymaps').mini_move_keys,
            options = {
                reindent_linewise = true,
            },
        },
    },

    -- Comment
    {
        'numToStr/Comment.nvim',
        opts = {},
        lazy = false,
    },

    -- Copilot
    {
        'github/copilot.vim',
        event = "VeryLazy",
        config = function()
            require('alex-config.keymaps').set_copilot_keys()
        end
    },

    -- Flash
    {
        "folke/flash.nvim",
        event = "VeryLazy",
        -- config = flash_config,
        keys = require("alex-config.keymaps").flash_keys,
        opts = {},
    }
}
