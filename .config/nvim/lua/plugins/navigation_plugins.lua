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
		dependencies = {
			{ "echasnovski/mini.icons", opts = {} },
			-- {
			-- 	"skardyy/neo-img",
			-- 	build = ":NeoImg Install",
			-- 	config = function()
			-- 		require("neo-img").setup({
			-- 			supported_extensions = {
			-- 				png = true,
			-- 				jpg = true,
			-- 				jpeg = true,
			-- 				tiff = true,
			-- 				tif = true,
			-- 				svg = false,
			-- 				webp = true,
			-- 				bmp = true,
			-- 				gif = true, -- static only
			-- 				docx = true,
			-- 				xlsx = true,
			-- 				pdf = true,
			-- 				pptx = true,
			-- 				odg = true,
			-- 				odp = true,
			-- 				ods = true,
			-- 				odt = true,
			-- 			},
			--
			-- 			----- Important ones -----
			-- 			size = "80%", -- size of the image in percent
			-- 			center = true, -- rather or not to center the image in the window
			-- 			----- Important ones -----
			--
			-- 			----- Less Important -----
			-- 			auto_open = true, -- Automatically open images when buffer is loaded
			-- 			oil_preview = true, -- changes oil preview of images too
			-- 			backend = "auto", -- auto / kitty / iterm / sixel
			-- 			resizeMode = "Fit", -- Fit / Stretch / Crop
			-- 			offset = "2x3", -- that exmp is 2 cells offset x and 3 y.
			-- 			ttyimg = "local", -- local / global
			-- 			----- Less Important -----
			-- 		})
			-- 	end,
			-- },
		},
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
		branch = "master",
		dependencies = {
			"gbprod/yanky.nvim",
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
