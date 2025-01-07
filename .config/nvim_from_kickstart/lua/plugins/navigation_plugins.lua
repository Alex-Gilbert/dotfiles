return {
	-- Oil
	{
		"stevearc/oil.nvim",
		config = function()
			require("oil").setup({
				keymaps = require("alex-config.keymaps").oil_keys,
				use_default_keymaps = false,
			})
			require("alex-config.keymaps").set_oil_keys()
		end,
		dependencies = { { "echasnovski/mini.icons", opts = {} } },
	},

	-- Harpoon
	{
		"ThePrimeagen/harpoon",
		branch = "harpoon2",
		lazy = false,
		dependencies = { "nvim-lua/plenary.nvim" },
		opts = {},
		config = function()
			local harpoon = require("harpoon")
			harpoon:setup()
			require("alex-config.keymaps").set_harpoon_keys(harpoon)
		end,
	},

	-- Telescope
	{
		"nvim-telescope/telescope.nvim",
		event = "VimEnter",
		branch = "0.1.x",
		dependencies = {
			"nvim-lua/plenary.nvim",
			{
				"nvim-telescope/telescope-fzf-native.nvim",

				build = "make",

				cond = function()
					return vim.fn.executable("make") == 1
				end,
			},
			{ "nvim-telescope/telescope-ui-select.nvim" },
			{ "nvim-tree/nvim-web-devicons", enabled = vim.g.have_nerd_font },
		},
		config = function()
			require("telescope").setup({
				extensions = {
					["ui-select"] = {
						require("telescope.themes").get_dropdown(),
					},
				},
			})

			pcall(require("telescope").load_extension, "fzf")
			pcall(require("telescope").load_extension, "ui-select")

			require("alex-config.keymaps").set_telescope_keys()
		end,
	},

	-- Trouble
	{
		"folke/trouble.nvim",
		dependencies = { "nvim-tree/nvim-web-devicons" },
		opts = {},
	},
}
