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
			require("alex-config.keymaps").set_snacks_keys()
		end,
	},

	-- Trouble
	{
		"folke/trouble.nvim",
		dependencies = { "nvim-tree/nvim-web-devicons" },
		opts = {},
	},

	-- Quicker (better quickfix editing)
	{
		"stevearc/quicker.nvim",
		event = "FileType qf",
		---@module "quicker"
		---@type quicker.SetupOptions
		opts = {},
	},

	-- Aerial (code outline / symbol navigation) - now using snacks for symbols picker
	{
		"stevearc/aerial.nvim",
		dependencies = {
			"nvim-treesitter/nvim-treesitter",
			"nvim-tree/nvim-web-devicons",
		},
		keys = {
			-- <leader>cs now handled by snacks.picker.lsp_symbols in LSP keymaps
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
	},

	-- Tmux navigation
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
