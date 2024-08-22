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
        workspaces = {
            {
                name = "personal",
                path = "~/ObisidianVault/",
            },
        },
        notes_subdir = "000 Zettelkasten",
        templates = {
            subdir = "999 Templates",
            date_format = "%Y%m%d",
            time_format = "%H%M",
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
