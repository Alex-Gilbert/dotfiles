return {
	-- mini.ai - Enhanced text objects with treesitter integration
	{
		"echasnovski/mini.ai",
		version = "*",
		event = "VeryLazy",
		dependencies = { "nvim-treesitter/nvim-treesitter-textobjects" },
		config = function()
			local ai = require("mini.ai")
			ai.setup({
				n_lines = 500, -- Search range for textobjects
				custom_textobjects = {
					-- Treesitter-powered textobjects
					f = ai.gen_spec.treesitter({ a = "@function.outer", i = "@function.inner" }), -- function
					c = ai.gen_spec.treesitter({ a = "@class.outer", i = "@class.inner" }), -- class
					a = ai.gen_spec.treesitter({ a = "@parameter.outer", i = "@parameter.inner" }), -- argument/parameter
					o = ai.gen_spec.treesitter({ -- code block
						a = { "@block.outer", "@conditional.outer", "@loop.outer" },
						i = { "@block.inner", "@conditional.inner", "@loop.inner" },
					}),

					-- Additional useful textobjects
					u = ai.gen_spec.function_call(), -- function call (default)
					U = ai.gen_spec.function_call({ name_pattern = "[%w_]" }), -- function call without dot

					-- Mini.ai defaults you keep: q (quotes), b (brackets), t (tags), etc.
				},
				-- Disable some defaults that conflict or aren't useful
				mappings = {
					around = "a",
					inside = "i",
					around_next = "an",
					inside_next = "in",
					around_last = "al",
					inside_last = "il",
					goto_left = "g[",
					goto_right = "g]",
				},
			})
		end,
	},

	-- mini.surround - Surround operations (replaces nvim-surround)
	{
		"echasnovski/mini.surround",
		version = "*",
		event = "VeryLazy",
		opts = {
			mappings = {
				add = "gs", -- Add surrounding (gs in normal/visual, e.g., gsiw" )
				delete = "gsd", -- Delete surrounding
				find = "gsf", -- Find surrounding (to the right)
				find_left = "gsF", -- Find surrounding (to the left)
				highlight = "gsh", -- Highlight surrounding
				replace = "gsr", -- Replace surrounding (change)
				update_n_lines = "gsn", -- Update `n_lines`

				suffix_last = "l", -- Suffix to search backwards
				suffix_next = "n", -- Suffix to search forwards
			},
		},
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
				disable_keymaps = false, -- disafalsebles built in keymaps for more manual control
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
		keys = require("alex-config.keymaps").flash_keys,
		opts = {
			-- options used when flash is activated through
			-- `f`, `F`, `t`, `T`, `;` and `,` motions
			modes = {
				char = {
					enabled = false,
				},
			},
		},
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

	-- Zen Mode now provided by snacks.nvim
}
