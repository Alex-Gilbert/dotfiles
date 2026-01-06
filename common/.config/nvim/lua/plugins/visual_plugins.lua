return {
	-- Colorscheme
	{
		"rebelot/kanagawa.nvim",
		lazy = false, -- make sure we load this during startup if it is your main colorscheme
		priority = 1000, -- make sure to load this before all the other start plugins
		opts = {
			compile = false, -- enable compiling the colorscheme
			undercurl = true, -- enable undercurls
			commentStyle = { italic = true },
			functionStyle = {},
			keywordStyle = { italic = true },
			statementStyle = { bold = true },
			typeStyle = {},
			transparent = true,
			dimInactive = true, -- dim inactive window `:h hl-NormalNC`
			terminalColors = true, -- define vim.g.terminal_color_{0,17}
			colors = { -- add/modify theme and palette colors
				palette = {},
				theme = { wave = {}, lotus = {}, dragon = {}, all = {} },
			},
			theme = "wave", -- Load "wave" theme when 'background' option is not set
			background = { -- map the value of 'background' option to a theme
				dark = "wave", -- try "dragon" !
				light = "lotus",
			},
		},
		config = function()
			vim.cmd([[colorscheme kanagawa]])
			vim.cmd([[
                hi Normal guibg=NONE ctermbg=NONE
                hi NormalNC guibg=NONE ctermbg=NONE
                hi SignColumn guibg=NONE ctermbg=NONE
                hi EndOfBuffer guibg=NONE ctermbg=NONE
            ]])
		end,
	},

	-- {
	-- 	"sainnhe/gruvbox-material",
	-- 	lazy = false,
	-- 	priority = 1000,
	-- 	config = function()
	-- 		vim.g.gruvbox_material_enable_italic = true
	-- 		vim.cmd.colorscheme("gruvbox-material")
	-- 	end,
	-- },

	-- {
	-- 	"aktersnurra/no-clown-fiesta.nvim",
	-- 	priority = 1000,
	-- 	config = function()
	-- 		local opts = {
	-- 			styles = {
	-- 				type = { bold = true },
	-- 				lsp = { underline = false },
	-- 				match_paren = { underline = true },
	-- 			},
	-- 		}
	--
	-- 		local plugin = require("no-clown-fiesta")
	-- 		plugin.setup(opts)
	-- 		return plugin.load()
	-- 	end,
	-- 	lazy = false,
	-- },

	"Zeioth/heirline-components.nvim",
	"SmiteshP/nvim-navic",

	-- Status Line
	{
		"rebelot/heirline.nvim",
		depends = {
			"rebelot/kanagawa.nvim",
			"Zeioth/heirline-components.nvim",
			"SmiteshP/nvim-navic",
			"cbochs/grapple.nvim",
		},
		lazy = false,
		config = function()
			local heirline = require("heirline")
			local my_heir = require("alex-config.heirlines")
			local components = require("heirline-components.all")

			heirline.load_colors(components.hl.get_colors())

			heirline.setup({
				statusline = my_heir.Statusline,
				tabline = my_heir.TabLine,
			})

			vim.o.showtabline = 2
		end,
	},
	-- {
	-- 	"MeanderingProgrammer/render-markdown.nvim",
	-- 	-- dependencies = { "nvim-treesitter/nvim-treesitter", "echasnovski/mini.nvim" }, -- if you use the mini.nvim suite
	-- 	-- dependencies = { 'nvim-treesitter/nvim-treesitter', 'echasnovski/mini.icons' }, -- if you use standalone mini plugins
	-- 	dependencies = { "nvim-treesitter/nvim-treesitter", "nvim-tree/nvim-web-devicons" }, -- if you prefer nvim-web-devicons
	-- 	---@module 'render-markdown'
	-- 	---@type render.md.UserConfig
	-- 	opts = {},
	-- },

	-- Noice - UI overhaul for cmdline, messages, notifications
	{
		"folke/noice.nvim",
		event = "VeryLazy",
		dependencies = {
			"MunifTanjim/nui.nvim",
			"rcarriga/nvim-notify",
		},
		keys = {
			{ "<leader>mh", "<cmd>Noice history<cr>", desc = "[M]essages [H]istory" },
			{ "<leader>ml", "<cmd>Noice last<cr>", desc = "[M]essages [L]ast" },
			{ "<leader>me", "<cmd>Noice errors<cr>", desc = "[M]essages [E]rrors" },
			{ "<leader>md", "<cmd>Noice dismiss<cr>", desc = "[M]essages [D]ismiss all" },
			{ "<leader>mt", "<cmd>Noice telescope<cr>", desc = "[M]essages [T]elescope" },
			{
				"<c-f>",
				function()
					if not require("noice.lsp").scroll(4) then
						return "<c-f>"
					end
				end,
				silent = true,
				expr = true,
				desc = "Scroll forward",
				mode = { "i", "n", "s" },
			},
			{
				"<c-b>",
				function()
					if not require("noice.lsp").scroll(-4) then
						return "<c-b>"
					end
				end,
				silent = true,
				expr = true,
				desc = "Scroll backward",
				mode = { "i", "n", "s" },
			},
		},
		opts = {
			cmdline = {
				enabled = true,
				view = "cmdline_popup",
				format = {
					cmdline = { pattern = "^:", icon = "", lang = "vim" },
					search_down = { kind = "search", pattern = "^/", icon = " ", lang = "regex" },
					search_up = { kind = "search", pattern = "^%?", icon = " ", lang = "regex" },
					filter = { pattern = "^:%s*!", icon = "$", lang = "bash" },
					lua = { pattern = { "^:%s*lua%s+", "^:%s*lua%s*=%s*", "^:%s*=%s*" }, icon = "", lang = "lua" },
					help = { pattern = "^:%s*he?l?p?%s+", icon = "󰋖" },
				},
			},
			messages = {
				enabled = true,
				view = "notify",
				view_error = "notify",
				view_warn = "notify",
				view_history = "messages",
				view_search = "virtualtext",
			},
			popupmenu = {
				enabled = true,
				backend = "nui",
				kind_icons = true,
			},
			notify = {
				enabled = true,
				view = "notify",
			},
			lsp = {
				progress = {
					enabled = true,
					format = "lsp_progress",
					format_done = "lsp_progress_done",
					throttle = 1000 / 30,
					view = "mini",
				},
				override = {
					["vim.lsp.util.convert_input_to_markdown_lines"] = true,
					["vim.lsp.util.stylize_markdown"] = true,
				},
				hover = {
					enabled = true,
					silent = false,
				},
				signature = {
					enabled = true,
					auto_open = {
						enabled = true,
						trigger = true,
						throttle = 50,
					},
				},
				message = {
					enabled = true,
					view = "notify",
				},
			},
			presets = {
				bottom_search = true, -- classic bottom cmdline for search
				command_palette = true, -- center cmdline and popupmenu together
				long_message_to_split = true, -- long messages go to split
				inc_rename = false,
				lsp_doc_border = true, -- border on LSP hover/signature
			},
			routes = {
				-- Skip "written" messages
				{
					filter = {
						event = "msg_show",
						kind = "",
						find = "written",
					},
					opts = { skip = true },
				},
				-- Skip search count messages
				{
					filter = { event = "msg_show", kind = "search_count" },
					opts = { skip = true },
				},
				-- Skip "No information available" from LSP hover
				{
					filter = {
						event = "notify",
						find = "No information available",
					},
					opts = { skip = true },
				},
				-- Skip macro recording messages
				{
					filter = { event = "msg_showmode" },
					opts = { skip = true },
				},
			},
			views = {
				cmdline_popup = {
					position = {
						row = "50%",
						col = "50%",
					},
					size = {
						width = 60,
						height = "auto",
					},
					border = {
						style = "rounded",
						padding = { 0, 1 },
					},
				},
				popupmenu = {
					relative = "editor",
					position = {
						row = 8,
						col = "50%",
					},
					size = {
						width = 60,
						height = 10,
					},
					border = {
						style = "rounded",
						padding = { 0, 1 },
					},
				},
			},
		},
		config = function(_, opts)
			require("noice").setup(opts)
			require("telescope").load_extension("noice")
		end,
	},

	-- nvim-notify - notification backend for noice
	{
		"rcarriga/nvim-notify",
		opts = {
			timeout = 3000,
			max_height = function()
				return math.floor(vim.o.lines * 0.75)
			end,
			max_width = function()
				return math.floor(vim.o.columns * 0.75)
			end,
			render = "wrapped-compact",
			stages = "fade_in_slide_out",
			top_down = true,
		},
	},
}
