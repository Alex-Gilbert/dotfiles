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

	-- Grapple (file tagging/navigation)
	{
		"cbochs/grapple.nvim",
		lazy = false,
		dependencies = {
			{ "nvim-tree/nvim-web-devicons", lazy = true },
		},
		opts = {
			scope = "git",
			icons = true,
			status = true,
		},
		config = function(_, opts)
			require("grapple").setup(opts)
			require("alex-config.keymaps").set_grapple_keys()
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

	-- Aerial (code outline / symbol navigation)
	{
		"stevearc/aerial.nvim",
		dependencies = {
			"nvim-treesitter/nvim-treesitter",
			"nvim-tree/nvim-web-devicons",
			"nvim-telescope/telescope.nvim",
		},
		keys = {
			{ "<leader>cs", "<cmd>Telescope aerial<cr>", desc = "[C]ode [S]ymbols (Aerial)" },
			{ "<leader>cn", "<cmd>AerialNavToggle<cr>", desc = "[C]ode [N]av (Aerial)" },
			{ "]s", "<cmd>AerialNext<cr>", desc = "Next symbol" },
			{ "[s", "<cmd>AerialPrev<cr>", desc = "Prev symbol" },
		},
		opts = {
			backends = { "treesitter", "lsp", "markdown", "asciidoc", "man" },
			layout = {
				default_direction = "float",
				max_width = { 80, 0.5 },
			},
			float = {
				relative = "editor",
				border = "rounded",
				max_height = 0.7,
				min_height = { 10, 0.2 },
			},
			nav = {
				border = "rounded",
				max_height = 0.7,
				min_height = { 10, 0.2 },
				max_width = 0.6,
				min_width = { 0.3, 40 },
				win_opts = {
					cursorline = true,
					winblend = 10,
				},
				autojump = true,
				preview = true,
			},
			filter_kind = false, -- Show all symbol types
			highlight_on_jump = 300,
			close_on_select = true,
			show_guides = true,
		},
		config = function(_, opts)
			require("aerial").setup(opts)

			-- Configure telescope extension
			require("telescope").setup({
				extensions = {
					aerial = {
						show_columns = "both",
						col1_width = 4,
						col2_width = 30,
					},
				},
			})
			require("telescope").load_extension("aerial")
		end,
	},
	{
		"christoomey/vim-tmux-navigator",
		cmd = {
			"TmuxNavigateLeft",
			"TmuxNavigateDown",
			"TmuxNavigateUp",
			"TmuxNavigateRight",
			"TmuxNavigatePrevious",
			"TmuxNavigatorProcessList",
		},
		keys = {
			{ "<c-h>", "<cmd><C-U>TmuxNavigateLeft<cr>" },
			{ "<c-j>", "<cmd><C-U>TmuxNavigateDown<cr>" },
			{ "<c-k>", "<cmd><C-U>TmuxNavigateUp<cr>" },
			{ "<c-l>", "<cmd><C-U>TmuxNavigateRight<cr>" },
			{ "<c-\\>", "<cmd><C-U>TmuxNavigatePrevious<cr>" },
		},
	},
}
