return {
	-- Using actively maintained fork with native blink.cmp support
	"obsidian-nvim/obsidian.nvim",
	version = "*",
	lazy = true,
	cmd = {
		"Obsidian",
		"ObsidianSearch",
		"ObsidianNew",
		"ObsidianToday",
		"ObsidianBacklinks",
		"ObsidianLink",
		"ObsidianRename",
		"ObsidianQuickSwitch",
		"ObsidianTemplate",
		"ObsidianFollowLink",
		"ObsidianToggleCheckbox",
	},
	keys = require("alex-config.keymaps").obsidian_keys,
	ft = "markdown",
	dependencies = {
		"nvim-lua/plenary.nvim",
		"nvim-telescope/telescope.nvim",
	},
	opts = {
		workspaces = {
			{
				name = "personal",
				path = "~/alex-vault/",
			},
		},

		notes_subdir = "000-INBOX",
		new_notes_location = "notes_subdir",

		---@param title string|?
		---@return string
		note_id_func = function(title)
			local suffix = ""
			title = title or vim.fn.input("Title: ")
			if title ~= nil then
				suffix = title:gsub(" ", "-"):gsub("[^A-Za-z0-9-]", ""):lower()
			else
				for _ = 1, 4 do
					suffix = suffix .. string.char(math.random(65, 90))
				end
			end
			local timestamp = os.date("%Y%m%d")
			return timestamp .. "-" .. suffix
		end,

		-- blink.cmp is auto-detected, sources auto-injected
		completion = {
			blink = true,
			min_chars = 2,
		},

		templates = {
			folder = "999-TEMPLATES",
			date_format = "%Y-%m-%d",
			time_format = "%H:%M",
		},

		-- Use new command style (e.g., "Obsidian backlinks" instead of "ObsidianBacklinks")
		legacy_commands = false,

		picker = { name = "telescope.nvim" },
	},
	config = function(_, opts)
		require("obsidian").setup(opts)
		require("alex-config.keymaps").set_obsidian_keys()
	end,
}
