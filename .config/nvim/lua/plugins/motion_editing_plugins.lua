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
		"echasnovski/mini.move",
		version = "*",
		opts = {
			mappings = require("alex-config.keymaps").mini_move_keys,
			options = {
				reindent_linewise = true,
			},
		},
	},

	-- Comment
	{
		"numToStr/Comment.nvim",
		opts = {},
		lazy = false,
	},

	-- Copilot
	-- {
	-- 	"github/copilot.vim",
	-- 	event = "VeryLazy",
	-- 	config = function()
	-- 		require("alex-config.keymaps").set_copilot_keys()
	-- 	end,
	-- },

	-- SuperMaven
	{
		"supermaven-inc/supermaven-nvim",
		event = "VeryLazy",
		config = function()
			require("supermaven-nvim").setup({

				keymaps = {
					accept_suggestion = "<C-l>",
					accept_word = "<C-s>",
					clear_suggestion = "<C-]>",
				},
				ignore_filetypes = {},
				color = {
					suggestion_color = "#ffffff",
					cterm = 244,
				},
				log_level = "info", -- set to "off" to disable logging completely
				disable_inline_completion = false, -- disables inline completion for use with cmp
				disable_keymaps = false, -- disables built in keymaps for more manual control
				condition = function()
					return false
				end, -- condition to check for stopping supermaven, `true` means to stop supermaven when the condition is true.
			})
		end,
	},

	-- Flash
	{
		"folke/flash.nvim",
		event = "VeryLazy",
		-- config = flash_config,
		keys = require("alex-config.keymaps").flash_keys,
		opts = {},
	},

	-- Yanky
	{
		"gbprod/yanky.nvim",
		opts = {},
		config = function(_, opts)
			require("yanky").setup(opts)
			require("alex-config.keymaps").set_yank_keys()
		end,
	},

	-- Zen Mode
	{
		"folke/zen-mode.nvim",
		opts = {
			window = {
				options = {
					relativenumber = true,
				},
			},
		},
	},
}
