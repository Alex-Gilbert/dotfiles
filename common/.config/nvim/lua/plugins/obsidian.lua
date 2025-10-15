return {
	"epwalsh/obsidian.nvim",
	version = "*", -- recommended, use latest release instead of latest commit
	lazy = true,
	cmd = {
		"ObsidianOpen",
		"ObsidianNew",
		"ObsidianQuickSwitch",
		"ObsidianFollowLink",
		"ObsidianBacklinks",
		"ObsidianSearch",
		"ObsidianLinks",
		"ObsidianTags",
		"ObsidianTemplate",
		"ObsidianToday",
		"ObsidianYesterday",
		"ObsidianTomorrow",
		"ObsidianDailies",
		"ObsidianPasteImg",
		"ObsidianTOC",
		"ObsidianToggleCheckbox",
		"ObsidianRename",
		"ObsidianKill",
	},
	keys = require("alex-config.keymaps").obsidian_keys,
	ft = "markdown",
	dependencies = {
		"nvim-lua/plenary.nvim",
	},
	opts = {
		workspaces = {
			{
				name = "personal",
				path = "~/.obsidian/alex-vault/",
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

		completion = {
			nvim_cmp = true,
			min_chars = 2,
		},

		templates = {
			folder = "999-TEMPLATES",
			date_format = "%Y-%m-%d",
			time_format = "%H:%M",
		},

		---@param url string
		follow_url_func = function(url)
			vim.fn.jobstart({ "xdg-open", url }) -- linux
		end,

		---@param img string
		follow_img_func = function(img)
			vim.fn.jobstart({ "xdg-open", img }) -- linux
		end,

		picker = { name = "telescope.nvim" },

		mappings = {},
	},
	config = function(_, opts)
		require("obsidian").setup(opts)
		require("alex-config.keymaps").set_obsidian_keys()
	end,
}
