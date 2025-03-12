return {
    "epwalsh/obsidian.nvim",
    version = "*", -- recommended, use latest release instead of latest commit
    dependencies = {
        "nvim-lua/plenary.nvim",
        -- see below for full list of optional dependencies 👇
    },
    lazy = true,
    cmd = {
        "ObsidianOpen",
        "ObsidianNew",
        "ObsidianQuickSwitch",
        "ObsidianFollowLink",
        "ObsidianBacklinks",
        "ObsidianToday",
        "ObsidianYesterday",
        "ObsidianTomorrow",
        "ObsidianTemplate",
        "ObsidianSearch",
        "ObsidianLink",
        "ObsidianLinkNew",
        "ObsidianWorkspace",
        "ObsidianPasteImg",
        "ObsidianRename"
        -- Add any other commands that you use frequently
    },
    opts = {
        notes_subdir = "000 Zettelkasten",

        templates = {
            subdir = "999 Templates",
            date_format = "%Y%m%d",
            time_format = "%H%M",
        },

        daily_notes = {
            -- Optional, if you keep daily notes in a separate directory.
            folder = "dailies",
            -- Optional, if you want to change the date format for the ID of daily notes.
            date_format = "%Y-%m-%d",
            -- Optional, if you want to change the date format of the default alias of daily notes.
            alias_format = "%B %-d, %Y",
            -- Optional, default tags to add to each new daily note created.
            default_tags = { "daily-notes" },
            -- Optional, if you want to automatically insert a template from your template directory like 'daily.md'
            template = nil
        },

        workspaces = {
            {
                name = "personal",
                path = "~/nas-drives/ovault/",
            },
        },

        mappings = {
            -- Overrides the 'gf' mapping to work on markdown/wiki links within your vault.
            ["gf"] = {
                action = function()
                    return require("obsidian").util.gf_passthrough()
                end,
                opts = { noremap = false, expr = true, buffer = true },
            },
            -- Toggle check-boxes.
            ["<leader>oh"] = {
                action = function()
                    return require("obsidian").util.toggle_checkbox()
                end,
                opts = { buffer = true },
            },
        },

        note_id_func = function(title)
            return title or vim.fn.input("Enter note name: ")
        end
    },
}
